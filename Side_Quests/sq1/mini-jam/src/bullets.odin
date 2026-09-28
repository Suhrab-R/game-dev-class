package arena

import rl "vendor:raylib"

// Moves every bullet and removes the ones that have left the arena.
update_bullets :: proc(g: ^Game, dt: f32) {
	// Loop backwards: unordered_remove moves the last element into the removed
	// slot, so going forwards would skip the element that was moved.
	for i := len(g.bullets) - 1; i >= 0; i -= 1 {
		b := &g.bullets[i]
		b.pos += b.vel * dt
		if !rl.CheckCollisionPointRec(b.pos, ARENA) {
			unordered_remove(&g.bullets, i)
		}
	}
}

// Bullet vs enemy: both are destroyed and the bullet's owner gets a kill.
handle_bullet_enemy_hits :: proc(g: ^Game) {
	for ei := len(g.enemies) - 1; ei >= 0; ei -= 1 {
		for bi := len(g.bullets) - 1; bi >= 0; bi -= 1 {
			if rl.CheckCollisionCircles(g.enemies[ei].pos, ENEMY_RADIUS, g.bullets[bi].pos, BULLET_RADIUS) {
				g.players[g.bullets[bi].owner].kills += 1
				unordered_remove(&g.bullets, bi)
				unordered_remove(&g.enemies, ei)
				break // this enemy is gone, move on to the next one
			}
		}
	}
}
