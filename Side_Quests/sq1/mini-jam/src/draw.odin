package arena

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Drawing: the arena and everything in it, plus the menu screens.
// Nothing here changes the game state.
// ---------------------------------------------------------------------------

BACKGROUND :: rl.Color{20, 20, 28, 255}

// Each power-up's colour is reused for its bullets / the ring it puts around a
// player, so what you see on the field matches what it does.
SABOTAGE_COLOR      :: rl.MAGENTA
RAPID_FIRE_COLOR    :: rl.YELLOW
LASER_COLOR         :: rl.GREEN
RICOCHET_COLOR      :: rl.VIOLET
SHOTGUN_COLOR       :: rl.PINK
INVINCIBILITY_COLOR :: rl.GOLD
EXTRA_HP_COLOR      :: rl.RED
SHIELD_COLOR        :: rl.BLUE

draw :: proc(g: ^Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing() // runs at the end of this proc, after everything below is drawn
	rl.ClearBackground(BACKGROUND)

	switch g.state {
	case .Title:              draw_title_screen(g)
	case .Join_Menu:          draw_join_screen(g)
	case .Waiting_For_Player: draw_waiting_screen(g)
	case .Connecting:         draw_connecting_screen(g)
	case .Playing:
		draw_world(g)
		draw_hud(g)
	case .Round_Over:
		draw_world(g)
		draw_hud(g)
		draw_round_over(g)
	}
}

// ---------------------------------------------------------------------------
// The arena
// ---------------------------------------------------------------------------

draw_world :: proc(g: ^Game) {
	rl.DrawRectangleLinesEx(ARENA, 2, rl.GRAY)

	for pu in g.power_ups {
		draw_power_up(pu)
	}
	for e in g.enemies {
		rl.DrawCircleV(e.pos, ENEMY_RADIUS, rl.RED)
	}
	for b in g.bullets {
		draw_bullet(b)
	}
	for i in 0 ..< g.player_count {
		draw_player(g, i)
	}
}

// Lasers are drawn as beams; every other bullet as a dot coloured by its kind.
draw_bullet :: proc(b: Bullet) {
	switch b.kind {
	case .Laser:
		tip, tail := laser_segment(b)
		rl.DrawLineEx(tail, tip, LASER_WIDTH, LASER_COLOR)
		rl.DrawLineEx(tail, tip, LASER_WIDTH / 3, rl.RAYWHITE) // bright core, so it reads as a beam
	case .Sabotage:
		rl.DrawCircleV(b.pos, bullet_radius(b), SABOTAGE_COLOR)
	case .Ricochet:
		rl.DrawCircleV(b.pos, bullet_radius(b), RICOCHET_COLOR)
	case .Normal:
		rl.DrawCircleV(b.pos, bullet_radius(b), rl.YELLOW)
	}
}

// A slowly spinning diamond in the power-up's colour, with its letter on top.
draw_power_up :: proc(pu: Power_Up) {
	color, letter := power_up_look(pu.kind)
	spin := f32(rl.GetTime()) * 90 // degrees
	rl.DrawPoly(pu.pos, 4, POWER_UP_RADIUS, spin, color)
	w := rl.MeasureText(letter, 16)
	rl.DrawText(letter, i32(pu.pos.x) - w / 2, i32(pu.pos.y) - 8, 16, rl.BLACK)
}

// Colour and letter for each kind of power-up (the title screen lists what the letters mean).
power_up_look :: proc(kind: Power_Up_Kind) -> (color: rl.Color, letter: cstring) {
	switch kind {
	case .Sabotage:      return SABOTAGE_COLOR, "S"
	case .Rapid_Fire:    return RAPID_FIRE_COLOR, "R"
	case .Laser:         return LASER_COLOR, "L"
	case .Ricochet:      return RICOCHET_COLOR, "B"
	case .Shotgun:       return SHOTGUN_COLOR, "W"
	case .Invincibility: return INVINCIBILITY_COLOR, "I"
	case .Extra_HP:      return EXTRA_HP_COLOR, "+"
	case .Shield:        return SHIELD_COLOR, "O"
	}
	return rl.RAYWHITE, "?"
}

