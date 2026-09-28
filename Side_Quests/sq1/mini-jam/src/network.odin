package arena

import "core:mem"
import "core:net"
import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// LAN multiplayer over UDP.
//
// The host is the only one that simulates the game:
//   client --(Input_Packet, every frame)--> host    "these are my keys and mouse"
//   host --(Snapshot_Packet, every frame)--> client "this is what the game looks like now"
//
// UDP sends separate packets with no delivery guarantee. That is fine here:
// both sides send every frame, so a lost packet is replaced 1/60 s later by a
// newer one, and we only ever care about the newest.
//
// Packets are sent as the raw bytes of the structs below. That works because
// both computers run this same program, so the structs have the same layout
// in memory on both ends.
// ---------------------------------------------------------------------------

NET_PORT              :: 7777       // UDP port the host listens on
NET_TIMEOUT           :: 3.0        // seconds of silence before we decide the other player left
CONNECT_TIMEOUT       :: 5.0        // seconds the client waits for the host's first reply
PACKET_MAGIC          :: 0x41524E41 // "ARNA": lets us ignore stray packets from other programs
MAX_PACKETS_PER_FRAME :: 64         // safety limit on how many packets we read in one frame
MAX_HOST_IPS          :: 4          // how many of this computer's addresses the host screen lists

Network :: struct {
	socket:        net.UDP_Socket,
	is_open:       bool,
	peer:          net.Endpoint, // the other computer (IP + port): the host for a client, the client for a host
	has_peer:      bool,
	last_heard:    f64,          // time (rl.GetTime) of the last valid packet from the peer
	remote_input:  Player_Input, // host only: player 2's newest input
	host_ips:      [MAX_HOST_IPS]net.IP4_Address, // host only: this computer's LAN addresses, shown on screen
	host_ip_count: int,
}

Packet_Kind :: enum u8 {
	Input,
	Snapshot,
}

Packet_Header :: struct {
	magic: u32,
	kind:  Packet_Kind,
}

// Client -> host.
Input_Packet :: struct {
	header: Packet_Header,
	input:  Player_Input,
}

// Host -> client: everything the client needs to draw the current frame.
// Enemies and bullets are fixed-size arrays with a count, because a packet
// can't contain a pointer to a growable array.
Snapshot_Packet :: struct {
	header:           Packet_Header,
	state:            State,
	outcome:          Outcome,
	enemies_disabled: bool, // TESTING toggle, so the client's HUD shows the host's setting
	time:             f32,
	players:          [MAX_PLAYERS]Player,
	enemy_count:      int,
	bullet_count:     int,
	power_up_count:   int,
	enemies:          [MAX_ENEMIES]rl.Vector2,
	bullets:          [MAX_BULLETS]Bullet, // whole bullets, so the client knows which are sabotage ones
	power_ups:        [MAX_POWER_UPS]Power_Up,
}

// ---------------------------------------------------------------------------
// Opening and closing
// ---------------------------------------------------------------------------

// Host: starts listening for player 2 on NET_PORT, on every network interface.
// Returns false if the port can't be opened (for example, another copy of the
// game on this computer is already hosting).
open_host_socket :: proc(n: ^Network) -> bool {
	socket, err := net.make_bound_udp_socket(net.IP4_Any, NET_PORT)
	if err != nil do return false
	// Non-blocking: reading when nothing has arrived returns straight away with
	// .Would_Block instead of freezing the game until a packet comes in.
	net.set_blocking(socket, false)

	n^ = Network { // `n^` is the struct the pointer points to (like *n in C)
		socket  = socket,
		is_open = true,
	}
	find_host_ips(n)
	return true
}

// Client: prepares to talk to the host at `host_ip`.
// Returns an error message to show on screen, or nil on success.
open_client_socket :: proc(n: ^Network, host_ip: string, now: f64) -> (error: cstring) {
	address, ok := net.parse_ip4_address(host_ip)
	if !ok do return "That is not a valid IP address (it should look like 192.168.1.23)"

	socket, err := net.make_unbound_udp_socket(.IP4)
	if err != nil do return "Could not create a network socket"
	net.set_blocking(socket, false)

	n^ = Network {
		socket     = socket,
		is_open    = true,
		peer       = {address = address, port = NET_PORT},
		has_peer   = true,
		last_heard = now, // start the connect timeout from now
	}
	return nil
}

close_network :: proc(n: ^Network) {
	if n.is_open do net.close(n.socket)
	n^ = {} // reset every field to zero
}

// Host: fills n.host_ips with this computer's IPv4 addresses so they can be shown on
// screen for player 2 to type in.
// Only adapters with a gateway (a router) are listed: that is the real Wi-Fi or
// Ethernet connection. Virtual adapters (VirtualBox, WSL, VPNs...) usually have
// none and would only confuse. If nothing qualifies, every address is listed.
find_host_ips :: proc(n: ^Network) {
	interfaces, err := net.enumerate_interfaces()
	if err != .None do return
	defer net.destroy_interfaces(interfaces) // `defer` runs this when the proc returns

	add_host_ips(n, interfaces, require_gateway = true)
	if n.host_ip_count == 0 {
		add_host_ips(n, interfaces, require_gateway = false)
	}
}

