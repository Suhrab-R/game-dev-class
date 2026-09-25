package main

// -----------------------------------------------------------------------------
// THE SPINE  --  the only file that knows every other module exists.
//
// Read it top to bottom: poll -> update -> draw, sixty times a second.
// Eight raylib calls hold up the entire game, and all eight are in this file.
//
//   odin run source/platformer
// -----------------------------------------------------------------------------

import "game"
import "input"
import "render"
import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(render.WINDOW_W, render.WINDOW_H, "One screen, one goal, one enemy")
	defer rl.CloseWindow() // load/unload discipline, paired at the load

	rl.SetTargetFPS(60)

	level := game.load_level()
	world: game.World
	game.world_start(&world, level)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		actions := input.poll_input()

		// F5 re-reads level.txt. THIS is what "the level is data" buys you:
		// edit the file in another window, tab back, see it -- with no rebuild.
		// It is the cheap half of scripting, and it is all most games need.
		if .ReloadLevel in actions.pressed {
			level = game.load_level()
			game.world_start(&world, level)
		}
		if (.Restart in actions.pressed) || (world.state != .Playing && .Jump in actions.pressed) {
			game.world_start(&world, level)
		}

		game.update_world(&world, actions, dt) // changes everything, draws nothing

		rl.BeginDrawing()
		rl.ClearBackground(render.BG)
		render.draw_world(&world) // draws everything, changes nothing
		rl.EndDrawing()
	}
}
