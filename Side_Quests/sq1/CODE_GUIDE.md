# ARENA Versus: Code Guide

A guide to reading and **explaining** the mini-jam code (`mini-jam/src/`). The
rubric says you must be able to explain any line you submit, so this focuses on
the parts that the code and its comments can't fully explain on their own: *why*
things are done a certain way, the math, and the ideas that span several files.

Small, obvious procs (a getter, a draw call) aren't covered; their comments are
enough.

---

## Part 1: How to read the code

### Reading order

Read in the order the game actually runs: vocabulary first, then one frame of
gameplay, then networking, then visuals.

| # | File | Why at this point | Time |
|---|---|---|---|
| 1 | `main.odin` | The whole program in ~30 lines: open a window, loop `update` → `draw`. The header lists every file. | 5 min |
| 2 | `types.odin` | **Read carefully.** Every other file just manipulates these structs. | 15 min |
| 3 | `config.odin` | Skim. It's named numbers; come back when a proc uses one. | 5 min |
| 4 | `game.odin` | What happens each frame, and how solo / host / client differ. | 15 min |
| 5 | `input.odin` | Tiny: keys + mouse → `Player_Input`. | 2 min |
| 6 | `round.odin` | `update_round` is **the map of the gameplay**: every step, in order. | 10 min |
| 7 | `player.odin` | Movement, shooting per weapon, and `hit_player` (all damage). | 20 min |
| 8 | `enemies.odin` | Spawning, chasing, speed ramp. | 10 min |
| 9 | `bullets.odin` | Bullet movement, ricochet, lasers, sabotage hits. | 20 min |
| 10 | `power_ups.odin` | Spawn odds, pickups, weapons replacing each other. | 15 min |
| 11 | `network.odin` | The multiplayer. Hardest file, but mostly packing data into two packet types. | 30 min |
| 12 | `menu.odin` | How the title screen starts or leaves a game. | 10 min |
| 13 | `draw.odin`, `hud.odin` | Everything visual. They only *read* the game state. | 20 min |

### How to study it

1. **Trace one frame by hand.** Open `main.odin`, follow `update(&g, dt)` →
   `update_host` → `advance_game` → `update_round`, then open every proc
   `update_round` calls, in order. After one pass you know how everything connects.
2. **Say it out loud.** For each proc, try to explain in one sentence what it does
   and why it exists. If you can't, re-read the matching section in Part 3.
3. **Break things on purpose.** Change a constant in `config.odin`, run the game
   and predict the result first (ideas in Part 5). Predicting correctly is the
   best proof you understand a value.
4. **Use the practice questions** in Part 6 as a self-test before class.

To run: from `mini-jam/`, `odin run src`. To test versus on one PC:
`odin build src -out:arena.exe`, run `arena.exe` twice, host in one window and
join `127.0.0.1` in the other.

---

## Part 2: Odin syntax cheat sheet

Everything you'll meet in this code, with the closest equivalent in C/Java/Python.

