# Things to try

## Building and running

From the repository root:

```sh
odin run source/platformer      # compile and play
odin build source/platformer    # compile only -- what you want while fixing errors
```

**While you are working down the compiler's to-do list, use `odin build`.** You
want the error list, not a window.

Both commands drop a `platformer` binary in whatever directory you ran them
from. Send it somewhere else if that annoys you:

```sh
odin build source/platformer -out:/tmp/platformer
```

You can also work from inside the folder — `cd source/platformer && odin run .`
— and `level.txt` is still found, because `load_level` tries the local path
first and the repo-root path second.

A full rebuild of all eight files takes about **0.3 seconds**. Keep that number
in mind: it is why this course does not write a scripting language. When the
turnaround is already under a second, the only thing still worth moving out of
the code is the *content* — which is what the next paragraph is about.

**The level is data.** `F5` re-reads `level.txt` with the game still running.
You do not need to rebuild to test a level change, and you should not be
restarting the program to move a platform.

## 1. A second enemy type

**Goal:** a `Chaser` — an enemy that walks *toward* the player instead of
patrolling, and that refuses to step off the ledge it is standing on. When you
are done, typing a `C` into `level.txt` puts one in the level.

**You will touch:** `game/world.odin` · `game/rules.odin` · `game/level.odin` ·
`render/render.odin`
**You should not touch:** `game/physics.odin` · `game/events.odin` · `input/` ·
`main.odin`

---

### Step 1 — make the compiler write your to-do list

In `game/world.odin`, add one line to `EntityKind`:

```odin
EntityKind :: enum u8 {
	None,
	Player,
	Walker,
	Goal,
	Chaser,        // <- this is the entire change
}
```

Build it. It fails, on purpose, with **exactly four errors** — nothing else:

```
render/render.odin(25:2) Unhandled switch case: Chaser   Suggestion: Was '#partial switch' wanted?
game/rules.odin(28:3)    Unhandled switch case: Chaser   Suggestion: Was '#partial switch' wanted?
game/world.odin(55:2)    Unhandled switch case: Chaser   Suggestion: Was '#partial switch' wanted?
game/rules.odin(97:3)    Unhandled switch case: Chaser   Suggestion: Was '#partial switch' wanted?
```

> **Ignore that suggestion.** `#partial switch` tells Odin "some cases are
> missing and that is fine", which turns off the exact feature you are using
> here. Taking it would make the game compile and the Chaser invisible,
> sizeless and harmless. The errors are not in your way; they *are* the
> instructions.

Translated, those four are:

```
game/world.odin     entity_size     how big is it?
render/render.odin  entity_color    what colour is it?
game/rules.odin:28  update_world    what does it DO each frame?
game/rules.odin:97  check_touches   what happens when the player hits it?
```

Those four questions are the *only* four that adding a thing to this game can
raise. Work down the list. (Your line numbers will differ by one or two
depending on where you put the case — the file and the procedure are what
matter.)

### Step 2 — answer three of them, one line each

- **`entity_size`** in `game/world.odin` — `case .Chaser: return {26, 26}`
- **`entity_color`** in `render/render.odin` — pick something that is not red
- **`check_touches`** in `game/rules.odin` — it kills you exactly like the
  Walker does, so widen the case that is already there:
  `case .Walker, .Chaser:`

Build again. One error left.

### Step 3 — the fourth error is the actual work

In `update_world`, add `case .Chaser: update_chaser(w, &e, dt)`, then write
`update_chaser` next to `update_walker`. The behaviour, precisely:

1. face the player — left if the player is left of it, right otherwise
2. walk that way at `WALK_SPEED`
3. fall like everything else does
4. **but** if there is no floor one pixel ahead, stand still rather than step off

**Every ingredient already exists. Do not write a new one.**

| you need | it is already here |
|---|---|
| where is the player? | `w.entities[w.player].pos` |
| gravity, terminal velocity | the two lines at the top of `update_walker` |
| move, and stop at walls | `move_and_collide` |
| am I standing on something? | `grounded` |
| is there floor ahead of me? | the `probe_x` / `probe_y` lines in `update_walker` |

Point 4 is the whole difficulty. Decide **before** you move, not after — once
`move_and_collide` has run, the Chaser is already over the drop.

### Step 4 — let the level spell it

One row in the `legend` table in `game/level.odin`:

```odin
{'C', .Empty, .Chaser},
```

Rebuild once. From now on you can type `C` anywhere in `level.txt` and press
**F5** in the running game — **no rebuild**. Put one on the top platform and
watch it come at you.

### Done when

- a `C` in `level.txt` spawns an enemy that walks toward you and **stops at the
  edge** instead of falling off
- touching it kills you
- `game/physics.odin`, `game/events.odin`, `input/` and `main.odin` are
  byte-for-byte unchanged
- the seam grep still prints exactly three files

