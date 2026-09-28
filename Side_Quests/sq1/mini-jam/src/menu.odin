package arena

import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Menus: the title screen, the join screen (typing an IP), and the procs
// that start or leave a game.
// ---------------------------------------------------------------------------

// Title: 1 = solo, 2 = host, 3 = join, ESC = quit.
update_title :: proc(g: ^Game) {
	if rl.IsKeyPressed(.ONE) || rl.IsKeyPressed(.KP_1) {
		start_solo(g)
	} else if rl.IsKeyPressed(.TWO) || rl.IsKeyPressed(.KP_2) {
		start_host(g)
	} else if rl.IsKeyPressed(.THREE) || rl.IsKeyPressed(.KP_3) {
		g.state = .Join_Menu
		g.message = nil
	} else if rl.IsKeyPressed(.ESCAPE) {
		g.quit = true
	}
}

// Join screen: type the host's IP address, ENTER to connect, ESC to go back.
update_join_menu :: proc(g: ^Game) {
	// GetCharPressed returns the characters typed this frame one at a time, then 0.
	// `rune` is Odin's type for a single Unicode character.
	for ch := rl.GetCharPressed(); ch != 0; ch = rl.GetCharPressed() {
		is_ip_char := (ch >= '0' && ch <= '9') || ch == '.'
		if is_ip_char && g.ip_len < len(g.ip_text) {
			g.ip_text[g.ip_len] = u8(ch)
			g.ip_len += 1
		}
	}
	// IsKeyPressedRepeat makes holding backspace keep deleting.
	if (rl.IsKeyPressed(.BACKSPACE) || rl.IsKeyPressedRepeat(.BACKSPACE)) && g.ip_len > 0 {
		g.ip_len -= 1
	}

	if rl.IsKeyPressed(.ENTER) {
		start_client(g)
	} else if rl.IsKeyPressed(.ESCAPE) {
		g.state = .Title
		g.message = nil
	}
}

// The IP typed so far, as a string. `arr[:n]` is a slice of the first n elements.
typed_ip :: proc(g: ^Game) -> string {
	return string(g.ip_text[:g.ip_len])
}

start_solo :: proc(g: ^Game) {
	g.mode = .Solo
	g.player_count = 1
	g.local_player = 0
	g.message = nil
	reset_round(g)
	g.state = .Playing
}

// Host: open the network port and wait for player 2 (the round starts when they join).
start_host :: proc(g: ^Game) {
	if !open_host_socket(&g.net) {
		g.message = "Could not open the network port. Is another copy of the game already hosting?"
		return
	}
	g.mode = .Host
	g.player_count = 2
	g.local_player = 0
	g.message = nil
	g.state = .Waiting_For_Player
}

// Client: start sending to the typed IP; the host's first reply moves us into the game.
start_client :: proc(g: ^Game) {
	if error := open_client_socket(&g.net, typed_ip(g), rl.GetTime()); error != nil {
		g.message = error
		return
	}
	g.mode = .Client
	g.player_count = 2
	g.local_player = 1
	g.message = nil
	g.state = .Connecting
}

// Closes any network connection and goes back to the title, optionally showing a message.
leave_to_title :: proc(g: ^Game, message: cstring) {
	close_network(&g.net)
	clear(&g.bullets)
	clear(&g.enemies)
	g.state = .Title
	g.message = message
}
