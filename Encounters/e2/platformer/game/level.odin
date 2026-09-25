package game

// -----------------------------------------------------------------------------
// RESOURCES  --  the level is DATA, not code.
//
// Nothing in this file knows what a Player or a Goal DOES. It knows that the
// character 'P' means "spawn a Player here", because a table says so.
// -----------------------------------------------------------------------------

import "core:os"
import "core:strings"

TILE :: 32
LEVEL_W :: 30
LEVEL_H :: 20

Tile :: enum u8 {
	Empty,
	Solid,
}

// "there is a Walker at column 13, row 14" -- a request, not an entity yet.
SpawnMarker :: struct {
	kind:     EntityKind,
	col, row: int,
}

Level :: struct {
	tiles:       [LEVEL_H][LEVEL_W]Tile,
	spawns:      [MAX_ENTITIES]SpawnMarker,
	spawn_count: int,
	source:      cstring, // where it came from, for the HUD (cstring: raylib is C)
}

// THE LEGEND. Every piece of content in this game enters through this table:
// one row per character. A level editor is a program that writes these
// characters into a file -- it needs no other permission from the codebase.
Legend :: struct {
	char:  u8,
	tile:  Tile,
	spawn: EntityKind,
}

legend := [?]Legend {
	{'.', .Empty, .None},
	{'#', .Solid, .None},
	{'P', .Empty, .Player},
	{'E', .Empty, .Walker},
	{'T', .Empty, .Turner},
	{'C', .Empty, .Chaser},
	{'o', .Empty, .Coin},
	{'G', .Empty, .Goal},
}

legend_lookup :: proc(c: u8) -> (Legend, bool) {
	for e in legend {
		if e.char == c do return e, true
	}
	return {}, false
}

// -----------------------------------------------------------------------------

// Parse a level out of plain text. Returns ok=false on an unknown character,
// so a typo in the file is a reported error and not a silently empty room.
parse_level :: proc(text: string) -> (lv: Level, ok: bool) {
	rest := text
	row := 0
	for line in strings.split_lines_iterator(&rest) {
		if len(strings.trim_space(line)) == 0 do continue
		if row >= LEVEL_H do break

		for col in 0 ..< min(len(line), LEVEL_W) {
			entry, found := legend_lookup(line[col])
			if !found do return lv, false

			lv.tiles[row][col] = entry.tile
			if entry.spawn != .None && lv.spawn_count < MAX_ENTITIES {
				lv.spawns[lv.spawn_count] = {entry.spawn, col, row}
				lv.spawn_count += 1
			}
		}
		row += 1
	}
	return lv, row > 0
}

// The smallest honest resource manager: a lookup that ALWAYS returns something
// usable. Try each path, fall back to the level compiled into the binary.
load_level :: proc() -> Level {
	paths := [?]cstring{"level.txt", "platformer/level.txt", "source/platformer/level.txt"}

	for path in paths {
		data, err := os.read_entire_file_from_path(string(path), context.allocator)
		if err != nil do continue
		defer delete(data)

		if lv, parse_ok := parse_level(string(data)); parse_ok {
			lv.source = path
			return lv
		}
	}

	lv, _ := parse_level(BUILT_IN_LEVEL)
	lv.source = "built-in"
	return lv
}

// Tile queries live with the tiles. Outside the grid the world is walled in
// and floored, so nothing can leave the screen or fall forever.
tile_at :: proc(lv: ^Level, col, row: int) -> Tile {
	if col < 0 || col >= LEVEL_W do return .Solid
	if row >= LEVEL_H do return .Solid
	if row < 0 do return .Empty
	return lv.tiles[row][col]
}

// -----------------------------------------------------------------------------

BUILT_IN_LEVEL :: `..............................
..............................
..............................
..............................
..............................
..................G...........
..............#######.........
..............................
......T...o...................
....########..................
..............................
.................E............
..............#######.........
..............................
.........C....................
.....#######..................
..............................
.P...o....o....o..............
##############################
##############################`