**The question:** four files for one enemy. Is that a smell? Argue it both ways.
The alternative — an `Enemy` base class with a virtual `update()` — puts all six
edits in one place and costs you a heap allocation and a pointer chase per
enemy, per frame. Which cost would you rather pay, and at what number of
enemies does your answer change?

---

### Variants, once the Chaser works

**A `Turner`** — two minutes. Copy `update_walker` and delete the ledge check,
so it turns at walls only and walks cheerfully off cliffs. Worth doing just to
see what that one probe was buying.

**A `Jumper`** — this one is not a warm-up, and it is the interesting one. "Hops
every second or so" needs a per-entity timer, and **`Entity` has no timer
field.** Your options, all defensible, none free:

- add `timer: f32` to `Entity` — every Goal, every coin, every future entity now
  carries four bytes it will never read
- derive it from `w.elapsed` and the entity's index — no new data, but every
  Jumper in the level hops in lockstep
- keep a separate array of jumper state, indexed alongside `entities`
- give it a `vel.y` kick whenever it lands, so "landed" *is* the timer


---

## 2. A collectible

**Goal:** a `Coin`. Walking into one makes it vanish and adds to a count in the
HUD. When you are done, typing `o` into `level.txt` places one.

**You will touch:** `game/world.odin` · `game/events.odin` · `game/rules.odin` ·
`game/level.odin` · `render/render.odin`
**You should not touch:** `game/physics.odin` · `input/` · `main.odin`

---

### Step 1 — the same four questions

Add `Coin` to `EntityKind` in `game/world.odin` and build. You get the same four
errors as last time. Answer three of them now:

- **`entity_size`** — `case .Coin: return {16, 16}`
- **`entity_color`** — gold
- **`update_world`** — `case .Coin:` with **nothing in it**. A coin does nothing
  each frame, exactly like the Goal. An empty case is a real answer; it is the
  compiler asking "and what about this one?" and you replying "nothing".

Leave the fourth, `check_touches`, for Step 3.

### Step 2 — a new event, and a different kind of error

In `game/events.odin`, add one value:

```odin
EventKind :: enum {
	PlayerJumped,
	PlayerLanded,
	PlayerDied,
	GoalReached,
	CoinCollected,   // <- this is the entire change
}
```

Build. Now there are two errors, and they are different in kind:

```
game/rules.odin(98:3)  Unhandled switch case: Coin            <- check_touches, the one you skipped
game/rules.odin(110:3) Unhandled switch case: CoinCollected   <- apply_events, brand new
```

The first is Step 3. The second is the interesting one: it has nothing to do
with entities. It is `apply_events`, the listener — and it proves the event
system has the same exhaustiveness the entity model does. **You cannot add a
thing that can happen without being asked what happens when it does.**

(Line numbers drift as you edit; the procedure names are what matter.)

### Step 3 — announce; do not act

Back in `check_touches`, add the case you skipped:

```odin
case .Coin: post(&w.events, .CoinCollected, e.pos, i)
```

Two details, and they are the whole step.

**Look at the last argument.** Every other `post` in this file passes
`w.player`. This one passes `i` — *the coin's own index* — because the listener
is what has to remove it, and it will need to know which one.

**Do not write `w.coins += 1` here.** It would work. Resist it; Step 5 is where
it goes, and the question at the bottom is why.

> While you are here, notice something that will bite you: `e` in this loop is a
> **copy**. Writing `e.alive = false` compiles, runs, and does nothing at all.
> That is a second reason removal belongs in the listener, where you have `ev.entity`
> and can reach `w.entities[...]` for real.

### Step 4 — somewhere to keep the count

One field, in `World`, in `game/world.odin`:

```odin
coins: int,
```

Nothing else. `world_start` does `w^ = World{...}`, so `R` resets it for free.

Unlike the debug flag in Task 3, this one genuinely **is** game state: it is part
of the run, it should restart with the run, and if you ever record a replay it
has to come back the same. `World` is exactly where it belongs.

### Step 5 — listen

In `apply_events`:

```odin
case .CoinCollected:
    w.coins += 1
    w.entities[ev.entity].alive = false
```

Two things now happen when a coin is taken, in one place, and **neither of them
is in the code that detected the touch.**

`alive = false` *is* the removal. Nothing is deleted, nothing shifts, `w.count`
does not change, and `w.player` still points exactly where it did. Every loop in
the game already skips dead entities. That is **deferred despawn**, three weeks
before Chapter 12 names it.

### Step 6 — draw it, spell it

- `draw_hud` in `render/render.odin` — one more `rl.DrawText` for the count.
- `legend` in `game/level.odin` — `{'o', .Empty, .Coin},`

Then put a few `o` characters in `level.txt` and press **F5**. No rebuild.

### Done when

