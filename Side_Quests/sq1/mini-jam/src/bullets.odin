package arena

import "core:math/linalg"
import rl "vendor:raylib"

// Moves every bullet. Ricochet bullets bounce off the walls until their lifetime
// runs out; every other bullet (lasers included) disappears when it leaves the arena.
update_bullets :: proc(g: ^Game, dt: f32) {
	// Loop backwards: unordered_remove moves the last element into the removed
	// slot, so going forwards would skip the element that was moved.
	for i := len(g.bullets) - 1; i >= 0; i -= 1 {
		b := &g.bullets[i]
		b.pos += b.vel * dt

		if b.kind == .Ricochet {
			b.life -= dt
			bounce_off_walls(b)
			if b.life <= 0 do unordered_remove(&g.bullets, i)
		} else if !rl.CheckCollisionPointRec(b.pos, ARENA) {
			unordered_remove(&g.bullets, i)
		}
	}
}

// If the bullet has gone past a wall, mirror it back inside and flip the matching
// part of its velocity, like a ball bouncing off a wall.
bounce_off_walls :: proc(b: ^Bullet) {
	left, right := ARENA.x, ARENA.x + ARENA.width
	top, bottom := ARENA.y, ARENA.y + ARENA.height

	if b.pos.x < left {
		b.pos.x = left + (left - b.pos.x)
		b.vel.x = -b.vel.x
	} else if b.pos.x > right {
		b.pos.x = right - (b.pos.x - right)
		b.vel.x = -b.vel.x
	}
	if b.pos.y < top {
		b.pos.y = top + (top - b.pos.y)
		b.vel.y = -b.vel.y
	} else if b.pos.y > bottom {
		b.pos.y = bottom - (b.pos.y - bottom)
		b.vel.y = -b.vel.y
	}
}

// Sabotage bullet vs the other player: a hit (see hit_player), and the bullet is used up
// even if the hit is blocked by the blink, invincibility or a shield.
// Other bullets, and your own sabotage bullets, pass through players harmlessly.
// This runs before the enemy check, so if a sabotage bullet touches a player and an
// enemy on the same frame, the player hit wins.
handle_sabotage_hits :: proc(g: ^Game) {
	for bi := len(g.bullets) - 1; bi >= 0; bi -= 1 {
		b := g.bullets[bi]
		if b.kind != .Sabotage do continue
		for i in 0 ..< g.player_count {
			p := &g.players[i]
			if i == b.owner || !p.alive do continue
			if rl.CheckCollisionCircles(b.pos, bullet_radius(b), p.pos, PLAYER_RADIUS) {
				hit_player(p, SABOTAGE_DAMAGE)
				unordered_remove(&g.bullets, bi)
				break // this bullet is gone
			}
		}
	}
}

// Bullet vs enemy: the enemy dies and the bullet's owner gets a kill.
// The bullet is used up, except a laser, which keeps going through every enemy.
// Sabotage bullets hit enemies too, which wastes them (that's the trade-off).
handle_bullet_enemy_hits :: proc(g: ^Game) {
	for ei := len(g.enemies) - 1; ei >= 0; ei -= 1 {
		for bi := len(g.bullets) - 1; bi >= 0; bi -= 1 {
			b := g.bullets[bi]
			if bullet_hits_circle(b, g.enemies[ei].pos, ENEMY_RADIUS) {
				g.players[b.owner].kills += 1
				if b.kind != .Laser do unordered_remove(&g.bullets, bi)
				unordered_remove(&g.enemies, ei)
				break // this enemy is gone, move on to the next one
			}
		}
	}
}

// Does this bullet touch the circle? A laser is a line segment (from its tail to
// its tip); everything else is a small circle.
bullet_hits_circle :: proc(b: Bullet, center: rl.Vector2, radius: f32) -> bool {
	if b.kind == .Laser {
		tip, tail := laser_segment(b)
		return rl.CheckCollisionCircleLine(center, radius, tail, tip)
	}
	return rl.CheckCollisionCircles(b.pos, bullet_radius(b), center, radius)
}

// The two ends of a laser beam: `tip` is the front, `tail` is LASER_LENGTH behind it.
laser_segment :: proc(b: Bullet) -> (tip, tail: rl.Vector2) {
	return b.pos, b.pos - linalg.normalize0(b.vel) * LASER_LENGTH
}

// The size of a round bullet, by kind.
bullet_radius :: proc(b: Bullet) -> f32 {
	switch b.kind {
	case .Sabotage: return SABOTAGE_BULLET_RADIUS
	case .Ricochet: return RICOCHET_BULLET_RADIUS
	case .Normal, .Laser:
	}
	return BULLET_RADIUS
}
