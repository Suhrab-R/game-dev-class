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
draw_versus_hud :: proc(g: ^Game) {
	p1 := g.players[0]
	p2 := g.players[1]

	left := fmt.ctprintf("P1  HP %d  Kills %d", p1.hp, p1.kills)
	rl.DrawText(left, 40, 25, 28, player_color(0))

	draw_centered_text(fmt.ctprintf("%.1f s", g.time), 25, 30, rl.RAYWHITE)

	right := fmt.ctprintf("P2  HP %d  Kills %d", p2.hp, p2.kills)
	rl.DrawText(right, SCREEN_W - 40 - rl.MeasureText(right, 28), 25, 28, player_color(1))
}