- an `o` places a coin; walking into it removes it and the HUD count rises
- `check_touches` contains no `+=` at all — grep it. It only posts.
- **collected + still-alive == placed**, always. Count the `.Coin` spawn markers
  in the level, then at any moment count `w.coins` plus the coins with
  `alive == true`. If that ever disagrees you have lost or double-counted an
  entity, which is the classic despawn bug.
- `game/physics.odin`, `input/` and `main.odin` are unchanged

**The question:** why not just `w.coins += 1` in `check_touches`? Because a coin
is never only a counter. The day it also wants a sound, a sparkle, a HUD flash,
an achievement at ten and a door that opens when they are all taken, the direct
version edits `check_touches` five more times, and every one of those edits is
in the middle of collision code. The event version edits `apply_events`. The
event version is more code today and less code on the fifth change — decide for
yourself where the crossover is.

---

### Variants, once coins work

**Lock the goal until every coin is taken.** Where does "every coin is taken"
get computed — once per frame, or once per `CoinCollected`? Both work. One of
them loops over 64 entities sixty times a second to answer a question that
changes five times a game.

**Show `3 / 7` instead of `3`.** Where does the 7 come from? Counting spawn
markers at `world_start` is one line. Counting live coins every frame is also
one line, and it is wrong the moment you collect one.

**Make the coin bob up and down.** It needs a per-entity timer — which is Task
1's Jumper problem again, and the same four options apply.

---

# Extra challenges

## 3. Show the game its own numbers ★

**Touches:** `input/input.odin` · `render/render.odin` · (`main.odin`, only for
the frame-time version)

Chapter 4 gave a specification for debugging tools before you could build one:

> a way to **manually instrument** code · **on-screen profiling statistics while
> the game runs** · memory used **by each subsystem** · dumps of usage and
> leaks · the ability to **record and play back**

This game has none of it. Build the second bullet. Press `F1` and an overlay
appears showing what the game knows about itself:

```
  state      Playing              entities   3 / 64
  fps        60   (16.4 ms)       events     2 this frame
  player     pos 452, 356         level      level.txt
             vel 0, 30            tile       col 14, row 11
             on_ground  true      elapsed    3.4 s
```

Press `F1` again and it is gone.

**Start here:** add one value to `Action`, one row to `bindings`, and one
`draw_debug` procedure. `rl.GetFPS()` and `rl.GetFrameTime()` are free;
`w.count`, `w.state`, `w.elapsed`, `w.events.count`, `w.level.source` and
`w.entities[w.player]` are all already reachable from `render/`. For the tile
under the player, `game.tile_of` and `game.tile_at` are public.

**The constraint, and it is the point:** you can build the whole overlay
**without editing a single file in `game/`**. If you find yourself adding a
field to `World` to make the display work, you have started storing
presentation in game state — back it out and find another way. A good seam
means the renderer can answer new questions without the game changing.

**The design question you cannot avoid:** where does the `show_debug` flag
live?

- in `World`? Then it gets saved, replayed and reset by `R` — but it is not part
  of the game.
- a local in `main.odin`, passed down? Then `draw_world` grows a parameter, and
  so does everything under it.
- a package-level `var` in `render/`? Then the renderer owns its own view
  options — and you have introduced mutable global state.

There is no free answer. Pick one, write down why in a comment, and be ready to
defend it. This is exactly the kind of decision CP2 asks you to justify.

**Going further:** the frame-time number is the interesting one, and it is not
raylib's. Instrument it yourself — take `rl.GetTime()` either side of
`update_world` and again either side of `draw_world`, and draw the two numbers
against the 16.6 ms budget as a bar. Now you can see which half of the frame
costs what. `source/game-loop/game-loop.odin` already does this in about six
lines; read it. That is *manual instrumentation*, bullet one of the spec, and
it is the only way you will ever answer "why did it get slow".

**Done when:** `F1` toggles it, the numbers move, and `git diff game/` is empty.

---

## 4. Rebindable keys

**Shape:** the cheapest big win in the codebase.
**Touches:** `input/input.odin` · `render/render.odin` · `main.odin`

`bindings` is already a table. Make it editable while the game runs: a screen
that lists each `Action`, lets you pick one, waits for a key, and writes it into
the table.

`rl.GetKeyPressed()` returns the next key in the queue, or `.KEY_NULL` — that is
your capture loop.

**The question:** notice what you did *not* have to touch. `rules.odin` asks for
`.Jump`; it has never known which key that is, so a rebinding screen cannot
break the player's movement. Ask yourself what this feature would have cost in a
codebase where `rl.IsKeyPressed(.SPACE)` appeared in the jump code.

**Going further:** save the table to a file and load it at startup. You now have
two kinds of data on disk — a level and a settings file — which is the moment a
**resource manager** stops being a diagram and starts being a thing you need.

---

## 5. A second level

