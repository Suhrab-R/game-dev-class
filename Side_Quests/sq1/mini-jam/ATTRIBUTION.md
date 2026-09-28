# Attribution

Every asset you did not make. Delete the example row.

## AI-generated assets
| asset (file) | source (URL) | author | licence | changes you made |
|---|---|---|---|---|
| `assets/player.png` | https://kenney.nl/assets/tiny-dungeon | Kenney | CC0 | cropped from sheet |

## Code

| asset (file) | tool + model | prompt (short) | hand edits |
|---|---|---|---|
| `src/main.odin` | claude-code, claude-opus-5-5 | Build the base ARENA game per README.md: top-down survival shooter, WASD movement, mouse-aimed shooting, enemies spawning from edges and chasing the player, HP/damage/invulnerability, difficulty ramp over time, title/win/lose states with restart | |
| `main.odin`, `config.odin`, `types.odin`, `input.odin`, `game.odin`, `menu.odin`, `round.odin`, `player.odin`, `bullets.odin`, `enemies.odin`, `network.odin`, `draw.odin`, `hud.odin` | claude-code, claude-opus-5-5 | Change the twist to local multiplayer over Wi-Fi: the second player who joins has the same controls, and it's a versus survival where each player tries to outlast the other. Multiplayer first; power-ups and sabotages later (session 1) | |
| `main.odin`, `config.odin`, `types.odin`, `game.odin`, `menu.odin`, `round.odin`, `player.odin`, `bullets.odin`, `power_ups.odin`, `network.odin`, `draw.odin`, `hud.odin` | claude-code, claude-opus-5-5 | Remove the "player lasted" part from the end screen and keep only kills; add a temporary toggle to turn enemies off for testing power-ups; add a sabotage power-up whose next 3 bullets take 1 HP from the other player, wasted if used on enemies (session 1) | |
| `player.odin` | claude-code, claude-opus-5-5 | Make sabotage hits during the blink do nothing (session 1) | |
| `config.odin`, `types.odin`, `round.odin`, `player.odin`, `bullets.odin`, `enemies.odin`, `power_ups.odin`, `draw.odin`, `hud.odin` | claude-code, claude-opus-5-5 | Add power-ups: rare 10 s invincibility, 10 s rapid fire, 10 s piercing lasers that end at the wall, 10 s ricochet bullets (lifetime 3 or 5 s, your choice), +1 HP, a 2-hit shield, and a 10 s 3-pellet shotgun. Shooting power-ups cancel each other; shield, HP and invincibility can stack. Max 3 on the map at random intervals, odds your choice (session 1) | |
| `config.odin`, `round.odin`, `power_ups.odin` | claude-code, claude-opus-5-5 | Make power-ups spawn every 6 s and last 5 s; set laser to 15% and invincibility to 7% (session 1) | |
| `config.odin` | claude-code, claude-opus-5-5 | Make solo rounds 2.5 minutes instead of 1.5, and in both modes make enemies start faster and speed up quicker (session 1) | |
| `config.odin`, `enemies.odin` | claude-code, claude-opus-5-5 | Cap enemy speed (session 1) | |


Any code copied or adapted from somewhere other than an LLM (tutorials,
examples, templates), with the link.
