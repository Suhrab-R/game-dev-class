package arena

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

HUD_SIZE     :: 28 // font size of the main stats line
EFFECTS_SIZE :: 18 // font size of the power-up line under it

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

// Solo: HP and power-ups on the left, time left in the middle, kills on the right.
draw_solo_hud :: proc(g: ^Game) {
	p := g.players[0]
	rl.DrawText(fmt.ctprintf("HP: %d", p.hp), 40, 20, HUD_SIZE, rl.RAYWHITE)
	rl.DrawText(effects_text(p), 40, 52, EFFECTS_SIZE, rl.LIGHTGRAY)

	draw_centered_text(fmt.ctprintf("%.0f", max(0, SOLO_ROUND_LENGTH - g.time)), 25, 30, rl.RAYWHITE)

	kills_text := fmt.ctprintf("Kills: %d", p.kills)
	rl.DrawText(kills_text, SCREEN_W - 40 - rl.MeasureText(kills_text, HUD_SIZE), 20, HUD_SIZE, rl.RAYWHITE)
}

// Versus: player 1 on the left, time survived so far in the middle, player 2 on the right.
// Under each player's stats, their active power-ups.
draw_versus_hud :: proc(g: ^Game) {
	for i in 0 ..< 2 {
		p := g.players[i]
		stats := fmt.ctprintf("P%d  HP %d  Kills %d", i + 1, p.hp, p.kills)
		effects := effects_text(p)

		// Player 1's text starts at the left edge; player 2's ends at the right edge.
		stats_x, effects_x := i32(40), i32(40)
		if i == 1 {
			stats_x = SCREEN_W - 40 - rl.MeasureText(stats, HUD_SIZE)
			effects_x = SCREEN_W - 40 - rl.MeasureText(effects, EFFECTS_SIZE)
		}
		rl.DrawText(stats, stats_x, 20, HUD_SIZE, player_color(i))
		rl.DrawText(effects, effects_x, 52, EFFECTS_SIZE, rl.LIGHTGRAY)
	}

	draw_centered_text(fmt.ctprintf("%.1f s", g.time), 25, 30, rl.RAYWHITE)
}

// A one-line summary of a player's active power-ups, e.g. "Laser 7s   Shield 2".
// Empty when they have none.
effects_text :: proc(p: Player) -> cstring {
	weapon := ""
	switch p.weapon {
	case .Normal:
	case .Sabotage:   weapon = fmt.tprintf("Sabotage x%d   ", p.sabotage_shots)
	case .Rapid_Fire: weapon = fmt.tprintf("Rapid fire %ds   ", seconds_left(p.weapon_timer))
	case .Laser:      weapon = fmt.tprintf("Laser %ds   ", seconds_left(p.weapon_timer))
	case .Ricochet:   weapon = fmt.tprintf("Bounce %ds   ", seconds_left(p.weapon_timer))
	case .Shotgun:    weapon = fmt.tprintf("Wide shot %ds   ", seconds_left(p.weapon_timer))
	}
	shield := p.shield_hits > 0 ? fmt.tprintf("Shield %d   ", p.shield_hits) : ""
	invincible := p.invincible_timer > 0 ? fmt.tprintf("Invincible %ds", seconds_left(p.invincible_timer)) : ""
	return fmt.ctprintf("%s%s%s", weapon, shield, invincible)
}

// Whole seconds left on a timer, rounded up (so 0.2 s shows as 1, not 0).
seconds_left :: proc(timer: f32) -> int {
	return int(math.ceil(timer))
}