draw_player :: proc(g: ^Game, index: int) {
	p := g.players[index]
	if !p.alive {
		rl.DrawCircleV(p.pos, PLAYER_RADIUS, rl.DARKGRAY) // where they died
		return
	}

	// Blink while invulnerable: hidden for half of every 0.2 s.
	blinking := p.invuln_timer > 0 && math.mod(p.invuln_timer, 0.2) < 0.1
	if !blinking {
		rl.DrawCircleV(p.pos, PLAYER_RADIUS, player_color(index))
	}
	draw_player_effects(p)

	// In versus, label each player so you know which circle is yours.
	if g.player_count == 2 {
		label := index == g.local_player ? cstring("YOU") : fmt.ctprintf("P%d", index + 1)
		w := rl.MeasureText(label, 16)
		rl.DrawText(label, i32(p.pos.x) - w / 2, i32(p.pos.y - PLAYER_RADIUS) - 20, 16, player_color(index))
	}
}

// Rings around a player showing their active power-ups, so both players can see them:
//   weapon: a thin ring in the weapon's colour
//   shield: one blue ring per hit it will still absorb
//   invincibility: a thick gold halo
draw_player_effects :: proc(p: Player) {
	if p.weapon != .Normal {
		rl.DrawCircleLinesV(p.pos, PLAYER_RADIUS + 4, weapon_color(p.weapon))
	}
	for i in 0 ..< p.shield_hits {
		rl.DrawCircleLinesV(p.pos, PLAYER_RADIUS + 8 + f32(i) * 3, SHIELD_COLOR)
	}
	if p.invincible_timer > 0 {
		rl.DrawRing(p.pos, PLAYER_RADIUS + 15, PLAYER_RADIUS + 18, 0, 360, 32, INVINCIBILITY_COLOR)
	}
}

weapon_color :: proc(weapon: Weapon) -> rl.Color {
	switch weapon {
	case .Sabotage:   return SABOTAGE_COLOR
	case .Rapid_Fire: return RAPID_FIRE_COLOR
	case .Laser:      return LASER_COLOR
	case .Ricochet:   return RICOCHET_COLOR
	case .Shotgun:    return SHOTGUN_COLOR
	case .Normal:
	}
	return rl.RAYWHITE
}

// ---------------------------------------------------------------------------
// Screens
// ---------------------------------------------------------------------------

draw_title_screen :: proc(g: ^Game) {
	draw_centered_text("ARENA", 150, 80, rl.RAYWHITE)
	draw_centered_text("Outlast the swarm - or outlast your friend", 245, 26, rl.LIGHTGRAY)

	draw_centered_text(fmt.ctprintf("[1]  Solo  (survive %.0f seconds)", SOLO_ROUND_LENGTH), 320, 30, rl.YELLOW)
	draw_centered_text("[2]  Host a LAN versus game", 365, 30, rl.YELLOW)
	draw_centered_text("[3]  Join a LAN versus game", 410, 30, rl.YELLOW)

	draw_centered_text("WASD to move  -  Mouse to aim  -  Hold left click to shoot", 480, 22, rl.LIGHTGRAY)
	draw_centered_text("Versus: last player standing wins", 510, 22, rl.LIGHTGRAY)
	draw_centered_text("Power-ups:  S sabotage   R rapid fire   L laser   B bounce   W wide shot   I invincible   + HP   O shield", 545, 18, rl.LIGHTGRAY)
	draw_centered_text("ESC to quit", 580, 20, rl.GRAY)
	// TESTING ONLY (remove with the toggle).
	enemies_text := g.enemies_disabled ? cstring("[N] Enemies: OFF  (testing)") : cstring("[N] Enemies: ON  (testing)")
	draw_centered_text(enemies_text, 605, 18, rl.GRAY)
	draw_message(g)
}

