package arena

import rl "vendor:raylib"

// ARENA: a top-down survival shooter, extended with LAN versus multiplayer.
// This file only owns the window and the game loop; see the other files in src/:
//   config.odin   tuning constants        types.odin    shared types (Game, Player, ...)
//   input.odin    keyboard/mouse          game.odin     per-frame update for solo/host/client
//   menu.odin     title and join menus    round.odin    round setup, update order, win/lose
//   player.odin   movement and shooting   bullets.odin  bullet movement and hits
//   enemies.odin  spawning and chasing    power_ups.odin  spawning and picking up power-ups
//   network.odin  UDP host/client messages
//   draw.odin     arena and screens       hud.odin      the text strip above the arena

main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "ARENA")
	defer rl.CloseWindow() // `defer` runs this when main returns, i.e. after the loop ends
	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL) // ESC goes back to the menu instead of closing the window

	g: Game
	defer delete(g.bullets)
	defer delete(g.enemies)
	defer delete(g.power_ups)
	defer close_network(&g.net)

	for !rl.WindowShouldClose() && !g.quit {
		// Cap dt so a stalled frame (e.g. dragging the window) doesn't teleport everything.
		dt := min(rl.GetFrameTime(), 1.0 / 30.0)
		update(&g, dt)
		draw(&g)
		free_all(context.temp_allocator) // fmt.ctprintf allocates its strings here each frame
	}
}