| Odin | Meaning |
|---|---|
| `package arena` | Every `.odin` file in `src/` is part of one package. They see each other's procs and types **without imports**. |
| `X :: 5` | Compile-time **constant** (like `const` / `#define`). |
| `x := 5` | Declare a **variable**, type inferred. `x: int` declares it with type and zero value. |
| `foo :: proc(a: int) -> bool { ... }` | A function ("procedure"). |
| `-> (pos: rl.Vector2, found: bool)` | Multiple **named return values**. A bare `return` returns them as they are. |
| `^Game` | **Pointer** to a `Game`. `&g` takes an address. `p^` is the value it points to. Field access auto-dereferences: `p.hp` works on a pointer. |
| `[dynamic]Bullet` | Growable array (`std::vector` / `ArrayList`). `append(&arr, x)`, `clear(&arr)`, `len(arr)`, `delete(arr)` frees it. |
| `[MAX_PLAYERS]Player` | Fixed-size array. |
| `[Power_Up_Kind]int` | Array **indexed by an enum** (used in the tests). |
| `for i in 0 ..< n` | `for (i = 0; i < n; i++)`. |
| `for e in arr` / `for &e in arr` | Loop over items by copy / **by reference** (so `e.pos += ...` changes the array). |
| `for kind in Power_Up_Kind` | Loop over every value of an enum. |
| `if cond do stmt` | One-line `if` (no braces). |
| `cond ? a : b` | Ternary, same as C. |
| `.Playing` | Enum value; Odin infers which enum from context (`g.state = .Playing`). |
| `switch x { case .A: ... case: ... }` | No fall-through. A `switch` on an enum must list **every** value (so some have an empty `case .None:`). `case:` is the default. |
| `defer f()` | Run `f()` when the current scope ends (cleanup next to creation). |
| `x.(T)` | "Is this **union** value a `T`?" Returns `(value, ok)`. Used on IP addresses. |
| `u8(ch)`, `f32(i)`, `i32(x)` | Type conversion (cast). |
| `rl.Something` | Raylib, imported as `rl`. Odin drops C's prefix and `rl.` replaces it. |
| `linalg.normalize0(v)` | Vector of length 1 in the same direction, or `{0,0}` for a zero vector. |
| `fmt.ctprintf(...)` | `sprintf` that returns a C string, allocated on the **temp allocator** (freed every frame by `free_all(context.temp_allocator)` in `main`). |
| `rl.Vector2` | Just `[2]f32`. You can do `a + b`, `v * 3.0`, `v.x`. |

---

## Part 3: The important parts, explained

### 3.1 The game loop and `dt` (`main.odin`)

```odin
for !rl.WindowShouldClose() && !g.quit {
    dt := min(rl.GetFrameTime(), 1.0 / 30.0)
    update(&g, dt)
    draw(&g)
    free_all(context.temp_allocator)
}
```

- **`dt` (delta time)** is the seconds since the last frame (~0.0167 at 60 FPS).
  Everything that moves is multiplied by `dt` (`pos += vel * dt`), so speeds are
  in **pixels per second** and the game runs at the same speed on fast and slow
  computers.
- **The `min(..., 1/30)` cap:** if the window freezes (dragged, or a lag spike),
  the next `dt` could be 0.5 s, and everything would teleport through walls. Capping
  at 1/30 s means a stall just slows the game down for a moment instead.
- **Update then draw:** `update` changes the state, and `draw` only reads it. They
  never mix, which is why `draw.odin` can't cause gameplay bugs.
- **`SetExitKey(.KEY_NULL)`:** Raylib closes the window on ESC by default. We
  disable that so ESC means "back to the menu".
- **The `defer delete(...)` lines** free the dynamic arrays when `main` ends, and
  `defer close_network` closes the socket.

### 3.2 Game state: `Game`, `Mode`, `State` (`types.odin`)

All state lives in **one `Game` struct**, passed as `g: ^Game` (a pointer, so procs
can modify it). There are no global variables. Two enums drive everything:

