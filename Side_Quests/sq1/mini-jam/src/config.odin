package arena

// Every .odin file in the src/ folder belongs to the same package ("arena"), so
// they all see each other's declarations without any imports between them.

import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Tuning constants. In Odin, `NAME :: value` is a compile-time constant
// (like `const` / `#define`); `name := value` would declare a variable.
// ---------------------------------------------------------------------------

SCREEN_W :: 1280 // window size in pixels
SCREEN_H :: 720

// The playable area, inset from the window so the HUD has room at the top.
ARENA :: rl.Rectangle{40, 80, SCREEN_W - 80, SCREEN_H - 120}

SOLO_ROUND_LENGTH :: 90.0 // seconds to survive to win a solo round (versus has no time limit)

MAX_PLAYERS         :: 2
VERSUS_START_OFFSET :: 150.0 // pixels left/right of the centre where the two players start

PLAYER_RADIUS :: 14.0  // pixels
PLAYER_SPEED  :: 260.0 // pixels per second
PLAYER_MAX_HP :: 5
PLAYER_INVULN :: 1.0   // seconds of invulnerability after a hit
FIRE_COOLDOWN :: 0.15  // seconds between shots

BULLET_RADIUS :: 4.0   // pixels
BULLET_SPEED  :: 700.0 // pixels per second
MAX_BULLETS   :: 128   // cap so a whole game snapshot fits in one network packet

ENEMY_RADIUS         :: 12.0  // pixels
ENEMY_BASE_SPEED     :: 90.0  // pixels per second at the start of a round
ENEMY_SPEED_GROWTH   :: 1.2   // extra pixels per second, for every second of the round
SPAWN_START_INTERVAL :: 1.2   // seconds between spawns at the start of a round
SPAWN_MIN_INTERVAL   :: 0.25  // spawns never come faster than this
SPAWN_RAMP           :: 0.011 // seconds the spawn interval shrinks per second of the round
MAX_ENEMIES          :: 300   // cap so a whole game snapshot fits in one network packet

// Power-ups (versus only)
POWER_UP_RADIUS   :: 14.0 // pixels
POWER_UP_INTERVAL :: 5.0  // seconds after a pickup (or the round start) until the next one appears
POWER_UP_MARGIN   :: 60.0 // pixels: power-ups never appear closer than this to the arena walls
MAX_POWER_UPS     :: 1    // how many can be on the field at once

// Sabotage power-up: your next few bullets can hurt the other player.
SABOTAGE_SHOTS         :: 3   // bullets granted per pickup (a pickup refills to this, it doesn't stack)
SABOTAGE_DAMAGE        :: 1   // HP a sabotage bullet takes from the other player
SABOTAGE_BULLET_RADIUS :: 6.0 // pixels: a bit bigger than a normal bullet so it's easy to see

// Colour of each player: index 0 is the host (or the solo player), index 1 is the one who joined.
// (A proc rather than a constant array, because Odin doesn't allow indexing a
// constant array with a value only known at runtime.)
player_color :: proc(index: int) -> rl.Color {
	return index == 0 ? rl.SKYBLUE : rl.ORANGE
}