draw_join_screen :: proc(g: ^Game) {
	draw_centered_text("JOIN A GAME", 150, 50, rl.RAYWHITE)
	draw_centered_text("Type the IP address shown on the host's screen:", 250, 26, rl.LIGHTGRAY)

	box := rl.Rectangle{SCREEN_W / 2 - 220, 300, 440, 60}
	rl.DrawRectangleLinesEx(box, 2, rl.YELLOW)
	cursor := math.mod(rl.GetTime(), 1.0) < 0.5 ? "_" : " " // blinking text cursor
	draw_centered_text(fmt.ctprintf("%s%s", typed_ip(g), cursor), 312, 36, rl.RAYWHITE)

	draw_centered_text("ENTER to connect  -  ESC to go back", 400, 24, rl.YELLOW)
	draw_centered_text("Both computers must be on the same Wi-Fi / network.", 450, 20, rl.GRAY)
	draw_centered_text("To test on one computer, host in one window and join 127.0.0.1 in another.", 478, 20, rl.GRAY)
	draw_message(g)
}

draw_waiting_screen :: proc(g: ^Game) {
	draw_centered_text("HOSTING", 130, 50, rl.RAYWHITE)
	draw_centered_text("Waiting for player 2 to join...", 200, 28, rl.LIGHTGRAY)
	draw_centered_text("On the other computer choose [3] Join and type one of:", 270, 24, rl.LIGHTGRAY)

	if g.net.host_ip_count == 0 {
		draw_centered_text("(could not find this computer's IP - run `ipconfig` to see it)", 320, 24, rl.ORANGE)
	}
	for i in 0 ..< g.net.host_ip_count {
		ip := g.net.host_ips[i]
		text := fmt.ctprintf("%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3])
		draw_centered_text(text, 315 + i32(i) * 50, 40, rl.YELLOW)
	}

	draw_centered_text("If there are several, use the Wi-Fi one (usually 192.168.x.x or 10.x.x.x).", 540, 20, rl.GRAY)
	draw_centered_text("ESC to cancel", 600, 22, rl.GRAY)
}

draw_connecting_screen :: proc(g: ^Game) {
	draw_centered_text(fmt.ctprintf("Connecting to %s ...", typed_ip(g)), 300, 32, rl.RAYWHITE)
	draw_centered_text("ESC to cancel", 380, 22, rl.GRAY)
}

// The dark overlay with the result, shown on top of the frozen arena.
draw_round_over :: proc(g: ^Game) {
	rl.DrawRectangle(0, 0, SCREEN_W, SCREEN_H, rl.Fade(rl.BLACK, 0.6))

	title, color := round_over_title(g)
	draw_centered_text(title, 220, 70, color)

	if g.player_count == 1 {
		draw_centered_text(fmt.ctprintf("Kills: %d", g.players[0].kills), 320, 36, rl.RAYWHITE)
	} else {
		// Only kills: both players always last the same time, since the round ends when one dies.
		for i in 0 ..< g.player_count {
			text := fmt.ctprintf("P%d  -  %d kills", i + 1, g.players[i].kills)
			draw_centered_text(text, 310 + i32(i) * 40, 30, player_color(i))
		}
	}
	draw_centered_text("Press R or ENTER to play again  -  ESC for the menu", 430, 26, rl.YELLOW)
}

// The big headline for the round-over screen, from this window's player's point of view.
round_over_title :: proc(g: ^Game) -> (text: cstring, color: rl.Color) {
	switch g.outcome {
	case .Survived: return "YOU SURVIVED", rl.GREEN
	case .Died:     return "YOU DIED", rl.RED
	case .Draw:     return "DRAW", rl.YELLOW
	case .Player1_Wins, .Player2_Wins:
		winner := g.outcome == .Player1_Wins ? 0 : 1
		if winner == g.local_player do return "YOU WIN", rl.GREEN
		return "YOU LOSE", rl.RED
	case .None:
	}
	return "", rl.RAYWHITE
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

draw_centered_text :: proc(text: cstring, y: i32, size: i32, color: rl.Color) {
	w := rl.MeasureText(text, size)
	rl.DrawText(text, SCREEN_W / 2 - w / 2, y, size, color)
}

// Shows g.message (errors, "host disconnected", ...) near the bottom of a menu screen.
draw_message :: proc(g: ^Game) {
	if g.message != nil {
		draw_centered_text(g.message, 640, 22, rl.ORANGE)
	}
}
