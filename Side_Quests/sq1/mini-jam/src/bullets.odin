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

// Sabotage bullet vs the other player: they lose SABOTAGE_DAMAGE HP and the bullet is used up.
// Normal bullets (and your own sabotage bullets) pass through players harmlessly.
// This runs before the enemy check, so if a sabotage bullet touches a player and an
// enemy on the same frame, the player hit wins.
handle_sabotage_hits :: proc(g: ^Game) {
	for bi := len(g.bullets) - 1; bi >= 0; bi -= 1 {
		b := g.bullets[bi]
		if !b.sabotage do continue
		for i in 0 ..< g.player_count {
			p := &g.players[i]
			if i == b.owner || !p.alive do continue
			if rl.CheckCollisionCircles(b.pos, bullet_radius(b), p.pos, PLAYER_RADIUS) {
				sabotage_player(p)
				unordered_remove(&g.bullets, bi)
				break // this bullet is gone
			}
		}
	}
}

// Bullet vs enemy: both are destroyed and the bullet's owner gets a kill.
// Sabotage bullets hit enemies too, which wastes them (that's the trade-off).
handle_bullet_enemy_hits :: proc(g: ^Game) {
	for ei := len(g.enemies) - 1; ei >= 0; ei -= 1 {
		for bi := len(g.bullets) - 1; bi >= 0; bi -= 1 {
			b := g.bullets[bi]
			if rl.CheckCollisionCircles(g.enemies[ei].pos, ENEMY_RADIUS, b.pos, bullet_radius(b)) {
				g.players[b.owner].kills += 1
				unordered_remove(&g.bullets, bi)
				unordered_remove(&g.enemies, ei)
				break // this enemy is gone, move on to the next one
			}
		}
	}
}

// Sabotage bullets are drawn and collide a little bigger than normal ones.
bullet_radius :: proc(b: Bullet) -> f32 {
	return b.sabotage ? SABOTAGE_BULLET_RADIUS : BULLET_RADIUS
}
