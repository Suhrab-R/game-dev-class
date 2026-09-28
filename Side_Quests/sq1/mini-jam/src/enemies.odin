package arena

import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

// Spawns an enemy on the arena edge whenever the spawn timer runs out.
// The interval shrinks the longer the round lasts: it starts at SPAWN_START_INTERVAL,
// loses SPAWN_RAMP seconds per second of play, and never goes below SPAWN_MIN_INTERVAL.
update_spawning :: proc(g: ^Game, dt: f32) {
	g.spawn_timer -= dt
	if g.spawn_timer > 0 do return

	if len(g.enemies) < MAX_ENEMIES {
		append(&g.enemies, Enemy{pos = random_edge_point()})
	}
	g.spawn_timer = max(SPAWN_MIN_INTERVAL, SPAWN_START_INTERVAL - g.time * SPAWN_RAMP)
}

// Moves every enemy straight toward the nearest living player.
// Enemies speed up the longer the round lasts, up to ENEMY_MAX_SPEED.
update_enemies :: proc(g: ^Game, dt: f32) {
	speed := min(ENEMY_BASE_SPEED + g.time * ENEMY_SPEED_GROWTH, ENEMY_MAX_SPEED)
	for &e in g.enemies { // `&e` loops by reference, so changing e changes the enemy in the array
		target, found := nearest_alive_player(g, e.pos) // procs can return several values
		if !found do continue
		e.pos += linalg.normalize0(target - e.pos) * speed * dt
	}
}

// Enemy vs player: the enemy is consumed and the player takes a hit (which an
// invincible, blinking or shielded player shrugs off, see hit_player).
handle_enemy_player_hits :: proc(g: ^Game) {
	for ei := len(g.enemies) - 1; ei >= 0; ei -= 1 { // backwards: see update_bullets
		for i in 0 ..< g.player_count {
			p := &g.players[i]
			if p.alive && rl.CheckCollisionCircles(g.enemies[ei].pos, ENEMY_RADIUS, p.pos, PLAYER_RADIUS) {
				unordered_remove(&g.enemies, ei)
				hit_player(p, 1)
				break // this enemy is gone
			}
		}
	}
}

// Returns the position of the living player closest to `from`.
// `found` is false when every player is dead.
nearest_alive_player :: proc(g: ^Game, from: rl.Vector2) -> (pos: rl.Vector2, found: bool) {
	best := max(f32) // the largest possible f32, so the first living player always wins
	for i in 0 ..< g.player_count {
		p := g.players[i]
		if !p.alive do continue
		// Squared distance is enough to compare which is closer, and skips a square root.
		d := linalg.length2(p.pos - from)
		if d < best {
			best, pos, found = d, p.pos, true
		}
	}
	return // named results (pos, found) are returned as they are
}

// Picks a random point on one of the four arena edges.
random_edge_point :: proc() -> rl.Vector2 {
	t := rand.float32() // 0..1, how far along the chosen edge
	switch rand.int_max(4) {
	case 0: return {ARENA.x + t * ARENA.width, ARENA.y}                // top
	case 1: return {ARENA.x + t * ARENA.width, ARENA.y + ARENA.height} // bottom
	case 2: return {ARENA.x, ARENA.y + t * ARENA.height}               // left
	case:   return {ARENA.x + ARENA.width, ARENA.y + t * ARENA.height} // right
	}
}
