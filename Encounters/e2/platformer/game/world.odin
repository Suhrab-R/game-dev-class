package game

// -----------------------------------------------------------------------------
// GAMEPLAY FOUNDATIONS  --  the bridge between the engine and the rules.
//
// Entities exist here as DATA. No behaviour, no drawing, no input, no opinion
// about what a Walker is for. This file answers "what is there", never "what
// does it do" -- that is rules.odin.
// -----------------------------------------------------------------------------

import rl "vendor:raylib"

MAX_ENTITIES :: 64

// A `kind` is a VALUE: compare it, save it, index a table with it, change it at
// runtime. Add a case and every switch that forgot it fails to compile.
EntityKind :: enum u8 {
	None,
	Player,
	Walker,
	Goal,
	Turner,
	Chaser,
	Coin,
}

// One struct for every kind of thing. A Goal carries a velocity it never uses;
// that costs 8 bytes and buys one array, one loop, one code path.
Entity :: struct {
	kind:      EntityKind,
	pos:       rl.Vector2, // top-left corner, in pixels
	vel:       rl.Vector2, // pixels per second
	size:      rl.Vector2,
	facing:    f32,  // -1 left, +1 right
	on_ground: bool,
	alive:     bool, // set false to remove it from play without moving anything
}

GameState :: enum {
	Playing,
	Won,
	Dead,
}

World :: struct {
	level:    Level,
	entities: [MAX_ENTITIES]Entity,
	count:    int,
	player:   int, // index into entities; -1 if the level has no P
	state:    GameState,
	events:   EventQueue,
	elapsed:  f32,
	squash:   f32, // render-only feedback, written by an event listener
	coins:    int,
}

entity_size :: proc(kind: EntityKind) -> rl.Vector2 {
	switch kind {
	case .Player: return {24, 28}
	case .Walker: return {26, 26}
	case .Turner: return {26, 26}
	case .Chaser: return {26, 26}
	case .Coin:   return {16, 16}
	case .Goal:   return {24, 32}
	case .None:   return {}
	}
	return {}
}

spawn :: proc(w: ^World, kind: EntityKind, col, row: int) -> int {
	if w.count >= MAX_ENTITIES do return -1

	size := entity_size(kind)
	i := w.count
	w.count += 1
	w.entities[i] = Entity {
		kind   = kind,
		size   = size,
		facing = 1,
		alive  = true,
		// sit it on the floor of its tile, centred left-to-right
		pos    = {f32(col * TILE) + (TILE - size.x) / 2, f32(row * TILE) + TILE - size.y},
	}
	return i
}

// Build a run from a level. "Restart" and "load a different level" are the
// same procedure, which is why neither of them is a special case anywhere.
world_start :: proc(w: ^World, lv: Level) {
	w^ = World{level = lv, player = -1}

	for m in w.level.spawns[:w.level.spawn_count] {
		i := spawn(w, m.kind, m.col, m.row)
		if m.kind == .Player do w.player = i
	}
}
