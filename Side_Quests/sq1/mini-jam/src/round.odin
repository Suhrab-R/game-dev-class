package arena

import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// One round of play: setting it up, advancing it by one frame, and deciding
// when it is over. Only the host (or solo player) runs this code; the client
// just draws the snapshots the host sends.
// ---------------------------------------------------------------------------

// Starts a fresh round: full HP, no enemies or bullets, timers back to zero.
reset_round :: proc(g: ^Game) {
	clear(&g.bullets)
	clear(&g.enemies)
	g.time = 0
	g.spawn_timer = SPAWN_START_INTERVAL
	g.outcome = .None // `.None` is an enum value; Odin infers the enum type (Outcome) from g.outcome

	center := rl.Vector2{ARENA.x + ARENA.width / 2, ARENA.y + ARENA.height / 2}
	for i in 0 ..< g.player_count { // loops i = 0, 1, ..., player_count - 1
		pos := center
		if g.player_count == 2 {
			// Versus: start the players apart so they don't overlap.
			pos.x += i == 0 ? -VERSUS_START_OFFSET : VERSUS_START_OFFSET
		}
		g.players[i] = Player {
			pos   = pos,
			hp    = PLAYER_MAX_HP,
			alive = true,
		}
	}
}

// Runs the game for one frame given each player's input.
// Each step is its own proc so this reads as the order things happen in.
update_round :: proc(g: ^Game, inputs: [MAX_PLAYERS]Player_Input, dt: f32) {
	g.time += dt

	for i in 0 ..< g.player_count {
		update_player(g, i, inputs[i], dt)
	}
	update_bullets(g, dt)
	update_spawning(g, dt)
	update_enemies(g, dt)
	handle_bullet_enemy_hits(g)
	handle_enemy_player_hits(g)

	check_round_over(g)
}

// Ends the round when its win/lose condition is met.
//   Solo:   die -> lose; survive SOLO_ROUND_LENGTH seconds -> win.
//   Versus: no time limit. Difficulty keeps ramping up, so eventually someone
//           dies, and the last player standing wins.
check_round_over :: proc(g: ^Game) {
	if g.player_count == 1 {
		if !g.players[0].alive {
			end_round(g, .Died)
		} else if g.time >= SOLO_ROUND_LENGTH {
			end_round(g, .Survived)
		}
		return
	}

	p1_alive := g.players[0].alive
	p2_alive := g.players[1].alive
	if !p1_alive && !p2_alive {
		end_round(g, .Draw)
	} else if !p1_alive {
		end_round(g, .Player2_Wins)
	} else if !p2_alive {
		end_round(g, .Player1_Wins)
	}
}

end_round :: proc(g: ^Game, outcome: Outcome) {
	g.outcome = outcome
	g.state = .Round_Over
}