// Adds each usable IPv4 address from `interfaces` to n.host_ips, skipping
// loopback (127.x) and self-assigned (169.254.x) addresses.
add_host_ips :: proc(n: ^Network, interfaces: []net.Network_Interface, require_gateway: bool) {
	for iface in interfaces {
		if require_gateway && len(iface.gateways) == 0 do continue
		for lease in iface.unicast {
			// `x.(T)` asks "is this union value a T?"; ok is false if it isn't (e.g. IPv6).
			ip4, is_ip4 := lease.address.(net.IP4_Address)
			if !is_ip4 || ip4[0] == 127 || (ip4[0] == 169 && ip4[1] == 254) do continue
			if n.host_ip_count < MAX_HOST_IPS {
				n.host_ips[n.host_ip_count] = ip4
				n.host_ip_count += 1
			}
		}
	}
}

// ---------------------------------------------------------------------------
// Client side
// ---------------------------------------------------------------------------

// Client: sends this frame's input to the host. Also serves as the "join" message:
// the host learns where we are from the first one it receives.
send_input :: proc(n: ^Network, input: Player_Input) {
	packet := Input_Packet {
		header = {magic = PACKET_MAGIC, kind = .Input},
		input  = input,
	}
	// mem.ptr_to_bytes views the struct's memory as a byte slice, without copying.
	// Send errors are ignored on purpose: UDP is best-effort and we send again next frame.
	net.send_udp(n.socket, mem.ptr_to_bytes(&packet), n.peer)
}

// Client: reads every snapshot that arrived since last frame and applies the newest one.
// Returns true if at least one arrived.
receive_snapshots :: proc(g: ^Game, now: f64) -> (got_one: bool) {
	for _ in 0 ..< MAX_PACKETS_PER_FRAME {
		packet: Snapshot_Packet
		size, from, err := net.recv_udp(g.net.socket, mem.ptr_to_bytes(&packet))
		if err == .Would_Block do break // nothing left to read this frame
		if err != .None do continue     // a bad packet or a reported network hiccup: skip it
		if !same_endpoint(from, g.net.peer) do continue
		if size != size_of(Snapshot_Packet) || packet.header.magic != PACKET_MAGIC || packet.header.kind != .Snapshot do continue

		// Packets arrive in order on a LAN almost always, so the last one read is the newest.
		apply_snapshot(g, &packet)
		g.net.last_heard = now
		got_one = true
	}
	return
}

// Client: copies the host's snapshot into our own Game so the normal draw code can draw it.
apply_snapshot :: proc(g: ^Game, s: ^Snapshot_Packet) {
	g.state = s.state
	g.outcome = s.outcome
	g.enemies_disabled = s.enemies_disabled
	g.time = s.time
	g.players = s.players

	clear(&g.enemies)
	for i in 0 ..< s.enemy_count do append(&g.enemies, Enemy{pos = s.enemies[i]})
	clear(&g.bullets)
	for i in 0 ..< s.bullet_count do append(&g.bullets, s.bullets[i])
	clear(&g.power_ups)
	for i in 0 ..< s.power_up_count do append(&g.power_ups, s.power_ups[i])
}

// ---------------------------------------------------------------------------
// Host side
// ---------------------------------------------------------------------------

// Host: reads every input packet that arrived since last frame and keeps the newest.
// The first valid packet tells us where player 2 is; after that, packets from
// anyone else are ignored (only two players are supported).
// Returns true on the frame player 2 joins.
receive_inputs :: proc(n: ^Network, now: f64) -> (just_joined: bool) {
	for _ in 0 ..< MAX_PACKETS_PER_FRAME {
		packet: Input_Packet
		size, from, err := net.recv_udp(n.socket, mem.ptr_to_bytes(&packet))
		if err == .Would_Block do break
		// Windows reports "the other side's port was closed" (from an earlier send) as a
		// receive error on UDP sockets. It isn't fatal, so skip it and keep reading.
		if err != .None do continue
		if size != size_of(Input_Packet) || packet.header.magic != PACKET_MAGIC || packet.header.kind != .Input do continue

		if !n.has_peer {
			n.peer = from
			n.has_peer = true
			just_joined = true
		} else if !same_endpoint(from, n.peer) {
			continue
		}
		n.remote_input = packet.input
		n.last_heard = now
	}
	return
}

// Host: sends the current game state to player 2.
send_snapshot :: proc(g: ^Game) {
	if !g.net.has_peer do return

	s: Snapshot_Packet
	s.header = {magic = PACKET_MAGIC, kind = .Snapshot}
	s.state = g.state
	s.outcome = g.outcome
	s.enemies_disabled = g.enemies_disabled
	s.time = g.time
	s.players = g.players

	// The spawn and shoot code already caps these, but min() makes sure we can never
	// write past the end of the fixed-size arrays.
	s.enemy_count = min(len(g.enemies), MAX_ENEMIES)
	for i in 0 ..< s.enemy_count do s.enemies[i] = g.enemies[i].pos
	s.bullet_count = min(len(g.bullets), MAX_BULLETS)
	for i in 0 ..< s.bullet_count do s.bullets[i] = g.bullets[i]
	s.power_up_count = min(len(g.power_ups), MAX_POWER_UPS)
	for i in 0 ..< s.power_up_count do s.power_ups[i] = g.power_ups[i]

	net.send_udp(g.net.socket, mem.ptr_to_bytes(&s), g.net.peer)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

same_endpoint :: proc(a, b: net.Endpoint) -> bool {
	return a.port == b.port && a.address == b.address
}
