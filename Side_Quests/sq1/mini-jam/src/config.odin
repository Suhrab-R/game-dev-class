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

// Seconds to survive to win a solo round (2.5 minutes). Versus has no time limit.
SOLO_ROUND_LENGTH :: 150.0

MAX_PLAYERS         :: 2
VERSUS_START_OFFSET :: 150.0 // pixels left/right of the centre where the two players start

PLAYER_RADIUS :: 14.0  // pixels
PLAYER_SPEED  :: 260.0 // pixels per second
PLAYER_MAX_HP :: 5
PLAYER_INVULN :: 1.0   // seconds of invulnerability after a hit
FIRE_COOLDOWN :: 0.15  // seconds between shots

BULLET_RADIUS :: 4.0   // pixels
BULLET_SPEED  :: 700.0 // pixels per second
MAX_BULLETS   :: 256   // cap so a whole game snapshot fits in one network packet

ENEMY_RADIUS         :: 12.0  // pixels
ENEMY_BASE_SPEED     :: 120.0 // pixels per second at the start of a round
ENEMY_SPEED_GROWTH   :: 1.6   // extra pixels per second, for every second of the round
ENEMY_MAX_SPEED      :: 250.0 // speed stops growing here (reached at ~81 s: 120 + 1.6 * 81 = 250).
                              // Just under PLAYER_SPEED, so you can always (barely) outrun them.
SPAWN_START_INTERVAL :: 1.2   // seconds between spawns at the start of a round
SPAWN_MIN_INTERVAL   :: 0.25  // spawns never come faster than this
SPAWN_RAMP           :: 0.011 // seconds the spawn interval shrinks per second of the round
MAX_ENEMIES          :: 300   // cap so a whole game snapshot fits in one network packet

// Power-ups: spawning (how likely each kind is: see power_up_weight in power_ups.odin)
POWER_UP_RADIUS       :: 14.0 // pixels
POWER_UP_INTERVAL     :: 6.0  // seconds between power-up spawns (while there's room on the field)
POWER_UP_MARGIN       :: 60.0 // pixels: power-ups never appear closer than this to the arena walls
MAX_POWER_UPS         :: 3    // how many can be on the field at once

// Weapon power-ups (only one weapon at a time: a new one replaces the old one)
WEAPON_DURATION :: 5.0 // seconds that rapid fire, laser, ricochet and shotgun last

SABOTAGE_SHOTS         :: 3   // sabotage lasts this many bullets instead of a time
SABOTAGE_DAMAGE        :: 1   // HP a sabotage bullet takes from the other player
SABOTAGE_BULLET_RADIUS :: 6.0 // pixels: a bit bigger than a normal bullet so it's easy to see

RAPID_FIRE_COOLDOWN :: 0.05 // seconds between shots (normal is FIRE_COOLDOWN, 0.15)

LASER_COOLDOWN :: 0.3    // seconds between shots: slower, since each laser pierces everything
LASER_SPEED    :: 1400.0 // pixels per second
LASER_LENGTH   :: 60.0   // pixels: how long the beam segment is drawn and collides
LASER_WIDTH    :: 4.0    // pixels

RICOCHET_LIFETIME      :: 3.0 // seconds a bouncing bullet lives if it hasn't hit an enemy
RICOCHET_BULLET_RADIUS :: 5.0 // pixels

SHOTGUN_COOLDOWN :: 0.35 // seconds between blasts
SHOTGUN_PELLETS  :: 3    // bullets per blast
SHOTGUN_SPREAD   :: 0.2  // radians (~11 degrees) between neighbouring pellets

// Defensive power-ups (these stack with everything)
INVINCIBILITY_DURATION :: 5.0  // seconds of taking no damage at all
SHIELD_HITS            :: 2    // hits the shield absorbs (a pickup refills to this, it doesn't stack)
BONUS_HP_CAP           :: 8    // +1 HP pickups can take you above PLAYER_MAX_HP, but not past this

// Colour of each player: index 0 is the host (or the solo player), index 1 is the one who joined.
// (A proc rather than a constant array, because Odin doesn't allow indexing a
// constant array with a value only known at runtime.)
player_color :: proc(index: int) -> rl.Color {
	return index == 0 ? rl.SKYBLUE : rl.ORANGE
}
