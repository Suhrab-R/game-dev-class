# SQ1 — Mini Game Jam (ARENA + twist)

This folder (`Side_Quests/sq1/`) holds one course assignment: the CSCI 4160U
(Game Development) **Mini Game Jam**. The instructor's brief calls it "Side Quest
SQ2". It's the same assignment, just stored in the `sq1` folder.

**All the work happens in `mini-jam/`.** That folder is what gets graded and
submitted. Everything else in `sq1/` (this file, `tools/`) is personal workflow
support and is not part of the submission.

The repo root is `game-dev-class/` (one repo for the whole course; other folders
like `Encounters/` and `Lab1/` are unrelated class work, don't touch them).

Read `mini-jam/README.md`, `RUBRIC.md` and `IDEAS.md` if you need detail beyond
this summary. They are the source of truth; this file condenses them.

---

## Current status (keep this section up to date)

- **Last updated:** 2026-09-28, during session 1 (in progress, not logged yet)
- **Twist:** **LAN versus multiplayer.** In one sentence: *"ARENA, but two players
  on different computers share the arena over Wi-Fi, and the last one standing wins."*
  - Chosen in session 1 (Sep 28). Power-ups/sabotages between the players are the
    depth layer. **Done so far: the Sabotage power-up** (see *Rules*). More power-ups
    will follow (the user's plan; details not decided yet).
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
  LAN versus was added, then the Sabotage power-up and the enemies-off testing toggle. The menu offers `[1]` Solo (the original ARENA, 90 s),
  `[2]` Host, `[3]` Join (type the host's IP). It builds with `-vet`, and a loopback
  test (host and client in one process) passed 14/14 checks. **Not yet play-tested
  by the user on two real computers.**
- **jam-log.csv:** still contains only the instructor's **example row**
  (`1,2026-09-23,40,...,claude-sonnet-5,...`). Replace it when logging the first
  real session (see *Session end protocol*).
- **ATTRIBUTION.md:** the existing Code row for `src/main.odin` ("Build the base
  ARENA game...") is the **instructor's entry**. **Keep it as is**, never replace
  or delete it (the user's decision). It's also the format model for new rows. The
  Kenney row under "AI-generated assets" is an instructor example; leave it alone
  unless the user says otherwise.
- **POSTMORTEM.md:** not started. It's written near submission (~Oct 4), not
  during sessions. See the rules below.
- **Next milestone:** play-test versus on two computers for the **Mon Sep 28
  showcase**, then add power-ups/sabotages.

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
| `config.odin` | tuning constants (`SOLO_ROUND_LENGTH`, speeds, `MAX_ENEMIES` 300, `MAX_BULLETS` 128), `player_color(i)` |
| `types.odin` | `Mode` (Solo/Host/Client), `State`, `Outcome`, `Player` (has `sabotage_shots`), `Bullet` (has `owner`, `sabotage`), `Enemy`, `Power_Up_Kind`, `Power_Up`, `Player_Input`, `Game` |
| `input.odin` | `read_local_input()`: keyboard/mouse → `Player_Input` |
| `game.odin` | `update` (state switch) → `update_solo` / `update_host` / `update_client`; `advance_game` (play or restart) |
| `menu.odin` | title (1/2/3/ESC), join menu (IP typing), `start_solo/host/client`, `leave_to_title` |
| `round.odin` | `reset_round`, `update_round` (the ordered list of steps), `check_round_over`, `end_round` |
| `player.odin` | `update_player`, `move_player`, `try_shoot` (uses up sabotage shots first), `damage_player` (enemy hit, respects invuln), `sabotage_player` (also respects invuln; a blocked hit still uses the bullet) |
| `bullets.odin` | `update_bullets`, `handle_sabotage_hits` (runs before enemy hits), `handle_bullet_enemy_hits` (kills credited to `owner`), `bullet_radius` |
| `power_ups.odin` | `update_power_up_spawning` (versus only), `handle_power_up_pickups`, `apply_power_up` (switch on kind: **add new power-ups here**), `random_power_up_point` |
| `enemies.odin` | `update_spawning`, `update_enemies` (chase **nearest alive** player), `handle_enemy_player_hits`, `random_edge_point` |
| `network.odin` | UDP host/client, packets, `find_host_ips` |
| `draw.odin` | `draw` (state switch), world, power-ups (spinning magenta diamond "S"), players (labels, magenta ring while armed), menu screens, round-over overlay (versus shows kills only) |
| `hud.odin` | solo HUD (HP / time left / kills), versus HUD (per player: HP, kills, "Sabotage shots: N"), "ENEMIES OFF (N)" reminder |

**How networking works (host-authoritative, UDP, port 7777):**
- Only the host simulates. Every frame, the client sends an `Input_Packet` (its
  `Player_Input`) and the host sends back a `Snapshot_Packet` (state, outcome, the
  enemies-off flag, time, both players, enemy positions, whole `Bullet`s and
  `Power_Up`s as fixed arrays + counts, ~6.6 KB). **Any new state the client must
  draw has to be added to the snapshot** (`send_snapshot` + `apply_snapshot`).
- Structs are sent as raw bytes (`mem.ptr_to_bytes`), which works because both ends
  run the same build. Sockets are non-blocking. `receive_*` drains up to 64 packets a
  frame and keeps the newest, and a `PACKET_MAGIC` + kind + size check filters junk.
- The host takes the first valid sender as player 2 and ignores anyone else.
- Timeouts: 3 s of silence mid-game → back to the title with a message; 5 s with no
  reply while connecting → back to the join menu.
- `restart` in the input is *held* (R/Enter), not pressed, so one lost packet can't
  swallow it. Either player can restart from the round-over screen.

**Rules:** solo = survive 90 s (as in the starter). Versus = both players in one
arena, no time limit (the ramp keeps going), and enemies chase the nearest living
player. The round ends the moment a player dies: the survivor wins, and both dying on
the same frame is a draw. Players start 150 px either side of the centre.

**Sabotage power-up (versus only):** one on the field at a time, appearing 5 s after
the round starts or after the last pickup, at a random spot at least 60 px from the
walls. Touching it sets `sabotage_shots = 3` (refills, doesn't stack). Your next 3
bullets are sabotage bullets (magenta, radius 6):
- One that hits the **other** player takes 1 HP and starts the usual 1 s blink.
  **A hit during the blink does nothing, and the bullet is still used up** (user's
  choice). So spraying all 3 at once wastes 2 of them; you have to space your shots.
- One that hits an enemy kills it and is **used up**. That's the trade-off: waste them
  on enemies, or keep them for your opponent.
- Normal bullets and your own sabotage bullets pass through players.
A magenta ring around a player and "Sabotage shots: N" in the HUD show who's armed.

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

One row per **game code file** created or changed this session (files under
`mini-jam/src/`, build scripts, etc.; not logs, docs, the postmortem or this
file). Use the script's "files edited" list plus `git status` / `git diff`
(shell edits aren't in the script's list).

`| \`src/file.odin\` | claude-code, <model> | <prompt (short)> | <hand edits> |`

- **prompt (short)**: a one-sentence *summary* of what was asked for that file,
  in the style of the existing `src/main.odin` row. **Never paste the user's raw
  prompts.** They are long; condense them.
- If the file already has a row from an earlier session, add a new row for this
  session's changes (append `(session N)` to the prompt text so it's clear).
  Never modify or remove the instructor's existing `src/main.odin` row.
- **hand edits**: leave blank unless the user says they edited it by hand.
- Also add rows under the assets table for any new asset files not made by the user
  (source, author, licence, changes; or tool + prompt if AI-generated).

### 4. Wrap up

- Update **Current status** above (date, what works now, what's next) and add
  anything learned to *Postmortem evidence* / *Odin notes*.
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