- **`Mode`** is *who this window is*: `Solo`, `Host` (runs the game) or `Client`
  (just displays the host's game).
- **`State`** is *which screen*: `Title` → `Join_Menu` / `Waiting_For_Player` /
  `Connecting` → `Playing` ⇄ `Round_Over`.

Together they form a **state machine**. `update` and `draw` both begin with
`switch g.state`, so each screen has its own update and draw code.

Also worth knowing:

- `Player_Input` is **everything a player's controls said this frame**. It exists
  so the simulation never reads the keyboard directly, and the host can treat
  player 2's input (from the network) exactly like its own.
- `local_player` is which player *this window* controls (0 for the host/solo, 1 for
  the client). It's only used for drawing: "YOU" labels and "YOU WIN" vs "YOU LOSE".

### 3.3 One frame, per mode (`game.odin`)

```
update ─┬─ Title / Join_Menu ──► menu.odin
        └─ in a game ──┬─ Solo   : read input ─────────────────────────► advance_game
                       ├─ Host   : receive P2 input, read own input ──► advance_game ► send_snapshot
                       └─ Client : send own input, receive snapshot (no simulation at all)
```

- **`advance_game`** is shared by solo and host: when `Playing` it runs
  `update_round`, and when `Round_Over` it waits for *any* player's `restart` to
  start a new round. That's how the client can restart too: its `restart` flag
  arrives inside its input.
- **`update_host`:** the first input packet from player 2 makes
  `receive_inputs` return `true`, and that starts the first round. After that, if
  no packet arrives for `NET_TIMEOUT` (3 s), player 2 is assumed gone.
- **`update_client`** never simulates. It sends input and applies snapshots. The
  timeout is 5 s while connecting (`CONNECT_TIMEOUT`), then 3 s. `last_heard`
  starts at the moment you pressed Enter, so the 5 s counts from then.

### 3.4 One round: `update_round` (`round.odin`)

```odin
g.time += dt
for each player: update_player      // timers, move, shoot
update_bullets                      // move / bounce / remove bullets
update_spawning (if enemies on)     // maybe add an enemy
update_power_up_spawning            // maybe add a power-up
update_enemies                      // chase nearest player
handle_sabotage_hits                // sabotage bullets vs players
handle_bullet_enemy_hits            // bullets vs enemies
handle_enemy_player_hits            // enemies vs players
handle_power_up_pickups             // players vs power-ups
check_round_over
```

**Why the order matters (a good spot-check question):**

- Things **move first, then collisions are checked**, so collisions use this
  frame's positions.
- **`handle_sabotage_hits` runs before `handle_bullet_enemy_hits`**, so a sabotage
  bullet touching both an enemy and the other player on the same frame hits the
  player (the more interesting outcome).
- **`check_round_over` is last**, so a player killed this frame ends the round this
  frame.

**`check_round_over`:** solo ends on death (`Died`) or after `SOLO_ROUND_LENGTH`
(150 s, `Survived`). Versus has **no timer**: the first death ends it (the
survivor wins, or it's a `Draw` if both die on the same frame).

**`reset_round`** clears everything and puts the players at the centre, 150 px
apart in versus (`VERSUS_START_OFFSET`).

### 3.5 Removing from arrays while looping (used everywhere)

```odin
for i := len(g.bullets) - 1; i >= 0; i -= 1 {
    ...
    unordered_remove(&g.bullets, i)
}
```

`unordered_remove` is fast because it **moves the last element into the removed
slot** instead of shifting everything down. If you looped *forwards*, the element
moved into slot `i` would be skipped, since you'd move on to `i+1`. Looping
**backwards** is safe, because the moved element comes from a slot you've
already visited. The same pattern appears in bullets, enemies and power-ups.

The nested collision loops `break` after a removal, because that enemy/bullet no
longer exists and checking it further would read a different element.

### 3.6 Players (`player.odin`)

**`move_player`:**
```odin
p.pos += linalg.normalize0(input.move) * PLAYER_SPEED * dt
p.pos.x = clamp(p.pos.x, ARENA.x + PLAYER_RADIUS, ARENA.x + ARENA.width - PLAYER_RADIUS)
```
- `input.move` is like `{1, 1}` when pressing D+S. Its length is √2 ≈ 1.41, so
  without `normalize0` **diagonal movement would be 41% faster**. Normalizing makes
  every direction length 1.
- `clamp` keeps the *edge* of the circle inside the arena, not just its centre,
  which is why the radius is added and subtracted.

**`try_shoot`:**
- `fire_cooldown` counts down every frame. You can shoot only when it's ≤ 0, and
  each shot resets it to the weapon's cooldown. **The cooldown is the fire rate**:
  0.15 s ≈ 6.7 shots/s normally, 0.05 s = 20 shots/s with rapid fire.
- `dir := normalize0(aim - p.pos)` is the direction from the player to the mouse.
- The `switch p.weapon` picks what to fire and which cooldown to set.
- **Shotgun spread math:**
  ```odin
  middle := f32(SHOTGUN_PELLETS - 1) / 2          // 3 pellets → middle = 1
  angle := (f32(i) - middle) * SHOTGUN_SPREAD     // i = 0,1,2 → -0.2, 0, +0.2 rad
  rl.Vector2Rotate(dir, angle)
  ```
  This centres the fan on the aim direction for **any** pellet count (5 pellets
  gives −0.4, −0.2, 0, 0.2, 0.4). Angles are in **radians** (0.2 rad ≈ 11°).
- **Sabotage** is the one weapon counted in shots, not time: each shot does
  `sabotage_shots -= 1`, and at 0 you're back to `.Normal`.

**`update_player_timers`:** counts down the blink (`invuln_timer`), invincibility,
and the weapon timer. Timed weapons turn back into `.Normal` at 0. Sabotage is
skipped here because it isn't timed.

**`hit_player`: the single place damage happens.** Both enemy touches and
sabotage bullets call it, so every rule is applied the same way:
```odin
if p.invincible_timer > 0 || p.invuln_timer > 0 do return  // 1. immune → nothing
p.invuln_timer = PLAYER_INVULN                              // 2. start the 1 s blink
if p.shield_hits > 0 { p.shield_hits -= 1; return }         // 3. shield absorbs it
p.hp -= damage                                              // 4. otherwise lose HP
if p.hp <= 0 do p.alive = false
```
- **`invuln_timer` vs `invincible_timer`:** the first is the short **blink** after
  any hit (1 s, so one crowd of enemies can't take all your HP in one frame). The
  second is the **Invincibility power-up** (5 s).
- A shield-absorbed hit still starts the blink. Otherwise two enemies touching you
  on the same frame would use both shield charges at once.

### 3.7 Enemies (`enemies.odin`)

**Difficulty formulas (all tunable in `config.odin`):**
```
enemy speed    = min(120 + 1.6 × time, 250)          px/s   (hits the cap at ~81 s)
spawn interval = max(0.25, 1.2 − 0.011 × time)       s      (hits the floor at ~86 s)
```
The speed cap (250) is just under the player's speed (260), so you can always
*barely* outrun them. After ~86 s, both formulas have hit their limits, so the
difficulty stops rising and the arena fills up at a steady 4 enemies per second.

**`nearest_alive_player`:** each enemy chases the closest living player. It compares
**squared** distances (`linalg.length2`): if a² < b² then a < b, so the square root
isn't needed just to compare. `best` starts at `max(f32)` (the largest float), so
the first living player always wins the first comparison. If nobody is alive,
`found` is false and the enemy stands still.

**`random_edge_point`:** picks one of 4 edges (`rand.int_max(4)`) and a random
position `t` from 0 to 1 along it.

### 3.8 Bullets (`bullets.odin`)

**Ricochet bounce (`bounce_off_walls`):**
```odin
if b.pos.x < left {
    b.pos.x = left + (left - b.pos.x)   // mirror the overshoot back inside
    b.vel.x = -b.vel.x                  // reverse horizontal direction
}
```
In one frame a bullet can go *past* the wall, say 5 px beyond it. We put it 5 px
*inside* instead (a mirror image) and flip that axis of its velocity, like a ball
off a wall. X and Y are checked separately, so a corner hit flips both. Ricochet
bullets also count down `life` and disappear at 0 (3 s).

**Laser collision:** a laser is drawn and collides as a **line segment**, not a dot:
```odin
laser_segment: tip = b.pos,  tail = b.pos − normalize(vel) × 60
rl.CheckCollisionCircleLine(enemy_center, enemy_radius, tail, tip)
```
Why a segment? The laser moves 1400 px/s, about 23 px per frame, which is almost
the width of an enemy (24 px). A small dot could **jump over** an enemy between two
frames ("tunnelling"). A 60 px segment always overlaps the path it just travelled.
The laser also **isn't removed** when it hits (`if b.kind != .Laser do
unordered_remove`), which is what makes it pierce.

**`handle_sabotage_hits`:** only `.Sabotage` bullets, only against players who
aren't the owner (`i == b.owner` is skipped), via `hit_player`. The bullet is used
up **even if the hit was blocked** by the blink, shield or invincibility. That's the
rule that makes spamming all 3 sabotage shots a waste.

**Kills** are credited with `g.players[b.owner].kills += 1`, which is why every
bullet stores its `owner`.

### 3.9 Power-ups (`power_ups.odin`)

**Two families:**
- **Weapons** (Sabotage, Rapid Fire, Laser, Ricochet, Shotgun) set `p.weapon`
  through `equip_weapon`. There's one `weapon` field, so a new weapon
  **automatically replaces** the old one, and `equip_weapon` also zeroes leftover
  sabotage shots. That's the "shooting power-ups cancel each other" rule.
- **Defensive** (Invincibility, +1 HP, Shield) change *other* fields
  (`invincible_timer`, `hp`, `shield_hits`), so they stack with any weapon and with
  each other.

**Weighted random choice (`random_power_up_kind`)**, like spinning a wheel where
each kind's slice is as big as its weight:
```odin
total := sum of weights                // 100 in versus
roll := rand.int_max(total)            // 0..99
for kind in Power_Up_Kind {
    roll -= power_up_weight(kind)
    if roll < 0 do return kind         // the roll landed in this kind's slice
}
```
Example: weights Sabotage 16, Laser 15, … A roll of 20 goes 20 − 16 = 4 (still ≥ 0,
so not Sabotage), then 4 − 15 = −11 < 0, so it's a **Laser**. Rolls 0–15 give
Sabotage, 16–30 give Laser, and so on. In solo, `can_spawn` removes Sabotage from
both loops, so the total becomes 84 and the others get slightly more likely.

**Spawn timer:** `power_up_timer` counts down only while fewer than 3 power-ups
are on the field, then spawns one and resets to 6 s. A full field doesn't queue up
spawns.

### 3.10 Networking (`network.odin`): the most important part to understand

**The model: host-authoritative.** Only the host runs the game. Each frame:

```
Client ── Input_Packet (my keys + mouse, 28 bytes) ──────────► Host
Client ◄── Snapshot_Packet (whole visible game, ~11 KB) ─────── Host
```

**Why this design?**
- If both computers simulated, their random numbers and timing would slowly
  **drift apart** (different enemies, different results). With one simulation,
  there's one truth.
- The client code becomes trivial: send input, draw whatever arrives.
- The cost is that the client sees its own movement after a network round trip
  (a few ms on a LAN, so you don't notice).

**Why UDP?** UDP sends individual packets with no delivery guarantee. That's fine,
because a new snapshot comes 1/60 s later anyway and we only ever want the
*newest* state. TCP would re-send lost old data and delay the new data behind it.

**Key details:**

| Detail | Explanation |
|---|---|
| `make_bound_udp_socket(IP4_Any, 7777)` | The host listens on port 7777 on all network adapters. |
| `make_unbound_udp_socket(.IP4)` | The client doesn't need a fixed port. The OS picks one on the first send, and the host learns it from `from` in `recv_udp`. |
| `set_blocking(socket, false)` | A normal socket `recv` **waits** until data arrives, which would freeze the game. Non-blocking returns immediately with `.Would_Block` when there's nothing to read. |
| `mem.ptr_to_bytes(&packet)` | Treats the struct's memory as a byte array. We send the struct's raw bytes, which works because both computers run the **same program**, so the struct layout is identical. |
| Fixed arrays + counts in `Snapshot_Packet` | A packet can't contain a `[dynamic]` array (that's a pointer to memory on the host). So we copy up to `MAX_ENEMIES` positions into a fixed array and send how many are valid. |
| `for _ in 0 ..< MAX_PACKETS_PER_FRAME` | Read **every** packet that arrived since last frame (up to 64 as a safety limit) and keep the newest. Otherwise packets would pile up and the game would lag further behind. |
| `PACKET_MAGIC` + kind + size check | Ignore anything that isn't one of our packets (other programs, corrupted data). |
| `if err != .None do continue` | Windows reports "your earlier packet hit a closed port" as a receive error on UDP. It's harmless, so we skip it instead of giving up. |
| First sender becomes `peer` | The host doesn't know player 2's address in advance. The first valid packet's `from` becomes the peer, and packets from anyone else are ignored (2 players max). |
| `last_heard` + timeouts | UDP has no "connection closed" event, so silence **is** the disconnect signal. |
| `restart` is *held*, not *pressed* | A key "pressed" is true for exactly one frame, and if that one packet is lost the press is lost. "Held" is sent in many packets. |
| `find_host_ips` | Lists this PC's IPv4 addresses for the waiting screen, **only from adapters with a gateway** (a router), so virtual adapters like VirtualBox are hidden. Skips 127.x (loopback) and 169.254.x (no DHCP). |
| `apply_snapshot` | The client overwrites its `Game` with the snapshot. The normal draw code then draws it, so no special client drawing exists. |

**Anything new the client must see has to be added to the snapshot**:
`send_snapshot` copies it in, and `apply_snapshot` copies it out.

### 3.11 Menus (`menu.odin`)

- **IP typing:** `rl.GetCharPressed()` returns typed characters one at a time
  (0 when there are none left), so the `for ch := ...; ch != 0; ch = ...` loop reads
  all of this frame's keystrokes. Only digits and `.` are accepted. `ip_text` is a
  fixed 32-byte buffer and `ip_len` is how much is used, and `typed_ip` turns it
  into a string with the slice `ip_text[:ip_len]`.
- **`IsKeyPressedRepeat(.BACKSPACE)`** makes holding backspace keep deleting.
- **`leave_to_title`** always closes the socket, which is how leaving (or a timeout)
  frees port 7777 for hosting again.

### 3.12 Drawing (`draw.odin`, `hud.odin`)

- **Blink:** `math.mod(p.invuln_timer, 0.2) < 0.1` hides the player for the first
  half of every 0.2 s while `invuln_timer > 0`, so it flashes 5 times a second.
- **Draw order = layer order:** power-ups, then enemies, then bullets, then players.
  Things drawn later appear on top.
- **Rings** show power-ups on each player (weapon colour, one blue ring per
  shield hit, a gold ring for invincibility), so **both** players can see what
  the other has. That's information for decisions (for example "they have sabotage,
  keep moving").
- **`power_up_look`** maps each kind to a colour and letter, and the same colour is
  reused for its bullets and rings.
- **`effects_text`** builds the "Laser 4s   Shield 2" line. `seconds_left` rounds
  **up** (`math.ceil`) so 0.3 s shows as 1, not 0.
- The HUD uses `fmt.ctprintf`, which allocates new text every frame on the temp
  allocator. That's why `main` calls `free_all(context.temp_allocator)` each frame;
  otherwise memory would grow forever.

### 3.13 Temporary testing code

Everything marked **`TESTING ONLY`** (the N key, `enemies_disabled`, the title and
HUD reminders) exists only so power-ups can be tested without enemies. It's
planned to be removed before submission. If asked, that's the honest answer.

---

## Part 4: Design decisions to be able to defend

| Decision | Why |
|---|---|
| Host-authoritative | One simulation means no drift between the two screens, and a trivially simple client. |
| UDP, not TCP | Only the newest state matters; lost packets are replaced 1/60 s later. |
| Solo mode kept | The game still works on one computer (the rubric needs a complete game), and power-ups can be tested alone. |
| Versus has no timer | "Last one standing" needs someone to die. The ramping difficulty guarantees it eventually. |
| Blink after every hit | Stops a crowd from draining all HP in one frame, and shows you were hit. |
| Sabotage used up even when blocked | Makes timing matter: spraying all 3 at once wastes 2. |
| Weapons replace each other | Picking up a weapon is a **choice**: grab the laser and lose your remaining sabotage shots? |
| Invincibility rare (7%) | It's the strongest pickup, so it should feel like luck. |
| Enemy speed capped under player speed | Solo lasts 150 s; uncapped enemies would be unescapable for the last minute. |
| Many small procs and files | Each proc does one thing, so each can be explained in one sentence. |

**Where the depth is (rubric A3):** power-ups create decisions with trade-offs.
Race your opponent to a power-up or stay safe? Spend sabotage shots on the enemy
in your way or save them for the other player? Swap your laser for the rapid fire
next to you? An expert tracks what the opponent is holding (the rings) and times
sabotage shots around the blink.

---

## Part 5: Experiments to check your understanding

Predict the result first, then change the value in `config.odin`, run, and check.
Undo afterwards.

| Change | What should happen |
|---|---|
| `SHOTGUN_PELLETS :: 7` | A 7-pellet fan, still centred on the mouse (the `middle` math). |
| `ENEMY_MAX_SPEED :: 400.0` | Late in the round enemies outrun you. |
| `PLAYER_INVULN :: 0.0` | A group of enemies can take all your HP at once, and there's no blink. |
| `MAX_POWER_UPS :: 10`, `POWER_UP_INTERVAL :: 1.0` | The arena fills with power-ups. |
| `RICOCHET_LIFETIME :: 10.0` | Bouncing bullets pile up. |
| `LASER_LENGTH :: 5.0` | Lasers look like dots and sometimes pass through enemies without killing them (tunnelling, §3.8). |
| In `move_player`, remove `linalg.normalize0(...)` | Diagonal movement becomes ~41% faster. |
| In `update_bullets`, loop forwards instead of backwards | Occasionally a bullet skips a frame of movement or removal (§3.5). |

---

## Part 6: Practice spot-check questions

Try to answer out loud before reading the answer.

1. **What happens when you press N?** It toggles `enemies_disabled`, clearing
   enemies and stopping spawns. It's testing-only, and only the host's value
   matters, because the client's is overwritten by each snapshot.
2. **Why is everything multiplied by `dt`?** So speeds are per second and the game
   runs the same regardless of frame rate.
3. **Does the client run the game?** No. It sends its input and draws the host's
   snapshots (`update_client` has no simulation).
4. **How does the host know where player 2 is?** The `from` address of the first
   valid input packet becomes `net.peer`.
5. **Why loop backwards when removing bullets?** `unordered_remove` moves the last
   element into the gap, and a forwards loop would skip it.
6. **Why does the laser use a line segment?** It moves ~23 px per frame, so a dot
   could jump over an enemy. The segment covers the path.
7. **What's the difference between `invuln_timer` and `invincible_timer`?** The 1 s
   blink after any hit, vs the 5 s Invincibility power-up.
8. **What happens if you pick up Laser while you have 2 sabotage shots?**
   `equip_weapon` sets the weapon to Laser and zeroes `sabotage_shots`.
9. **Why not TCP?** TCP re-sends lost packets and delays newer data behind them.
   We only care about the newest state.
10. **Why is the client's restart key "held" instead of "pressed"?** A press lasts
    one frame; if that packet is lost the press is lost.
11. **How is the power-up kind chosen?** A weighted roll: subtract each weight from
    a random number until it goes below 0.
12. **What does `hit_player` check, in order?** Invincible or blinking → nothing;
    start the blink; shield → use a charge; else lose HP (and die at 0).
13. **Why does `find_host_ips` require a gateway?** To show the real Wi-Fi address,
    not virtual adapters like VirtualBox.
14. **What is `mem.ptr_to_bytes` doing?** Viewing a struct's memory as bytes, so
    it can be sent in a packet as-is. That's safe because both ends run the same program.
15. **Why does a sabotage bullet check players before enemies?** So if it touches
    both on the same frame, the player hit wins.
16. **When does a versus round end?** The moment either player dies. There's no timer.
17. **What does `defer` do in `main`?** It frees the arrays and closes the network
    socket when `main` returns, after the loop.
18. **Why `max(f32)` in `nearest_alive_player`?** It's the starting "best distance",
    so the first living player is always closer.
