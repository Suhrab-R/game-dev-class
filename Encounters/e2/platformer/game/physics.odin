package game

// -----------------------------------------------------------------------------
// COLLISION  --  geometry, and nothing else.
//
// This file knows about rectangles and solid tiles. It does not know that one
// of those rectangles is the player, and it NEVER decides what a hit means.
// Detection here; response in rules.odin. (Chapter 9 makes this a system.)
// -----------------------------------------------------------------------------

import "core:math"
import rl "vendor:raylib"

// Which sides stopped us this frame. The caller decides what that implies --
// the player reads `down` as "I may jump", the walker reads it as "turn around".
Hits :: struct {
	left, right, up, down: bool,
}

tile_of :: proc(v: f32) -> int {
	return int(math.floor(v / TILE))
}

// Four comparisons. That is the whole of AABB overlap, and writing it here
// rather than calling rl.CheckCollisionRecs keeps raylib out of this floor.
//
// Note the arguments: two positions and two sizes, NOT two Entities. This file
// is not allowed to know that one of these boxes is the player.
overlapping :: proc(a_pos, a_size, b_pos, b_size: rl.Vector2) -> bool {
	return(
		a_pos.x < b_pos.x + b_size.x &&
		b_pos.x < a_pos.x + a_size.x &&
		a_pos.y < b_pos.y + b_size.y &&
		b_pos.y < a_pos.y + a_size.y \
	)
}

// Does this rectangle overlap any solid tile? Only the tiles it could possibly
// touch are tested -- the grid IS the spatial partition. (Chapter 10.)
solid_rect :: proc(lv: ^Level, pos, size: rl.Vector2) -> bool {
	c0, c1 := tile_of(pos.x), tile_of(pos.x + size.x - 1)
	r0, r1 := tile_of(pos.y), tile_of(pos.y + size.y - 1)

	for r in r0 ..= r1 {
		for c in c0 ..= c1 {
			if tile_at(lv, c, r) == .Solid do return true
		}
	}
	return false
}

// "Am I standing on something?" is a QUESTION, asked of the world, and not a
// souvenir of the last collision. A body at rest only actually collides on the
// frames gravity has pushed it far enough into the tile -- so a flag set from
// `hit.down` flickers on and off every other frame, and half of the player's
// jumps get silently eaten. Probe one pixel down instead. It is always true.
grounded :: proc(lv: ^Level, pos, size: rl.Vector2) -> bool {
	return solid_rect(lv, {pos.x, pos.y + 1}, size)
}

// Move one axis at a time. That is the whole trick: resolving X and Y
// separately is what produces "slides along the wall" instead of "sticks to
// the corner", and it is why a jump into a ceiling does not cancel your run.
move_and_collide :: proc(lv: ^Level, pos, vel: ^rl.Vector2, size: rl.Vector2, dt: f32) -> (hit: Hits) {
	// --- X, alone ---
	// The `!= 0` guard is not an optimisation. Without it, a body that is
	// already inside a tile -- a fresh spawn, a teleport, a reloaded level --
	// resolves on BOTH axes and gets flung a whole tile sideways by a
	// collision the Y axis caused. An axis that did not move never resolves.
	if vel.x != 0 {
		pos.x += vel.x * dt
		if solid_rect(lv, pos^, size) {
			if vel.x > 0 {
				pos.x = f32(tile_of(pos.x + size.x) * TILE) - size.x
				hit.right = true
			} else {
				pos.x = f32((tile_of(pos.x) + 1) * TILE)
				hit.left = true
			}
			vel.x = 0
		}
	}

	// --- Y, alone ---
	if vel.y != 0 {
		pos.y += vel.y * dt
		if solid_rect(lv, pos^, size) {
			if vel.y > 0 {
				pos.y = f32(tile_of(pos.y + size.y) * TILE) - size.y
				hit.down = true
			} else {
				pos.y = f32((tile_of(pos.y) + 1) * TILE)
				hit.up = true
			}
			vel.y = 0
		}
	}
	return
}
