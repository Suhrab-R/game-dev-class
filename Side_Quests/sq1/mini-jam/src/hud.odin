package arena

import "core:fmt"
import rl "vendor:raylib"

// The strip of text above the arena during play.
draw_hud :: proc(g: ^Game) {
	if g.player_count == 1 {
		draw_solo_hud(g)
	} else {
		draw_versus_hud(g)
	}
	// TESTING ONLY (remove with the toggle): a reminder that enemies are switched off.
	if g.enemies_disabled {
		draw_centered_text("ENEMIES OFF (N)", 58, 18, rl.ORANGE)
	}
}

// Solo: HP on the left, time left in the middle, kills on the right.
draw_solo_hud :: proc(g: ^Game) {
	p := g.players[0]
	rl.DrawText(fmt.ctprintf("HP: %d / %d", p.hp, PLAYER_MAX_HP), 40, 25, 30, rl.RAYWHITE)
	draw_centered_text(fmt.ctprintf("%.0f", max(0, SOLO_ROUND_LENGTH - g.time)), 25, 30, rl.RAYWHITE)
	kills_text := fmt.ctprintf("Kills: %d", p.kills)
	rl.DrawText(kills_text, SCREEN_W - 40 - rl.MeasureText(kills_text, 30), 25, 30, rl.RAYWHITE)
}

// Versus: player 1 on the left, time survived so far in the middle, player 2 on the right.
// Under each player's stats, their remaining sabotage shots (if any).
draw_versus_hud :: proc(g: ^Game) {
	HUD_SIZE :: 28 // a constant can also be declared inside a proc
	for i in 0 ..< 2 {
		p := g.players[i]
		stats := fmt.ctprintf("P%d  HP %d  Kills %d", i + 1, p.hp, p.kills)
		// Player 1's text starts at the left edge; player 2's ends at the right edge.
		x := i == 0 ? i32(40) : SCREEN_W - 40 - rl.MeasureText(stats, HUD_SIZE)
		rl.DrawText(stats, x, 20, HUD_SIZE, player_color(i))

		if p.sabotage_shots > 0 {
			rl.DrawText(fmt.ctprintf("Sabotage shots: %d", p.sabotage_shots), x, 52, 18, SABOTAGE_COLOR)
		}
	}

	draw_centered_text(fmt.ctprintf("%.1f s", g.time), 25, 30, rl.RAYWHITE)
}
