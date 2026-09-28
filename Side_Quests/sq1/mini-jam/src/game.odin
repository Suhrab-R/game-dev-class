package arena

import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// The per-frame update. The menus are handled in menu.odin; once a game has
// started, what happens each frame depends on whether this window is the
// solo player, the host, or the client.
// ---------------------------------------------------------------------------

update :: proc(g: ^Game, dt: f32) {
	switch g.state {
	case .Title:
		update_title(g)
	case .Join_Menu:
		update_join_menu(g)
	case .Waiting_For_Player, .Connecting, .Playing, .Round_Over:
		if rl.IsKeyPressed(.ESCAPE) {
			leave_to_title(g, nil)
			return
		}
		switch g.mode {
		case .Solo:   update_solo(g, dt)
		case .Host:   update_host(g, dt)
		case .Client: update_client(g)
		}
	}
}

// Solo: the original single-player ARENA.
update_solo :: proc(g: ^Game, dt: f32) {
	inputs: [MAX_PLAYERS]Player_Input
	inputs[0] = read_local_input()
	advance_game(g, inputs, dt)
}

// Host: receive player 2's input, simulate both players, send the result back.
update_host :: proc(g: ^Game, dt: f32) {
	now := rl.GetTime()
	if receive_inputs(&g.net, now) {
		// Player 2 has just connected: start the first round.
		reset_round(g)
		g.state = .Playing
	}
	if g.state == .Waiting_For_Player do return

	if now - g.net.last_heard > NET_TIMEOUT {
		leave_to_title(g, "Player 2 disconnected")
		return
	}

	inputs: [MAX_PLAYERS]Player_Input
	inputs[0] = read_local_input()
	inputs[1] = g.net.remote_input
	advance_game(g, inputs, dt)
	send_snapshot(g)
}

// Client: send our input to the host and draw whatever state the host sends back.
// The client never simulates anything itself.
update_client :: proc(g: ^Game) {
	now := rl.GetTime()
	send_input(&g.net, read_local_input())
	receive_snapshots(g, now) // this also switches us from Connecting to Playing

	timeout := g.state == .Connecting ? CONNECT_TIMEOUT : NET_TIMEOUT
	if now - g.net.last_heard > timeout {
		if g.state == .Connecting {
			leave_to_title(g, "No answer from the host. Check the IP, the Wi-Fi, and the host's firewall.")
			g.state = .Join_Menu // back to the IP box so it can be fixed and retried
		} else {
			leave_to_title(g, "The host disconnected")
		}
	}
}

// Runs one frame of the game for the host or solo player: play the round, or
// wait on the round-over screen until any player asks to play again.
advance_game :: proc(g: ^Game, inputs: [MAX_PLAYERS]Player_Input, dt: f32) {
	if g.state == .Playing {
		update_round(g, inputs, dt)
	} else if g.state == .Round_Over {
		for i in 0 ..< g.player_count {
			if inputs[i].restart {
				reset_round(g)
				g.state = .Playing
				break
			}
		}
	}
}
