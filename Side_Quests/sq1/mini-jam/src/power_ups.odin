package arena

import "core:math/rand"
import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Power-ups: they appear at random spots and random intervals, and whoever
// touches one first gets its effect.
//
// Weapons (sabotage, rapid fire, laser, ricochet, shotgun) replace each other:
// picking one up ends whatever weapon you had. Defensive ones (invincibility,
// extra HP, shield) stack with everything.
// ---------------------------------------------------------------------------

// How likely each kind is to spawn, relative to the others. The weights add up
// to 100, so in versus each one is a percentage (laser 15%, invincibility 7%).
// In solo, Sabotage is left out, so the others become slightly more likely.
power_up_weight :: proc(kind: Power_Up_Kind) -> int {
	switch kind {
	case .Sabotage:      return 16
	case .Laser:         return 15
	case .Rapid_Fire:    return 13
	case .Shotgun:       return 13
	case .Ricochet:      return 12
	case .Shield:        return 12
	case .Extra_HP:      return 12
	case .Invincibility: return 7
	}
	return 0
}

// Spawns a power-up every POWER_UP_INTERVAL seconds, up to MAX_POWER_UPS on the
// field. The timer only runs while there's room, so a full field doesn't build up
// a queue: the next one comes POWER_UP_INTERVAL seconds after space frees up.
update_power_up_spawning :: proc(g: ^Game, dt: f32) {
	if len(g.power_ups) >= MAX_POWER_UPS do return

	g.power_up_timer -= dt
	if g.power_up_timer > 0 do return

	append(&g.power_ups, Power_Up{pos = random_power_up_point(), kind = random_power_up_kind(g)})
	g.power_up_timer = POWER_UP_INTERVAL
}

// Picks a kind using the weights above, like spinning a wheel where each kind's
// slice is as big as its weight. Sabotage is left out in solo (there's no one to sabotage).
random_power_up_kind :: proc(g: ^Game) -> Power_Up_Kind {
	total := 0
	for kind in Power_Up_Kind { // loops over every value of the enum
		if can_spawn(g, kind) do total += power_up_weight(kind)
	}

	roll := rand.int_max(total) // 0 ..< total
	for kind in Power_Up_Kind {
		if !can_spawn(g, kind) do continue
		roll -= power_up_weight(kind)
		if roll < 0 do return kind
	}
	return .Extra_HP // not reachable, but the compiler needs a return
}

can_spawn :: proc(g: ^Game, kind: Power_Up_Kind) -> bool {
	return kind != .Sabotage || g.player_count == 2
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
		equip_weapon(p, .Sabotage)
		p.sabotage_shots = SABOTAGE_SHOTS
	case .Rapid_Fire: equip_weapon(p, .Rapid_Fire)
	case .Laser:      equip_weapon(p, .Laser)
	case .Ricochet:   equip_weapon(p, .Ricochet)
	case .Shotgun:    equip_weapon(p, .Shotgun)

	case .Invincibility:
		p.invincible_timer = INVINCIBILITY_DURATION // refills, doesn't stack
	case .Extra_HP:
		p.hp = min(p.hp + 1, BONUS_HP_CAP)
	case .Shield:
		p.shield_hits = SHIELD_HITS // refills, doesn't stack
	}
}

// Replaces the player's weapon (ending any weapon they had, including leftover
// sabotage shots) and starts its WEAPON_DURATION timer.
equip_weapon :: proc(p: ^Player, weapon: Weapon) {
	p.weapon = weapon
	p.weapon_timer = WEAPON_DURATION
	p.sabotage_shots = 0
	p.fire_cooldown = 0 // the new weapon can fire straight away
}

// A random point inside the arena, at least POWER_UP_MARGIN away from the walls.
random_power_up_point :: proc() -> rl.Vector2 {
	return {
		rand.float32_range(ARENA.x + POWER_UP_MARGIN, ARENA.x + ARENA.width - POWER_UP_MARGIN),
		rand.float32_range(ARENA.y + POWER_UP_MARGIN, ARENA.y + ARENA.height - POWER_UP_MARGIN),
	}
}
