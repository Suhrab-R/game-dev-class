package game

import "../input"

// -----------------------------------------------------------------------------
// GAME-SPECIFIC  --  the rules of THIS game.
//
// Every number a designer would argue about is at the top of this file, and
// every "what does it MEAN when these two touch" decision is in one switch.
// Swap this file and the other seven still compile: that is the engine/game line.
// -----------------------------------------------------------------------------

GRAVITY    :: 1800.0 // pixels per second, per second
MOVE_SPEED :: 220.0  // pixels per second
JUMP_SPEED :: -700.0 // negative = up. Peak ~136 px: a 3-tile step is comfortable, a 5-tile step impossible
MAX_FALL   :: 900.0  // terminal velocity: also keeps one frame under one tile
WALK_SPEED :: 70.0   // the Walker's patrol speed

update_world :: proc(w: ^World, actions: input.Input, dt: f32) {
	clear_events(&w.events)
	w.squash = max(0, w.squash - dt)
	if w.state != .Playing do return
	w.elapsed += dt

	// ONE array, ONE loop. Adding a kind adds a case, not a code path.
	for &e in w.entities[:w.count] {
		if !e.alive do continue
		switch e.kind {
		case .Player: update_player(w, &e, actions, dt)
		case .Walker: update_walker(w, &e, dt)
		case .Turner: update_turner(w, &e, dt)
		case .Chaser: update_chaser(w, &e, dt)
		case .Goal, .Coin: // a goal just sits there -- and is still an entity
		case .None:
		}
	}

	check_touches(w)
	apply_events(w)
}

update_turner :: proc(w: ^World, e: ^Entity, dt: f32) {
	e.vel.x = e.facing * WALK_SPEED
	e.vel.y = min(e.vel.y + GRAVITY * dt, MAX_FALL)

	hit := move_and_collide(&w.level, &e.pos, &e.vel, e.size, dt)
	e.on_ground = grounded(&w.level, e.pos, e.size)
	if e.on_ground && e.vel.y > 0 do e.vel.y = 0

	if hit.left || hit.right do e.facing = -e.facing
}

update_chaser :: proc(w: ^World, e: ^Entity, dt: f32) {
	player := w.entities[w.player]
	e.facing = -1 if player.pos.x < e.pos.x else 1
	e.vel.x = e.facing * WALK_SPEED
	e.vel.y = min(e.vel.y + GRAVITY * dt, MAX_FALL)

	e.on_ground = grounded(&w.level, e.pos, e.size)
	probe_x := e.pos.x + (e.size.x if e.facing > 0 else -1)
	probe_y := e.pos.y + e.size.y + 1
	ledge_ahead := tile_at(&w.level, tile_of(probe_x), tile_of(probe_y)) != .Solid
	if e.on_ground && ledge_ahead do e.vel.x = 0

	move_and_collide(&w.level, &e.pos, &e.vel, e.size, dt)
	e.on_ground = grounded(&w.level, e.pos, e.size)
	if e.on_ground && e.vel.y > 0 do e.vel.y = 0
}

// Note what is absent: this procedure never asks which button was pressed.
update_player :: proc(w: ^World, e: ^Entity, actions: input.Input, dt: f32) {
	dir: f32 = 0
	if .Left in actions.held do dir -= 1
	if .Right in actions.held do dir += 1
	e.vel.x = dir * MOVE_SPEED
	if dir != 0 do e.facing = dir

	if (.Jump in actions.pressed) && e.on_ground {
		e.vel.y = JUMP_SPEED
		post(&w.events, .PlayerJumped, e.pos)
	}

	e.vel.y = min(e.vel.y + GRAVITY * dt, MAX_FALL)

	was_grounded := e.on_ground
	move_and_collide(&w.level, &e.pos, &e.vel, e.size, dt)
	e.on_ground = grounded(&w.level, e.pos, e.size)

	// Do not let gravity keep accumulating while standing: otherwise walking
	// off a ledge starts the fall at whatever speed the floor was absorbing.
	if e.on_ground && e.vel.y > 0 do e.vel.y = 0
	if e.on_ground && !was_grounded do post(&w.events, .PlayerLanded, e.pos)
}

// The whole brain of the enemy: walk, turn at a wall, turn at a ledge.
// Chapter 13 replaces these three lines with a state machine.
update_walker :: proc(w: ^World, e: ^Entity, dt: f32) {
	e.vel.x = e.facing * WALK_SPEED
	e.vel.y = min(e.vel.y + GRAVITY * dt, MAX_FALL)

	hit := move_and_collide(&w.level, &e.pos, &e.vel, e.size, dt)
	e.on_ground = grounded(&w.level, e.pos, e.size)
	if e.on_ground && e.vel.y > 0 do e.vel.y = 0

	// one pixel past the leading edge; the turn lands a frame later, so the
	// walker may overhang the ledge by a pixel or two. That is cheap and fine.
	probe_x := e.pos.x + (e.size.x if e.facing > 0 else -1)
	probe_y := e.pos.y + e.size.y + 1
	ledge_ahead := tile_at(&w.level, tile_of(probe_x), tile_of(probe_y)) != .Solid

	if hit.left || hit.right || (e.on_ground && ledge_ahead) {
		e.facing = -e.facing
	}
}

// The ONLY place in the game that says what contact MEANS. Everything here is
// a post, never a decision: this procedure does not know what dying involves.
check_touches :: proc(w: ^World) {
	if w.player < 0 do return
	player := w.entities[w.player]
	if !player.alive do return

	for e, i in w.entities[:w.count] {
		if i == w.player || !e.alive do continue
		if !overlapping(player.pos, player.size, e.pos, e.size) do continue

		switch e.kind {
		case .Walker, .Turner, .Chaser: post(&w.events, .PlayerDied, player.pos, w.player)
		case .Goal:   post(&w.events, .GoalReached, player.pos, w.player)
		case .Coin:   post(&w.events, .CoinCollected, e.pos, i)
		case .Player, .None:
		}
	}
}

// THE LISTENERS. Everything that reacts is in one place, and none of it lives
// inside the code that caused it. The Walker does not know the game can end.
apply_events :: proc(w: ^World) {
	for ev in drain(&w.events) {
		switch ev.kind {
		case .PlayerDied:
			w.state = .Dead
		case .GoalReached:
			w.state = .Won
		case .PlayerJumped:
			w.squash = 0.22 // cosmetic only -- the renderer reads it, nothing else
		case .PlayerLanded:
			w.squash = 0.16
		case .CoinCollected:
			w.coins += 1
			w.entities[ev.entity].alive = false
		}
	}
}