**Shape:** the empty box in the tower, filled.
**Touches:** `game/level.odin` · `game/rules.odin` · `game/world.odin` ·
`main.odin`

Reaching the goal loads `level-2.txt` instead of ending the game. Finishing the
last level wins.

**The question:** this is where `load_level` stops being enough and a **resource
manager** starts. Today it reads one file, hands back a `Level`, and frees the
bytes. Now answer:

- who owns the list of levels, and where is it written down? (Hint: a file. Not
  an array in the code.)
- what carries across a transition — the coin count? the timer? the best time?
- what happens if `level-2.txt` is missing or has a typo in it? `parse_level`
  already returns `ok = false`; is falling back to the built-in level the right
  behaviour here, or should it be a visible error?

That third question is the real one. Silent fallback is fine for one level and
actively hostile once a player can lose progress to it.

**This is CP3.** Loaded once, shared, tuning and level data in files.

---

## 6. A moving platform

**Shape:** the honest trap. Attempt it knowing it does not have a cheap answer.
**Touches:** `game/physics.odin` and then, probably, your plan

A platform that slides between two points, carrying the player.

The tile grid has no notion of a solid that moves. `solid_rect` asks a *static*
`Level` whether a cell is `.Solid`, and `move_and_collide` resolves a box
against that grid. Neither has anywhere to put a platform.

So you have to choose:

- **make it a tile that moves** — the grid is `[20][30]Tile`, indexed by integer
  cell. A platform at x = 451.7 is not expressible. Dead end; understand *why*
  before you abandon it.
- **make it an entity, and teach physics about entity-vs-entity** — now
  `move_and_collide` needs a list of solid boxes as well as the grid, and its
  signature changes for every caller.
- **resolve it in `rules.odin` after the grid pass** — move the player by the
  platform's delta when standing on it. Cheapest, and it leaks platform
  knowledge into the rules.

**The question:** all three are defensible. Write one paragraph on which you
picked and what it costs *next* — when you want a crusher that kills you, a
platform that falls when stepped on, or a lift that carries the Walker too.

This is the task most likely to make you restructure something, which is why it
is on the list. Most real architecture work starts as "I just want a moving
platform".

---

## 7. A death animation

**Shape:** where the `enum` runs out.
**Touches:** `game/world.odin` · `game/rules.odin` · `render/render.odin`

On death, freeze for half a second, flash the player, *then* allow the restart.

`GameState` is `enum { Playing, Won, Dead }`, and a value carries no data. You
now need a timer and a position that mean nothing while `Playing`. The upgrade
is a tagged union:

```odin
Playing :: struct { elapsed: f32 }
Dead    :: struct { at: rl.Vector2, timer: f32 }
GameState :: union { Playing, Dead, Won }

switch &s in gs {              // & binds a POINTER to the active variant.
case Dead: s.timer -= dt       // drop the & and you mutate a copy.
}
```

**The question:** if `Playing` holds the `World`, then `gs^ = Dead{}` throws the
level away — and `R` has to bring it back. Three fixes, all defensible: keep the
`World` in `World` and make only the *mode* a union; put the death timer beside
the world as a plain field; or copy into `Dead` only what `Dead` needs. Pick
one. Say why.

Chapter 15 settles this argument properly, with components and ECS on the table.
You are allowed to reach a different conclusion there than you reach here.

---

## 8. Record and replay

**Shape:** the hardest, and the one a professional would build first.
**Touches:** `input/input.odin` · `main.odin` · `render/render.odin`

`F6` records every frame's `Input` into a list. `F7` replays it, feeding the
recorded inputs to `update_world` instead of the keyboard, and the game plays
itself.

This is only possible because intent is a **value**. An `Input` is two bytes of
`bit_set`; a whole session is an array of them. If the player code read
`rl.IsKeyDown` directly there would be nothing to record.

**It will not reproduce, and finding out why is the exercise.** Replay is exact
only if every source of nondeterminism goes through one door. This game has
three problems waiting for you:

1. `dt` comes from `rl.GetFrameTime()` and is different every frame. Replay it
   with a **fixed** `dt` and the recording is meaningful. This is the difference
   between `rl.SetTargetFPS(60)`, which is a `sleep`, and a real fixed timestep.
2. any randomness must be **seeded**, and the seed recorded with the tape. This
   game has none today — check for yourself, then notice that adding one
   enemy that picks a random direction breaks replay forever unless you plan
   for it.
3. the recording must start from a known world. Record the level name and
   restart from it.

**Why it is worth it:** this is the difference between "it crashes sometimes"
and a bug you can hand someone. It is how QA files a report you can act on, and
it is how you A/B a difficulty change honestly instead of by feel. Chapters 19
and 20 need exactly this.

`source/input-command/input-command.odin` in this repo already does all of it —
tape, replay, and a deliberate desync toggle so you can watch determinism break.
Read it after you have tried.
