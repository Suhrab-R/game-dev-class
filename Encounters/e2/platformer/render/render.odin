package render

// -----------------------------------------------------------------------------
// RENDERER + FRONT END  --  draws the world and never changes it.
//
// Every procedure in this file is named draw_*; no procedure in this file is
// named update_*. The pointer below is for cheapness, not permission: nothing
// here writes through it. That discipline is the update/render seam.
// -----------------------------------------------------------------------------

import "../game"
import rl "vendor:raylib"

// The renderer owns the screen, so the screen's size is declared here and
// main.odin reads it -- not the other way round.
WINDOW_W :: game.LEVEL_W * game.TILE // 960
WINDOW_H :: game.LEVEL_H * game.TILE // 640

BG        :: rl.Color{24, 26, 38, 255}
TILE_FILL :: rl.Color{58, 64, 92, 255}
TILE_EDGE :: rl.Color{92, 102, 142, 255}

// A table, not a switch chain. Colours are presentation; keep them out of rules.
entity_color :: proc(kind: game.EntityKind) -> rl.Color {
	switch kind {
	case .Player: return {96, 200, 255, 255}
	case .Walker: return {236, 84, 92, 255}
	case .Turner: return {255, 140, 90, 255}
	case .Chaser: return {180, 110, 255, 255}
	case .Coin:   return {255, 215, 64, 255}
	case .Goal:   return {255, 206, 72, 255}
	case .None:   return rl.BLANK
	}
	return rl.BLANK
}

draw_world :: proc(w: ^game.World) {
	draw_tiles(&w.level)
	draw_entities(w)
	draw_hud(w)
	draw_overlay(w)
}

draw_tiles :: proc(lv: ^game.Level) {
	for row in 0 ..< game.LEVEL_H {
		for col in 0 ..< game.LEVEL_W {
			if lv.tiles[row][col] != .Solid do continue
			x, y := i32(col * game.TILE), i32(row * game.TILE)
			rl.DrawRectangle(x, y, game.TILE, game.TILE, TILE_FILL)
			// a lit top edge, but only where the tile is actually exposed
			if game.tile_at(lv, col, row - 1) != .Solid {
				rl.DrawRectangle(x, y, game.TILE, 3, TILE_EDGE)
			}
		}
	}
}

draw_entities :: proc(w: ^game.World) {
	for e in w.entities[:w.count] {
		if !e.alive do continue

		size := e.size
		if e.kind == .Player && w.squash > 0 {
			// a purely cosmetic reaction to an EVENT the renderer did not cause
			size = {e.size.x * (1 + w.squash), e.size.y * (1 - w.squash)}
		}
		pos := rl.Vector2{
			e.pos.x - (size.x - e.size.x) / 2,
			e.pos.y + (e.size.y - size.y),
		}

		rl.DrawRectangleV(pos, size, entity_color(e.kind))

		// one eye, so "which way is it facing" is visible in a still screenshot
		if e.kind == .Player || e.kind == .Walker || e.kind == .Turner || e.kind == .Chaser {
			eye := rl.Vector2{
				pos.x + (size.x - 6 if e.facing > 0 else 2),
				pos.y + size.y * 0.25,
			}
			rl.DrawRectangleV(eye, {4, 4}, BG)
		}
	}
}

draw_hud :: proc(w: ^game.World) {
	// rl.TextFormat is C varargs: it cannot see Odin's types. An Odin `string`
	// is a (pointer, length) pair and would print garbage for %s, and an f32
	// must be widened to f64 for %f. Both casts below are load-bearing.
	rl.DrawText(rl.TextFormat("level: %s", w.level.source), 12, 10, 18, rl.GRAY)
	rl.DrawText(rl.TextFormat("coins: %d", w.coins), 12, 34, 18, rl.Color{255, 215, 64, 255})
	rl.DrawText(rl.TextFormat("%.1f s", f64(w.elapsed)), WINDOW_W - 90, 10, 18, rl.GRAY)
	rl.DrawText("A/D move   SPACE jump   R restart   F5 reload level.txt", 12, WINDOW_H - 24, 18, rl.Color{120, 130, 165, 255})
}

draw_overlay :: proc(w: ^game.World) {
	// This switch is deliberately a SECOND one. update_world decides; this one
	// presents. They will diverge, and that is what makes them two switches.
	switch w.state {
	case .Playing:
	// no overlay -- just play
	case .Won:
		draw_banner("REACHED THE GOAL", rl.TextFormat("%.1f seconds   --   R to play again", f64(w.elapsed)), rl.Color{255, 206, 72, 255})
	case .Dead:
		draw_banner("AN ENEMY GOT YOU", "R to try again", rl.Color{236, 84, 92, 255})
	}
}

draw_banner :: proc(title, hint: cstring, tint: rl.Color) {
	rl.DrawRectangle(0, WINDOW_H / 2 - 70, WINDOW_W, 140, rl.Color{16, 18, 28, 220})
	draw_centered(title, WINDOW_H / 2 - 44, 44, tint)
	draw_centered(hint, WINDOW_H / 2 + 14, 22, rl.LIGHTGRAY)
}

draw_centered :: proc(text: cstring, y, size: i32, color: rl.Color) {
	rl.DrawText(text, WINDOW_W / 2 - rl.MeasureText(text, size) / 2, y, size, color)
}
