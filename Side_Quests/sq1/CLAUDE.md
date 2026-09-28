# SQ1 — Mini Game Jam (ARENA + twist)

This folder (`Side_Quests/sq1/`) holds one course assignment: the CSCI 4160U
(Game Development) **Mini Game Jam**. The instructor's brief calls it "Side Quest
SQ2". It's the same assignment, just stored in the `sq1` folder.

**All the work happens in `mini-jam/`.** That folder is what gets graded and
submitted. Everything else in `sq1/` (this file, `tools/`, `CODE_GUIDE.md`) is
personal workflow support and is not part of the submission.

`sq1/CODE_GUIDE.md` is the user's study guide for explaining the code in
spot-checks: reading order, Odin cheat sheet, explanations of the key procs and
math, design decisions, experiments, and practice questions. **When a change makes
it wrong** (a renamed proc, a new mechanic, changed numbers like timings or odds),
update the matching section in the same turn.

The repo root is `game-dev-class/` (one repo for the whole course; other folders
like `Encounters/` and `Lab1/` are unrelated class work, don't touch them).

Read `mini-jam/README.md`, `RUBRIC.md` and `IDEAS.md` if you need detail beyond
this summary. They are the source of truth; this file condenses them.

---

## Current status (keep this section up to date)

- **Last updated:** 2026-09-28, end of session 1 (logged). The next "session start" …
  "session end" pair is **session 2**.
- **Twist:** **LAN versus multiplayer.** In one sentence: *"ARENA, but two players
  on different computers share the arena over Wi-Fi, and the last one standing wins."*
  - Chosen in session 1 (Sep 28). Power-ups between the players are the depth layer.
    **8 power-ups are in** (see *Power-ups* under *Rules*): Sabotage, Rapid Fire,
    Laser, Ricochet, Shotgun (weapons, which replace each other), and Invincibility,
    +1 HP, Shield (defensive, which stack).
  - **Temporary testing toggle:** `N` turns enemies off/on (`g.enemies_disabled`,
    everything marked `TESTING ONLY`). The user wants it **removed later**, so it's on
    the submission checklist.
  - Pitch history for the postmortem's "pitch vs. delivered": no pitch was set on
    Sep 23. A placeholder ("health is ammo") was written on Sep 27 and dropped on
    Sep 28 in favour of LAN versus.
  - Depth note for A3: versus alone isn't yet "choices with trade-offs" (it's still
    circle and shoot, just side by side). The planned sabotages/power-ups are where
    the depth has to come from. Keep steering them toward real trade-offs.
