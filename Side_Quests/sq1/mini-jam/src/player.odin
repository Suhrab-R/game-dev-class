package arena

import "core:math/linalg"
import rl "vendor:raylib"

// Advances one player by one frame: timers, movement and shooting.
// Dead players do nothing (in versus the round ends as soon as someone dies anyway).
update_player :: proc(g: ^Game, index: int, input: Player_Input, dt: f32) {
	p := &g.players[index] // `&x` takes the address, so `p` is a pointer we can modify through
	if !p.alive do return

	update_player_timers(p, dt)
	move_player(p, input, dt)
	try_shoot(g, index, input, dt)
}

// Counts down the hit blink and the power-up timers, ending power-ups that run out.
update_player_timers :: proc(p: ^Player, dt: f32) {
	p.invuln_timer -= dt
	p.invincible_timer = max(0, p.invincible_timer - dt)

	// Sabotage is counted in shots (see try_shoot); every other weapon is timed.
	if p.weapon != .Normal && p.weapon != .Sabotage {
		p.weapon_timer -= dt
		if p.weapon_timer <= 0 do p.weapon = .Normal
	}
}

// Moves the player in the input direction and keeps them inside the arena.
move_player :: proc(p: ^Player, input: Player_Input, dt: f32) {
	// normalize0 turns the direction into length 1 (so diagonals aren't faster)
	// and safely returns {0, 0} when there is no input.
	p.pos += linalg.normalize0(input.move) * PLAYER_SPEED * dt
	p.pos.x = clamp(p.pos.x, ARENA.x + PLAYER_RADIUS, ARENA.x + ARENA.width - PLAYER_RADIUS)
	p.pos.y = clamp(p.pos.y, ARENA.y + PLAYER_RADIUS, ARENA.y + ARENA.height - PLAYER_RADIUS)
}

// Fires toward the aim point if the button is held and the cooldown has run out.
// What comes out, and how soon the next shot is allowed, depends on the weapon.
try_shoot :: proc(g: ^Game, index: int, input: Player_Input, dt: f32) {
	p := &g.players[index]
	p.fire_cooldown -= dt
	if !input.shooting || p.fire_cooldown > 0 do return

	dir := linalg.normalize0(input.aim - p.pos)
	if dir == {0, 0} do return // aiming exactly at yourself: no direction to shoot in

	switch p.weapon {
	case .Normal:
		fire_bullet(g, index, dir, .Normal, BULLET_SPEED)
		p.fire_cooldown = FIRE_COOLDOWN

	case .Sabotage:
		fire_bullet(g, index, dir, .Sabotage, BULLET_SPEED)
		p.fire_cooldown = FIRE_COOLDOWN
		p.sabotage_shots -= 1
		if p.sabotage_shots <= 0 do p.weapon = .Normal

	case .Rapid_Fire:
		fire_bullet(g, index, dir, .Normal, BULLET_SPEED)
		p.fire_cooldown = RAPID_FIRE_COOLDOWN

	case .Laser:
		fire_bullet(g, index, dir, .Laser, LASER_SPEED)
		p.fire_cooldown = LASER_COOLDOWN

	case .Ricochet:
		fire_bullet(g, index, dir, .Ricochet, BULLET_SPEED)
		p.fire_cooldown = FIRE_COOLDOWN

	case .Shotgun:
		// Pellets fan out evenly around the aim direction: with 3 pellets the
		// angles are -SPREAD, 0 and +SPREAD.
		middle := f32(SHOTGUN_PELLETS - 1) / 2
		for i in 0 ..< SHOTGUN_PELLETS {
			angle := (f32(i) - middle) * SHOTGUN_SPREAD
			fire_bullet(g, index, rl.Vector2Rotate(dir, angle), .Normal, BULLET_SPEED)
		}
		p.fire_cooldown = SHOTGUN_COOLDOWN
	}
}

// Adds one bullet leaving the player in direction `dir` (a length-1 vector).
fire_bullet :: proc(g: ^Game, owner: int, dir: rl.Vector2, kind: Bullet_Kind, speed: f32) {
	if len(g.bullets) >= MAX_BULLETS do return
	append(&g.bullets, Bullet {
		pos   = g.players[owner].pos,
		vel   = dir * speed,
		owner = owner,
		kind  = kind,
		life  = RICOCHET_LIFETIME, // only ricochet bullets use this
	})
}

// Applies one hit to a player (an enemy touching them, or a sabotage bullet).
// In order: invincibility ignores it; during the blink after a previous hit it
// does nothing; a shield absorbs it; otherwise the player loses `damage` HP.
// Every hit that lands (shield or not) starts the blink.
hit_player :: proc(p: ^Player, damage: int) {
	if p.invincible_timer > 0 || p.invuln_timer > 0 do return

	p.invuln_timer = PLAYER_INVULN
	if p.shield_hits > 0 {
		p.shield_hits -= 1
		return
	}
	p.hp -= damage
	if p.hp <= 0 do p.alive = false
}
