package arena

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Tuning
// ---------------------------------------------------------------------------

SCREEN_W :: 1280
SCREEN_H :: 720

// The playable area, inset from the window so the HUD has room at the top.
ARENA :: rl.Rectangle{40, 80, SCREEN_W - 80, SCREEN_H - 120}

ROUND_LENGTH :: 90.0 // seconds to survive to win

PLAYER_RADIUS     :: 14.0
PLAYER_SPEED      :: 260.0
PLAYER_MAX_HP     :: 5
PLAYER_INVULN     :: 1.0  // seconds of invulnerability after a hit
FIRE_COOLDOWN     :: 0.15 // seconds between shots

BULLET_RADIUS :: 4.0
BULLET_SPEED  :: 700.0

ENEMY_RADIUS        :: 12.0
ENEMY_BASE_SPEED    :: 90.0
ENEMY_SPEED_GROWTH  :: 1.2  // extra speed per second survived
SPAWN_START_INTERVAL :: 1.2 // seconds between spawns at the start
SPAWN_MIN_INTERVAL   :: 0.25
SPAWN_RAMP           :: 0.011 // how much the interval shrinks per second survived

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

State :: enum {
	Title,
	Playing,
	Won,
	Lost,
}

Player :: struct {
	pos:           rl.Vector2,
	hp:            int,
	invuln_timer:  f32,
	fire_cooldown: f32,
}

Bullet :: struct {
	pos: rl.Vector2,
	vel: rl.Vector2,
}

Enemy :: struct {
	pos: rl.Vector2,
}

Game :: struct {
	state:       State,
	player:      Player,
	bullets:     [dynamic]Bullet,
	enemies:     [dynamic]Enemy,
	time:        f32, // seconds survived this round
	spawn_timer: f32,
	score:       int,
}

// ---------------------------------------------------------------------------
// Round setup
// ---------------------------------------------------------------------------

reset :: proc(g: ^Game) {
	g.player = Player {
		pos = {ARENA.x + ARENA.width / 2, ARENA.y + ARENA.height / 2},
		hp  = PLAYER_MAX_HP,
	}
	clear(&g.bullets)
	clear(&g.enemies)
	g.time = 0
	g.spawn_timer = SPAWN_START_INTERVAL
	g.score = 0
}

// Picks a random point on one of the four arena edges.
random_edge_point :: proc() -> rl.Vector2 {
	t := rand.float32()
	switch rand.int_max(4) {
	case 0: return {ARENA.x + t * ARENA.width, ARENA.y}                // top
	case 1: return {ARENA.x + t * ARENA.width, ARENA.y + ARENA.height} // bottom
	case 2: return {ARENA.x, ARENA.y + t * ARENA.height}               // left
	case:   return {ARENA.x + ARENA.width, ARENA.y + t * ARENA.height} // right
	}
}

// ---------------------------------------------------------------------------
// Update
// ---------------------------------------------------------------------------

update_playing :: proc(g: ^Game, dt: f32) {
	g.time += dt
	if g.time >= ROUND_LENGTH {
		g.state = .Won
		return
	}

	// --- Player movement (WASD / arrows) ---
	move: rl.Vector2
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)    do move.y -= 1
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)  do move.y += 1
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)  do move.x -= 1
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) do move.x += 1
	// normalize0 keeps diagonal movement the same speed and returns 0 for no input.
	g.player.pos += linalg.normalize0(move) * PLAYER_SPEED * dt
	g.player.pos.x = clamp(g.player.pos.x, ARENA.x + PLAYER_RADIUS, ARENA.x + ARENA.width - PLAYER_RADIUS)
	g.player.pos.y = clamp(g.player.pos.y, ARENA.y + PLAYER_RADIUS, ARENA.y + ARENA.height - PLAYER_RADIUS)

	// --- Shooting (hold left mouse, aim with cursor) ---
	g.player.fire_cooldown -= dt
	if rl.IsMouseButtonDown(.LEFT) && g.player.fire_cooldown <= 0 {
		dir := linalg.normalize0(rl.GetMousePosition() - g.player.pos)
		if dir != {0, 0} {
			append(&g.bullets, Bullet{pos = g.player.pos, vel = dir * BULLET_SPEED})
			g.player.fire_cooldown = FIRE_COOLDOWN
		}
	}

	// --- Bullets: move, and remove the ones that leave the arena ---
	for i := len(g.bullets) - 1; i >= 0; i -= 1 {
		b := &g.bullets[i]
		b.pos += b.vel * dt
		if !rl.CheckCollisionPointRec(b.pos, ARENA) {
			unordered_remove(&g.bullets, i)
		}
	}

	// --- Spawning: gets faster the longer you survive ---
	g.spawn_timer -= dt
	if g.spawn_timer <= 0 {
		append(&g.enemies, Enemy{pos = random_edge_point()})
		g.spawn_timer = max(SPAWN_MIN_INTERVAL, SPAWN_START_INTERVAL - g.time * SPAWN_RAMP)
	}

	// --- Enemies: chase the player; they also speed up over time ---
	enemy_speed := ENEMY_BASE_SPEED + g.time * ENEMY_SPEED_GROWTH
	for &e in g.enemies {
		e.pos += linalg.normalize0(g.player.pos - e.pos) * enemy_speed * dt
	}

	// --- Bullet vs enemy: both are destroyed, +1 score ---
	// Iterate backwards so unordered_remove doesn't skip elements.
	for ei := len(g.enemies) - 1; ei >= 0; ei -= 1 {
		for bi := len(g.bullets) - 1; bi >= 0; bi -= 1 {
			if rl.CheckCollisionCircles(g.enemies[ei].pos, ENEMY_RADIUS, g.bullets[bi].pos, BULLET_RADIUS) {
				unordered_remove(&g.bullets, bi)
				unordered_remove(&g.enemies, ei)
				g.score += 1
				break // this enemy is gone, move on to the next one
			}
		}
	}

	// --- Enemy vs player: lose 1 HP, then a short invulnerability window ---
	g.player.invuln_timer -= dt
	for ei := len(g.enemies) - 1; ei >= 0; ei -= 1 {
		if rl.CheckCollisionCircles(g.enemies[ei].pos, ENEMY_RADIUS, g.player.pos, PLAYER_RADIUS) {
			unordered_remove(&g.enemies, ei) // the enemy that hit you is consumed
			if g.player.invuln_timer <= 0 {
				g.player.hp -= 1
				g.player.invuln_timer = PLAYER_INVULN
			}
		}
	}

	if g.player.hp <= 0 {
		g.state = .Lost
	}
}