- **Game state (session 1):** the starter was split into files (see *Code layout*),
  LAN versus was added, then the power-ups and the enemies-off testing toggle. The
  menu offers `[1]` Solo (the original ARENA, now 150 s, now with power-ups except
  Sabotage), `[2]` Host, `[3]` Join (type the host's IP). It builds with `-vet`, and
  the test harness passes (0 failures). **Not yet play-tested by the user on two real
  computers.**
- **jam-log.csv:** the instructor's example row has been replaced. Row 1 = session 1
  (2026-09-28, 76 min, 7 prompts, ccusage). `llm_helpfulness` and `notes` are left
  blank for the user to fill in. Append new sessions below it.
- **ATTRIBUTION.md:** the existing Code row for `src/main.odin` ("Build the base
  ARENA game...") is the **instructor's entry**. **Keep it as is**, never replace
  or delete it (the user's decision). It's also the format model for new rows.
  Session 1 added 7 rows (one per prompt, with its files comma-separated, tagged
  "(session 1)"). The
  Kenney row under "AI-generated assets" is an instructor example; leave it alone
  unless the user says otherwise.
- **POSTMORTEM.md:** not started. It's written near submission (~Oct 4), not
  during sessions. See the rules below.
- **Next milestone:** play-test versus + power-ups on two computers for the **Mon
  Sep 28 showcase**, then tune from showcase feedback.

---

## Deadlines

| When | What |
|---|---|
| Wed Sep 23 | ARENA presented, twist pitched on Canvas (one sentence), build starts |
| Thu Sep 24 – Sun Sep 27 | Build. Aim for **something playable** by Monday |
| **Mon Sep 28** | **Showcase**: classmates play the game as it stands (required for A4) |
| Mon Sep 28 – Sun Oct 4 | Keep improving using showcase feedback |
| **Sun Oct 4, 23:59** | **Due:** game tagged `jam-final`, `POSTMORTEM.md`, `jam-log.csv`, all pushed |

Late: −10% of the assignment per day or part-day, up to 72 h, judged by push time.

## Rules

1. Solo. 2. **Odin + Raylib (`vendor:raylib`), 2D.** 3. Any tool allowed
(LLMs included). 4. **Log every working session** in `jam-log.csv`.
5. **The user must be able to explain every line submitted.** Spot-checks happen in
class. 6. Art optional; any asset not made by the user must be credited in
`ATTRIBUTION.md`. 7. **Keep it playable.** Small and working beats ambitious and broken.

## Grading (5 pts), what to optimise for

- **A1 Complete game (1.0):** start, play, reach an end (win/lose), **replay
  without relaunching**, no crash or blocking bug in 3 minutes of play.
- **A2 Distance from ARENA (1.0):** *substantial* changes: new, changed or removed
  **mechanics**, not just added content, and they must work.
- **A3 Depth and creativity (1.0):** real decisions with **trade-offs**, more than
  one viable strategy, room for skill; summable in one sentence ("ARENA, but ...").
  Juice/art/sound alone scores 0. An IDEAS.md idea taken unchanged scores 0.5;
  combining or bending ideas scores higher.
- **A4 Shipping (0.5):** builds from a clean clone with **one command written in
  the README**; ATTRIBUTION complete; shown at the Sep 28 showcase.
- **B1 Data (0.5):** one `jam-log.csv` row per session, every column filled;
  POSTMORTEM front matter consistent with the log totals.
- **B2 Analysis (1.0):** postmortem in the user's own words, with specifics. It needs:
  where the LLM sped things up, where it didn't, **one LLM-introduced bug found,
  fixed and verified with evidence**, pitch vs delivered, pipeline improvements.

Never graded: which tool or model, token counts, how much code the LLM wrote.

The three depth questions to test any design idea against: **the decision** (what
does the player choose?), **the trade-off** (what does each option cost?),
**the mastery** (what does an expert do differently?).

---

## Stack, build, run

- Odin at `C:\odin\dist\odin.exe` (on PATH), version `dev-2026-09-nightly`.
- Run from `mini-jam/`:
  - `odin run src`: build and launch
  - `odin build src -out:arena.exe`: build only (`*.exe` is gitignored)
  - `odin check src`: type-check without building
- **After every code change, at minimum run `odin build src` (or `odin check src`)
  and fix all errors before reporting done.** Say whether it was actually run.
- The exact Raylib API as Odin sees it: `<odin root>/vendor/raylib/raylib.odin`
  (`odin root` prints the path; here `C:\odin\dist\`). **Check a proc's real
  name and signature there before using it.** Don't guess from C names or memory.
  The instructor's example log mentions an LLM inventing `rl.GetDeltaTime`; the
  real one is `rl.GetFrameTime`.
- Docs: odin-lang.org/docs/overview, pkg.odin-lang.org/vendor/raylib,
  raylib.com/cheatsheet (C names; Odin drops the prefix and uses `rl.`).

### Code layout (update as it grows)

`mini-jam/src/`, all one package `arena`:

| file | what's in it |
|---|---|
| `main.odin` | window + game loop only; ESC is not the exit key (`SetExitKey(.KEY_NULL)`) |
| `config.odin` | tuning constants (`SOLO_ROUND_LENGTH`, speeds, `MAX_ENEMIES` 300, `MAX_BULLETS` 256, power-up timings/odds constants), `player_color(i)` |
| `types.odin` | `Mode`, `State`, `Outcome`, `Weapon`, `Player` (weapon + timers, `sabotage_shots`, `invincible_timer`, `shield_hits`), `Bullet_Kind`, `Bullet` (`owner`, `kind`, `life`), `Enemy`, `Power_Up_Kind`, `Power_Up`, `Player_Input`, `Game` |
| `input.odin` | `read_local_input()`: keyboard/mouse → `Player_Input` |
| `game.odin` | `update` (state switch) → `update_solo` / `update_host` / `update_client`; `advance_game` (play or restart) |
| `menu.odin` | title (1/2/3/ESC), join menu (IP typing), `start_solo/host/client`, `leave_to_title` |
| `round.odin` | `reset_round`, `update_round` (the ordered list of steps), `check_round_over`, `end_round` |
| `player.odin` | `update_player`, `update_player_timers` (weapon/invincibility expiry), `move_player`, `try_shoot` (switch on weapon), `fire_bullet`, `hit_player` (the one damage path: invincible → blink → shield → HP) |
| `bullets.odin` | `update_bullets` (+ `bounce_off_walls` for ricochet), `handle_sabotage_hits` (runs before enemy hits), `handle_bullet_enemy_hits` (lasers don't get used up), `bullet_hits_circle`, `laser_segment`, `bullet_radius` |
| `power_ups.odin` | `power_up_weight` (spawn odds), `update_power_up_spawning`, `random_power_up_kind` (weighted), `handle_power_up_pickups`, `apply_power_up` (**add new power-ups here**), `equip_weapon` |
| `enemies.odin` | `update_spawning`, `update_enemies` (chase **nearest alive** player), `handle_enemy_player_hits`, `random_edge_point` |
| `network.odin` | UDP host/client, packets, `find_host_ips` |
| `draw.odin` | `draw` (state switch), world, `draw_bullet` (laser = line), `draw_power_up` + `power_up_look` (colour + letter), `draw_player_effects` (rings), power-up colour constants, menu screens (title has the power-up legend), round-over overlay (versus shows kills only) |
| `hud.odin` | solo HUD, versus HUD, `effects_text` (active power-ups line), "ENEMIES OFF (N)" reminder |

**How networking works (host-authoritative, UDP, port 7777):**
- Only the host simulates. Every frame, the client sends an `Input_Packet` (its
  `Player_Input`) and the host sends back a `Snapshot_Packet` (state, outcome, the
  enemies-off flag, time, both players, enemy positions, whole `Bullet`s and
  `Power_Up`s as fixed arrays + counts; ~10.8 KB since `MAX_BULLETS` went to 256
for rapid fire and the shotgun). **Any new state the client must
  draw has to be added to the snapshot** (`send_snapshot` + `apply_snapshot`).
- Structs are sent as raw bytes (`mem.ptr_to_bytes`), which works because both ends
  run the same build. Sockets are non-blocking. `receive_*` drains up to 64 packets a
  frame and keeps the newest, and a `PACKET_MAGIC` + kind + size check filters junk.
- The host takes the first valid sender as player 2 and ignores anyone else.
- Timeouts: 3 s of silence mid-game → back to the title with a message; 5 s with no
  reply while connecting → back to the join menu.
- `restart` in the input is *held* (R/Enter), not pressed, so one lost packet can't
  swallow it. Either player can restart from the round-over screen.

**Rules:** solo = survive **150 s** (the starter had 90; the user raised it). Enemy
speed = 120 + 1.6 px/s per second of the round (starter: 90 + 1.2; the user asked
for a faster start and ramp), **capped at 250 px/s** (`ENEMY_MAX_SPEED`, reached at
~81 s), just under the player's 260 so they can always be outrun. After the cap, the
difficulty keeps rising only through the spawn rate (floor 0.25 s). Versus = both players in one
arena, no time limit (the ramp keeps going), and enemies chase the nearest living
player. The round ends the moment a player dies: the survivor wins, and both dying on
the same frame is a draw. Players start 150 px either side of the centre.

**Power-ups (spawning):** up to **3** on the field at once. One spawns every **6 s**
(`POWER_UP_INTERVAL`), and the timer only runs while there's room. They spawn at a random
spot at least 60 px from the walls, in solo too (except Sabotage). Kind is a weighted
roll (`power_up_weight` in `power_ups.odin`, weights add up to 100 so they're
versus percentages): Sabotage 16, **Laser 15**, Rapid Fire 13, Shotgun 13, Ricochet 12,
Shield 12, +HP 12, **Invincibility 7 (rare)**. Laser 15% and invincibility 7% were set
by the user, and the others were scaled down to keep the total at 100. Drawn as a
spinning diamond in the power-up's colour with a letter: **S**abotage (magenta),
**R**apid (yellow), **L**aser (green), **B**ounce/ricochet (violet), **W**ide/shotgun
(pink), **I**nvincible (gold), **+** HP (red), **O** shield (blue). The title screen
has the legend.

**Weapons: one at a time.** Picking up any weapon replaces the current one, including
leftover sabotage shots (`equip_weapon`). The user's rule is "power-ups that change
shooting cancel each other", and Claude counted Sabotage as one of them. Timed weapons
last **5 s** (`WEAPON_DURATION`; the user cut it from 10).
- **Sabotage** (counted in shots, not time): the next 3 bullets are magenta, radius 6.
  A hit on the **other** player is a `hit_player(p, 1)`, so a hit during the blink does
  nothing, but the bullet is still used up (user's choice). Spraying all 3 wastes 2.
  Hitting an enemy kills it and uses the shot up (the trade-off). Then back to Normal.
- **Rapid Fire:** cooldown 0.05 s (normal 0.15), normal bullets.
- **Laser:** 1400 px/s beam, 60 px long (a line segment, `CheckCollisionCircleLine`),
  **pierces every enemy**, disappears when its tip leaves the arena. Cooldown 0.3 s.
- **Ricochet:** bullets bounce off walls (`bounce_off_walls` mirrors position and
  flips velocity) and live **3 s** (Claude's pick of the user's 3 or 5), or until
  they hit an enemy.
- **Shotgun:** 3 pellets per shot at −0.2 / 0 / +0.2 rad (`rl.Vector2Rotate`),
  cooldown 0.35 s.

**Defensive: stack with everything.** Each refills rather than stacks.
- **Invincibility:** 5 s with no damage from anything (enemies/sabotage bullets that
  touch you are still used up). Gold halo.
- **+1 HP:** can go above 5, capped at 8 (`BONUS_HP_CAP`).
- **Shield:** absorbs 2 hits. Blue rings, one per hit left. An absorbed hit still starts
  the blink, and a hit during the blink doesn't use a shield charge.

`hit_player` order: invincible → ignore; blinking → ignore; shield → absorb (−1
charge, start blink); else −HP (start blink). Normal/laser/ricochet/own-sabotage
bullets never hurt players. Rings around players show weapon (thin, weapon colour),
shield and invincibility. The HUD line under each player's stats shows e.g.
"Laser 7s   Shield 2   Invincible 4s".

**Controls:** WASD/arrows move, mouse aim, hold LMB to shoot, R/Enter restart, ESC =
back to menu (quit on the title screen), N = enemies on/off (testing only; the host's
setting is the one that counts).

**Testing versus on one PC:** `odin build src -out:arena.exe`, then run `arena.exe`
twice. Host in one window, join `127.0.0.1` in the other (only the focused window gets
keyboard input). On two PCs, both must be on the same network, and Windows Firewall
must allow `arena.exe` (the prompt appears the first time you host). School/public
Wi-Fi often blocks device-to-device traffic, so a phone hotspot is the fallback.
There's a loopback test harness pattern: copy `src/*.odin` minus `main.odin` into a
scratch folder with a test `main` that drives two `Game`s (host and client), with
`IP4_Any` swapped for `IP4_Loopback` so there's no firewall prompt.

Keep this layout description current whenever files or major procs are added.

---

## Code style: readable by a programmer who doesn't know Odin

The user isn't an Odin expert and must be able to explain every line. The target
reader is **someone who can program (C, Java, Python...) but has never seen Odin**.
They should be able to open any file and understand what each proc and line does.

**Structure**
- **Small, single-purpose procs** with descriptive names, e.g. `update_player_movement`,
  `spawn_enemy`, `handle_bullet_enemy_collisions`, `draw_hud`. If a proc does
  several things or grows past ~40 lines, split it. `update_playing` should read like a
  list of steps that each call a helper.
- **Split into files by responsibility once `main.odin` gets crowded** (adding the
  twist is a good moment). Suggested layout, all `package arena` in `src/`:
  `main.odin` (window + game loop only), `config.odin` (tuning constants),
  `types.odin` (structs/enums), `player.odin`, `enemies.odin`, `bullets.odin`,
  one file per twist mechanic, `collision.odin`, `draw.odin`, `hud.odin`. Split
  only along real seams, and don't create near-empty files.
  - Odin fact worth knowing: every `.odin` file in the same folder is **one
    package**. They share everything automatically, with no imports between them, and
    the build command stays `odin build src`.
- Refactoring the instructor's starter into this structure is fine (it's our game
  now). Do it as its own step, compile, and check it still plays the same
  *before* adding new mechanics on top.
- **Keep all game state in the `Game` struct**, passed as `g: ^Game`. No global
  mutable variables. Constants (`::`) at file scope are fine.
- **No magic numbers.** Every tuning value is a named constant in the config
  section/file, with a comment giving its unit (seconds, pixels/sec, HP...).

**Odin conventions** (follow them so the code looks idiomatic):
- `snake_case` for procs and variables, `Ada_Case` for types (`Enemy_Kind`),
  `SCREAMING_SNAKE` for constants, enum values in `Ada_Case` (`.Playing`).
- Tabs for indentation (as in the starter). Use `rl.` for Raylib and
  `linalg.` for vector math.
- Prefer plain, obvious features: structs, enums, `switch`, `[dynamic]` arrays,
  `for` loops. **Avoid** `using`, parametric polymorphism (`$T`), `#soa`, operator
  tricks, and `or_return` chains unless there's a clear win. If one is used, comment it.
- Every `[dynamic]` array gets a matching `delete` (use `defer delete(...)` next to
  where it's created), same as the starter.

**Comments**
- A short comment above every proc saying **what it does and why** (not a
  restatement of the name).
- Explain **Odin-specific syntax** the first time it shows up in each file, in
  plain terms for a non-Odin reader. For example:
  - `x :: 5` is a compile-time constant; `x := 5` declares a variable
  - `^Game` is a pointer; `&g` takes an address
  - `for &e in g.enemies` loops by reference so `e` can be modified
  - `defer` runs at scope exit
  - `do` is a one-line body
  - `.Playing` is an enum value with the type inferred
- Comment the *game logic reasoning*: why a check exists, what a formula means
  ("spawn interval shrinks 0.011 s per second survived, floored at 0.25 s").
- Don't comment the obvious (`i += 1 // increment i`).

---

## How to work with the user

- **Explainability matters for the grade.** Follow *Code style* above. After a
  change, briefly explain what changed and why. Don't pull in clever abstractions
  the user can't defend in a spot-check.
- **Keep the game playable at all times.** Build the smallest version of a
  feature first, compile, then extend.
- **Depth over complexity.** When suggesting features, check them against the
  three depth questions. Prefer one rule that changes decisions over more content.
- **Keep facts for the postmortem.** When a bug caused by the LLM is found and
  fixed, or a feature was notably easy or hard, add a one-line entry to
  *Postmortem evidence* below (what, session number, how it was verified). The
  user writes the postmortem in their own words; you only keep the facts.
- **POSTMORTEM.md comes later.** It's written near submission (~Oct 4), so don't
  touch it during normal sessions. When the time comes, help by pulling up the
  *Postmortem evidence* list, commits and log totals, and fill front-matter numbers
  from `jam-log.csv` if asked. **Don't write its prose**; it must be the user's own voice.
- **Don't commit or push unless asked.** Before submission, remind the user to
  tag `jam-final` and push.

---

## Session markers: "session start" / "session end"

The user marks each jam session with two one-line prompts, in any letter case:

- **`session start`**: a session begins. Just acknowledge it in one or two lines
  (current status and next step from this file). Don't log anything.
- **`session end`**: the session is over. Run the protocol below.

These two prompts are the **only** triggers. Never log a session, edit
`jam-log.csv`, or edit `ATTRIBUTION.md` at any other time. Anything outside a
start/end pair (like this CLAUDE.md setup) is not jam work. Per the README, a
break of more than 30 minutes also ends a session.

## Session end protocol

### 1. Gather the numbers

Run (works from any directory; reads only this machine's transcripts):

```sh
python Side_Quests/sq1/tools/jam_session_stats.py --prompts
```

It takes the window from the latest "session start" to the "session end" (across
all Claude chats in this repo on this machine; neither marker counts as a prompt)
and prints: date, active minutes, model(s), tokens_in / tokens_out (ccusage,
cache included), prompt count, files Claude edited, and each prompt's text.

- If it prints `BREAK` lines (gaps > 30 min), ask the user whether to split into
  two rows (rerun with `--since/--until` for each part).
- If it warns there was no "session start", it falls back to the first prompt
  after the previous "session end". Check with the user that the window is right.
- Setup work before 2026-09-27 21:56 UTC is never counted (`JAM_START` in the script).
- If part of the session happened on another device or in another tool, the
  script can't see it. Ask for those numbers only if the user mentions it;
  otherwise assume one device, claude-code only.

### 2. Append one row to `mini-jam/jam-log.csv`

Columns: `session,date,minutes,tool,model,tokens_in,tokens_out,tokens_source,prompts,features,llm_helpfulness,notes`

- `session`: next number (1, 2, 3...). **The first real row replaces the
  instructor's example row.**
- `date` (`YYYY-MM-DD`), `minutes`, `model`, `tokens_in`, `tokens_out`,
  `prompts`: from the script. `tool` = `claude-code` (semicolon-separate if
  several). `tokens_source` = what the script printed (e.g. `ccusage incl. cache`).
- `features`: short semicolon-separated names of what was worked on, e.g.
  `ricochet;hud;bugfix-spawn`.
- **`llm_helpfulness` and `notes`: leave EMPTY.** The user fills these in themselves.
  The row ends with `,,`.
- Quote any field containing a comma.

### 3. Update `mini-jam/ATTRIBUTION.md` → `## Code` table

**One row per user prompt that led to editing game code**, listing every file that
prompt edited, comma-separated, without the `src/` prefix. The prompt
column is a summary of **the user's actual prompt**: the last prompt they sent
before the edit. It is **not** a description of what the code does (the user
corrected this after session 1, when Claude first wrote code descriptions).

How:
1. Run the script with `--prompts`. Under each prompt it prints `-> edited: ...`, the
   files Claude edited between that prompt and the next.
2. Keep only game code files (`mini-jam/src/*.odin`, build scripts). Skip
   `CLAUDE.md`, logs, docs, the postmortem and scratch test files.
3. For each prompt, add **one row**: its edited game files, comma-separated, in
   the first column (e.g. `` `config.odin`, `enemies.odin` ``), then the summary.
4. Shell edits (`sed`, python) aren't in the script's list. If one touched a
   `src/` file after a prompt, add that file under that prompt too.

`| \`a.odin\`, \`b.odin\` | claude-code, <model> | <summary of the user's prompt> (session N) | <hand edits> |`

- **Summary:** condense the prompt to 1–2 sentences in the user's terms (what they
  asked for), in the style of the existing `src/main.odin` row. **Never paste the raw
  prompt.** Keep every request it contained, and don't add details the user didn't
  ask for.
- Rows go in prompt order. Append `(session N)` to each summary. Never modify or
  remove the instructor's existing `src/main.odin` row.
- **hand edits**: leave blank unless the user says they edited it by hand.
- Also add rows under the assets table for any new asset files not made by the user
  (source, author, licence, changes; or tool + prompt if AI-generated).

### 4. Wrap up

- Update **Current status** above (date, what works now, what's next) and add
  anything learned to *Postmortem evidence* / *Odin notes*.
- Check `CODE_GUIDE.md` still matches the code (numbers, proc names, new mechanics).
- Show the user the new CSV row and ATTRIBUTION rows. Offer to commit and push,
  since that's how the laptop gets the latest state.

---

## Postmortem evidence (facts only; the user writes the prose)

Format: `S<n> · feature/bug · what happened · how verified`

- S1 · refactor + LAN versus · starter split into 13 files; UDP host/client written
  in one pass after reading `core/net` sources for the real API · verified with
  `odin build -vet` and a loopback test harness (14/14 checks: join, input → host,
  snapshot → client, positions match, intruder ignored, P1 dies → P2 wins, P2 restarts).
- S1 · **LLM bug (compile-time)** · Claude wrote `PLAYER_COLORS :: [2]rl.Color{...}`
  and indexed it with a runtime index; Odin refused: "Cannot index a constant
  'PLAYER_COLORS'". Fixed with `player_color(index)`, a proc · verified: build passes.
- S1 · **LLM bug (logic, caught by test)** · the host screen listed every IPv4
  address, and the first one shown was `192.168.56.1` (VirtualBox virtual adapter),
  not the Wi-Fi address `192.168.2.22`, so player 2 would have typed the wrong IP.
  Fix: list only adapters that have a gateway, falling back to all · verified:
  the test harness printed `host IPs found: 1 [[192, 168, 2, 22]]` after the fix
  (it printed both addresses before).
- S1 · versus polish · the round-over screen dropped "P lasted X s" (always equal for
  both, since the round ends on the first death); it now shows kills only. The unused
  `Player.time_survived` field was removed.
- S1 · Sabotage power-up + enemies-off toggle · verified with the test harness:
  25/25 checks (spawn timing, solo has none, pickup + refill, 3 rapid hits = exactly
  −3 HP, normal bullets pass through, own sabotage is harmless, sabotage wasted on an
  enemy, sabotage kill → win, toggle clears/stops/resumes enemies, snapshot carries
  sabotage shots, bullets and power-ups to the client).
- S1 · sabotage vs blink · Claude first made sabotage hits ignore invulnerability
  (so rapid fire = −3 HP). The user chose the opposite: hits during the blink do
  nothing, and the bullet is used up. Changed `sabotage_player` to check `invuln_timer`
  · verified: the harness now shows rapid fire → −1 HP with the other 2 bullets used
  up, and 3 hits spaced past the blink → −3 HP.
- S1 · 7 more power-ups (Invincibility, Rapid Fire, Laser, Ricochet, +1 HP, Shield,
  Shotgun), up to 3 on the field, random 3–7 s spawns, weighted odds · verified:
  44/44 harness checks (odds measured over 20k rolls, invincibility 3.9%; weapons
  replace each other and defensive ones stack; 10 s expiry; the laser killed 3 enemies
  in a line and was gone at the wall; ricochet stayed inside through corner bounces
  and died at 3 s; shield absorbed exactly 2; invincibility blocked enemies and
  sabotage; network carries weapons, bullet kinds and power-up kinds).
- S1 · tuning (user's call) · power-up spawns went from random 3–7 s to a fixed 6 s,
  timed power-ups from 10 s to 5 s, laser to 15% and invincibility to 7% · verified:
  harness 0 failures (first spawn at 6 s and the next 6 s later, 5 s expiry, odds over
  20k rolls: laser 15.5%, invincibility 7.3%).
- S1 · tuning (user's call) · solo round 90 s → 150 s; enemy base speed 90 → 120 px/s,
  growth 1.2 → 1.6 px/s per second (they now outrun the player after ~88 s,
  previously ~142 s) · verified: build passes; not play-tested yet.
- S1 · enemy speed cap (user's call, after Claude pointed out solo's last minute
  would have enemies faster than the player) · `ENEMY_MAX_SPEED` 250 · verified by a
  speed probe: 120 px/s at 0 s, 184 at 40 s, 250 at 81 s, and still 250 at 150 s and 300 s.
  Test-side bug worth knowing: the first fire-rate check measured shots as the frame's
  change in bullet count, so bullets leaving at the wall cancelled new shots. Rapid
  fire read 17 vs normal 18 (a false FAIL). Counting and clearing each frame gave the
  true 60 vs 18.

- S1 · process mistake (session logging) · at the first "session end" Claude filled
  ATTRIBUTION's "prompt (short)" column with its own descriptions of each file,
  not summaries of the user's actual prompts. The user caught it. Fixed by
  mapping every edit to the preceding prompt from the transcript (7 prompts), then
  merged into one row per prompt with its files comma-separated, at the user's
  request. `jam_session_stats.py --prompts` now prints the files edited under each
  prompt so this can't drift again.

## Odin / Raylib notes (gotchas found while working)

- Delta time is `rl.GetFrameTime()` (there is no `GetDeltaTime`).
- Remove from `[dynamic]` arrays while iterating **backwards** when using
  `unordered_remove` (existing code does this).
- `fmt.ctprintf` allocates on `context.temp_allocator`, which is freed once per frame in `main`.
- A constant array (`X :: [2]T{...}`) **can't be indexed with a runtime value**.
  Use a proc or a variable instead.
- `core:net`: `make_bound_udp_socket(net.IP4_Any, port)` for the host,
  `make_unbound_udp_socket(.IP4)` for the client, `set_blocking(sock, false)`, and
  `recv_udp` returns `.Would_Block` when there's nothing to read. Winsock is initialised
  automatically. On Windows a UDP `recv` can report `.Connection_Refused` because of an
  earlier send to a closed port; it isn't fatal, so skip it.
- `net.Endpoint` values can be compared with `==` on their fields (the `Address`
  union compares fine).
- `odin run src` names the exe after the folder (`src.exe`). Use `-out:arena.exe`
  for a stable name, which also keeps the Windows Firewall rule stable.

## Submission checklist (before Oct 4, 23:59)

- [ ] A one-command build instruction in the README (e.g. `odin run src` from
      `mini-jam/`). The current `mini-jam/README.md` is the instructor's brief,
      so add a short "How to build and play" section at its top, or ask the user where.
- [ ] Game complete: title → play → win/lose → replay, no crashes (3-min test).
- [ ] **Remove the enemies-off testing toggle** (search `TESTING ONLY` / `enemies_disabled`
      across `src/`: `types.odin`, `game.odin`, `round.odin`, `network.odin`,
      `draw.odin`, `hud.odin`). Ask the user first; they said "later".
- [ ] `jam-log.csv`: example row gone, one row per session, all columns filled
      (user fills helpfulness and notes).
- [ ] `ATTRIBUTION.md`: code rows complete for every session (the instructor's
      `main.odin` row stays); ask the user about the Kenney example row if no assets were used.
- [ ] `POSTMORTEM.md`: front matter totals match `jam-log.csv` (sessions,
      minutes, prompts, tokens); `agent_instructions_file: yes` (this CLAUDE.md).
- [ ] Optional: transcripts in `mini-jam/transcripts/` (check for personal info first).
- [ ] `git tag jam-final` on the final commit, then push the commit **and** the tag
      (`git push && git push origin jam-final`).
