package arena

import "core:math/rand"
import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Power-ups: they appear in the arena during versus rounds, and whoever
// touches one first gets its effect.
// ---------------------------------------------------------------------------

// Spawns a power-up every POWER_UP_INTERVAL seconds, as long as there's room on
// the field. The timer only runs while there's room, so the next power-up comes
// POWER_UP_INTERVAL seconds after the last one was picked up.
update_power_up_spawning :: proc(g: ^Game, dt: f32) {
	if g.player_count < 2 do return // sabotage is pointless in solo
	if len(g.power_ups) >= MAX_POWER_UPS do return

	g.power_up_timer -= dt
	if g.power_up_timer > 0 do return

	append(&g.power_ups, Power_Up{pos = random_power_up_point(), kind = .Sabotage})
	g.power_up_timer = POWER_UP_INTERVAL
}

// A living player touching a power-up picks it up.
handle_power_up_pickups :: proc(g: ^Game) {
	for pi := len(g.power_ups) - 1; pi >= 0; pi -= 1 { // backwards: see update_bullets
		for i in 0 ..< g.player_count {
			p := &g.players[i]
			if p.alive && rl.CheckCollisionCircles(g.power_ups[pi].pos, POWER_UP_RADIUS, p.pos, PLAYER_RADIUS) {
				apply_power_up(p, g.power_ups[pi].kind)
				unordered_remove(&g.power_ups, pi)
				break // this power-up is gone
			}
		}
	}
}

// Gives the effect of a power-up to the player who picked it up.
apply_power_up :: proc(p: ^Player, kind: Power_Up_Kind) {
	switch kind {
	case .Sabotage:
		p.sabotage_shots = SABOTAGE_SHOTS // refill, not stack
	}
}

// A random point inside the arena, at least POWER_UP_MARGIN away from the walls.
random_power_up_point :: proc() -> rl.Vector2 {
	return {
		rand.float32_range(ARENA.x + POWER_UP_MARGIN, ARENA.x + ARENA.width - POWER_UP_MARGIN),
		rand.float32_range(ARENA.y + POWER_UP_MARGIN, ARENA.y + ARENA.height - POWER_UP_MARGIN),
	}
}