update :: proc(g: ^Game, dt: f32) {
	switch g.state {
	case .Title:
		if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
			reset(g)
			g.state = .Playing
		}
	case .Playing:
		update_playing(g, dt)
	case .Won, .Lost:
		if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.R) {
			reset(g)
			g.state = .Playing
		}
	}
}

// ---------------------------------------------------------------------------
// Draw
// ---------------------------------------------------------------------------

draw_centered_text :: proc(text: cstring, y: i32, size: i32, color: rl.Color) {
	w := rl.MeasureText(text, size)
	rl.DrawText(text, SCREEN_W / 2 - w / 2, y, size, color)
}

draw_world :: proc(g: ^Game) {
	rl.DrawRectangleLinesEx(ARENA, 2, rl.GRAY)

	for e in g.enemies {
		rl.DrawCircleV(e.pos, ENEMY_RADIUS, rl.RED)
	}
	for b in g.bullets {
		rl.DrawCircleV(b.pos, BULLET_RADIUS, rl.YELLOW)
	}

	// Blink the player while invulnerable (visible for half of every 0.2 s).
	blinking := g.player.invuln_timer > 0 && math.mod(g.player.invuln_timer, 0.2) < 0.1
	if !blinking {
		rl.DrawCircleV(g.player.pos, PLAYER_RADIUS, rl.SKYBLUE)
	}
}

draw_hud :: proc(g: ^Game) {
	rl.DrawText(fmt.ctprintf("HP: %d / %d", g.player.hp, PLAYER_MAX_HP), 40, 25, 30, rl.RAYWHITE)
	draw_centered_text(fmt.ctprintf("%.0f", max(0, ROUND_LENGTH - g.time)), 25, 30, rl.RAYWHITE)
	score_text := fmt.ctprintf("Score: %d", g.score)
	rl.DrawText(score_text, SCREEN_W - 40 - rl.MeasureText(score_text, 30), 25, 30, rl.RAYWHITE)
}

draw :: proc(g: ^Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground({20, 20, 28, 255})

	switch g.state {
	case .Title:
		draw_centered_text("ARENA", 220, 80, rl.RAYWHITE)
		draw_centered_text(fmt.ctprintf("Survive %.0f seconds", ROUND_LENGTH), 330, 30, rl.LIGHTGRAY)
		draw_centered_text("WASD to move  -  Mouse to aim  -  Hold left click to shoot", 380, 24, rl.LIGHTGRAY)
		draw_centered_text("Press ENTER to start", 460, 30, rl.YELLOW)
	case .Playing:
		draw_world(g)
		draw_hud(g)
	case .Won, .Lost:
		draw_world(g)
		draw_hud(g)
		rl.DrawRectangle(0, 0, SCREEN_W, SCREEN_H, rl.Fade(rl.BLACK, 0.6))
		title: cstring = g.state == .Won ? "YOU SURVIVED" : "YOU DIED"
		draw_centered_text(title, 250, 70, g.state == .Won ? rl.GREEN : rl.RED)
		draw_centered_text(fmt.ctprintf("Score: %d", g.score), 350, 36, rl.RAYWHITE)
		draw_centered_text("Press ENTER or R to play again", 420, 28, rl.YELLOW)
	}
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "ARENA")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	g: Game
	defer delete(g.bullets)
	defer delete(g.enemies)

	for !rl.WindowShouldClose() {
		// Cap dt so a stalled frame (e.g. dragging the window) doesn't teleport everything.
		dt := min(rl.GetFrameTime(), 1.0 / 30.0)
		update(&g, dt)
		draw(&g)
		free_all(context.temp_allocator) // ctprintf allocates HUD strings here each frame
	}
}
