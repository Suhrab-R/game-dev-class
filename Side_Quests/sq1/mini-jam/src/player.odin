package arena

import "core:math/linalg"

// Advances one player by one frame: timers, movement and shooting.
// Dead players do nothing (in versus the round ends as soon as someone dies anyway).
update_player :: proc(g: ^Game, index: int, input: Player_Input, dt: f32) {
	p := &g.players[index] // `&x` takes the address, so `p` is a pointer we can modify through
	if !p.alive do return

	p.invuln_timer -= dt
	move_player(p, input, dt)
	try_shoot(g, index, input, dt)
}

// Moves the player in the input direction and keeps them inside the arena.
move_player :: proc(p: ^Player, input: Player_Input, dt: f32) {
	// normalize0 turns the direction into length 1 (so diagonals aren't faster)
	// and safely returns {0, 0} when there is no input.
	p.pos += linalg.normalize0(input.move) * PLAYER_SPEED * dt
	p.pos.x = clamp(p.pos.x, ARENA.x + PLAYER_RADIUS, ARENA.x + ARENA.width - PLAYER_RADIUS)
	p.pos.y = clamp(p.pos.y, ARENA.y + PLAYER_RADIUS, ARENA.y + ARENA.height - PLAYER_RADIUS)
}

// Fires a bullet toward the aim point if the button is held and the cooldown has run out.
try_shoot :: proc(g: ^Game, index: int, input: Player_Input, dt: f32) {
	p := &g.players[index]
	p.fire_cooldown -= dt
	if !input.shooting || p.fire_cooldown > 0 || len(g.bullets) >= MAX_BULLETS do return

	dir := linalg.normalize0(input.aim - p.pos)
	if dir == {0, 0} do return // aiming exactly at yourself: no direction to shoot in

	// If this player has sabotage shots left, this bullet is one of them.
	sabotage := p.sabotage_shots > 0
	if sabotage do p.sabotage_shots -= 1

	append(&g.bullets, Bullet{pos = p.pos, vel = dir * BULLET_SPEED, owner = index, sabotage = sabotage})
	p.fire_cooldown = FIRE_COOLDOWN
}

// Applies one enemy hit to a player: lose 1 HP, then a short invulnerability window.
damage_player :: proc(p: ^Player) {
	if p.invuln_timer > 0 do return
	p.hp -= 1
	p.invuln_timer = PLAYER_INVULN
	if p.hp <= 0 do p.alive = false
}

// Applies a sabotage bullet hit: lose SABOTAGE_DAMAGE HP, then the same short
// invulnerability window as an enemy hit. A sabotage bullet that lands during the
// blink does nothing (and is still used up), so firing all three at once is a waste.
sabotage_player :: proc(p: ^Player) {
	if p.invuln_timer > 0 do return
	p.hp -= SABOTAGE_DAMAGE
	p.invuln_timer = PLAYER_INVULN
	if p.hp <= 0 do p.alive = false
}
