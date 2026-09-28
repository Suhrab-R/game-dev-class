package arena

import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Types shared by the whole game. `Name :: struct {...}` declares a type;
// `enum u8` means the enum's values are stored in one byte.
// ---------------------------------------------------------------------------

// Which role this copy of the game is playing.
Mode :: enum u8 {
	Solo,   // one player, no network
	Host,   // player 1: runs the real simulation and sends the result to player 2
	Client, // player 2: sends its inputs to the host and draws whatever the host sends back
}

State :: enum u8 {
	Title,              // main menu
	Join_Menu,          // typing the host's IP address
	Waiting_For_Player, // host: waiting for player 2 to join
	Connecting,         // client: waiting for the host's first reply
	Playing,
	Round_Over,
}

// How the last round ended.
Outcome :: enum u8 {
	None,
	Survived,     // solo: lasted the whole round
	Died,         // solo: ran out of HP
	Player1_Wins, // versus: player 2 died first
	Player2_Wins, // versus: player 1 died first
	Draw,         // versus: both died on the same frame
}

Player :: struct {
	pos:           rl.Vector2,
	hp:            int,
	alive:         bool,
	invuln_timer:  f32, // seconds of invulnerability left after being hit
	fire_cooldown: f32, // seconds until the next shot is allowed
	time_survived: f32, // seconds this player has been alive this round
	kills:         int,
}

Bullet :: struct {
	pos:   rl.Vector2,
	vel:   rl.Vector2, // pixels per second
	owner: int,        // index of the player who fired it (they get the kill)
}

Enemy :: struct {
	pos: rl.Vector2,
}

// Everything one player's controls said this frame.
// The client sends this to the host every frame; the host feeds it into the simulation.
Player_Input :: struct {
	move:     rl.Vector2, // WASD/arrow direction, each axis is -1, 0 or 1
	aim:      rl.Vector2, // mouse position in screen pixels
	shooting: bool,       // left mouse button held
	restart:  bool,       // R or Enter held (only used on the round-over screen)
}

// All the game's state lives in this one struct, which is passed around as a
// pointer (`g: ^Game`, where `^T` means "pointer to T").
Game :: struct {
	mode:         Mode,
	state:        State,
	outcome:      Outcome,
	quit:         bool, // set by the title screen to close the window

	players:      [MAX_PLAYERS]Player, // fixed-size array
	player_count: int, // 1 in solo, 2 in versus
	local_player: int, // which player this window controls: 0 = host/solo, 1 = client
	bullets:      [dynamic]Bullet, // growable array (like std::vector / ArrayList)
	enemies:      [dynamic]Enemy,
	time:         f32, // seconds since the round started
	spawn_timer:  f32, // seconds until the next enemy spawns

	net:          Network,
	ip_text:      [32]u8, // join menu: the characters of the IP address typed so far
	ip_len:       int,
	message:      cstring, // shown on the menus: errors, "host disconnected", ...
}
