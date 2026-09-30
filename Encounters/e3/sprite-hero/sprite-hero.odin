package main

import rl "vendor:raylib"

// sprite-hero: one character, nothing else. Your job (Class 7, Encounter E3):
//   Step 1 (TODOs 1-3): replace the blue rectangle with a 16x16 pixel-art
//                       character you drew yourself.
//   Step 2 (TODOs 4-6): make it walk - a sprite-strip animation.
// See README.md.

WINDOW_W :: 1280
WINDOW_H :: 720
GROUND_Y :: 560
SPEED :: 300.0 // pixels per second

// TODO 1: draw a 16x16 character in Pixelorama / LibreSprite / Piskel
// and export it as assets/hero.png, next to this file.
HERO_PATH :: #directory + "/assets/hero.png"
SCALE :: 4 // each art pixel becomes a 4x4 block on screen - whole numbers only

// --- Step 2: make it walk ---------------------------------------------------
// TODO 4: turn hero.png into a WALK STRIP: 4 frames side by side, each the same
// size as hero.png (4 frames of 16x16 -> one 64x16 PNG). Duplicate your
// character and move the legs. Export it as assets/hero-walk.png.
WALK_PATH :: #directory + "/assets/hero-walk.png"
WALK_FRAMES :: 4
FRAME_TIME :: 0.12 // seconds each frame stays on screen

Player :: struct {
	pos:         rl.Vector2, // the FEET: bottom-centre of the character
	facing_left: bool,
	frame:       int, // step 2: which frame of the walk strip is showing
	frame_timer: f32, // step 2: how long the current frame has been showing
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_W, WINDOW_H, "sprite-hero")
	defer rl.CloseWindow()

	// TODO 2: load the texture ONCE, here - never inside the loop.
	hero := rl.LoadTexture(HERO_PATH)
	defer rl.UnloadTexture(hero)
	// TODO 4 (cont.): load hero-walk.png here too, the same way.
	walk := rl.LoadTexture(WALK_PATH)
	defer rl.UnloadTexture(walk)

	player := Player{pos = {WINDOW_W / 2, GROUND_Y}}

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		// 1. INPUT
		dir: f32 = 0
		if rl.IsKeyDown(.RIGHT) do dir += 1
		if rl.IsKeyDown(.LEFT) do dir -= 1

		// 2. UPDATE
		player.pos.x = clamp(player.pos.x + dir * SPEED * dt, 0, WINDOW_W)
		if dir != 0 do player.facing_left = dir < 0

		// TODO 5: animate. While walking, add dt to player.frame_timer; each
		// time it passes FRAME_TIME, move to the next frame (wrap around with
		// % WALK_FRAMES). Standing still: back to frame 0.
		if dir != 0 {
			player.frame_timer += dt
			if player.frame_timer >= FRAME_TIME {
				player.frame_timer -= FRAME_TIME
				player.frame = (player.frame + 1) % WALK_FRAMES
			}
		} else {
			player.frame = 0
			player.frame_timer = 0
		}

		// 3. DRAW
		rl.BeginDrawing()
		rl.ClearBackground(rl.SKYBLUE)
		rl.DrawRectangle(0, GROUND_Y, WINDOW_W, WINDOW_H - GROUND_Y, rl.DARKGREEN)

		// TODO 3: replace this rectangle with your sprite (DrawTexturePro):
		// scaled by SCALE, with the origin at the FEET (bottom-centre).
		// TODO 6: draw from the walk strip instead of hero.png. One frame is
		// walk.width / WALK_FRAMES wide, and src.x = player.frame * that width.
		w := f32(walk.width) / WALK_FRAMES
		h := f32(walk.height)
		src := rl.Rectangle{f32(player.frame) * w, 0, w, h} // one frame of the strip
		dst := rl.Rectangle{player.pos.x, player.pos.y, w * SCALE, h * SCALE}
		origin := rl.Vector2{dst.width / 2, dst.height} // the feet: bottom-centre
		rl.DrawTexturePro(walk, src, dst, origin, 0, rl.WHITE)

		rl.EndDrawing()
	}
}
