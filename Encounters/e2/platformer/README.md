# One screen, one goal, one enemy

The Chapter 4 demo: a complete platformer in 705 lines, split into four Odin
packages so that each one sits on a named floor of the engine-architecture
tower — and so that the compiler refuses to let a lower floor call an upper one.

```sh
odin run source/platformer        # from the repository root
```

`A`/`D` or arrows to move · `SPACE`/`W`/`UP` to jump · `R` to restart ·
`F5` to re-read `level.txt` **without rebuilding**.

---

## 1. Module map — what each file *is*

```
source/platformer/
│
│  main.odin ................ package main ...... the spine: window + loop   49
│                                                 8 rl. calls, all of them
├─ input/
│    input.odin ............. package input ..... keys  ->  Actions          53
│
├─ game/  ................... package game ...... the game. No window, no
│    world.odin ......................... gameplay foundations: entities     89
│    level.odin ......................... resources: the level is text      136
│    physics.odin ....................... collision: a box vs a tile grid    99
│    rules.odin ......................... game-specific: what contact MEANS  120
│    events.odin ........................ the decoupling seam                47
│
└─ render/
     render.odin ........... package render .... World  ->  pixels          112

──────────────────────── the raylib seam ────────────────────────
  CALLS raylib:   main.odin · input/input.odin · render/render.odin
  never does:     all five files in game/
```

The seam is checkable, and the open paren matters:

```sh
grep -rlE 'rl\.[A-Z][A-Za-z]*\(' source/platformer --include="*.odin"
# source/platformer/main.odin
# source/platformer/input/input.odin
# source/platformer/render/render.odin
```

Three files call Raylib; five do not. Three of the five in `game/` still *name*
Raylib types (`rl.Vector2` is two floats) but make no call — no window, no key,
no draw. **Types are vocabulary; calls are dependency.**

---

## 2. Call graph — who calls whom

```
main.odin  -- the only file that knows all the others
  │
  ├─ input.poll_input()     input/     keys ......... ->  Input
  │
  ├─ game.update_world()    game/      Input + World  ->  World'
  │      ├─ move_and_collide, grounded, overlapping ....... physics.odin
  │      ├─ post, drain, clear_events ..................... events.odin
  │      └─ tile_at ....................................... level.odin
  │
  └─ render.draw_world()    render/    World ........ ->  pixels
         └─ game.tile_at ................................... level.odin
```

`rules.odin` **writes** the `World`. `render.odin` **reads** it and writes
nothing at all. `main.odin` **owns** it — one struct, on the stack.

Four of the eight files call nothing at all: `input`, `events`, `level`,
`world`. They are asked questions; they do not ask. `physics.odin` calls
exactly one thing, downwards: `tile_at`.

Inside `update_world`, a single `switch` is the entire dispatch:

```
.Player -> update_player      .Goal -> nothing; it just sits there
.Walker -> update_walker      .None -> nothing
```

### The package graph, and why it is a real constraint

```
        main                 imports input, game, render
       ╱  │  ╲
   input  │   render         render imports game
       ╲  │  ╱
        game                 game imports input
```

Odin has no cyclic imports, so this direction is **enforced, not encouraged**.
Add `import "../render"` to `game/rules.odin` and the build stops:

```
game/rules.odin(4:1) Error: 'render' refers to
render/render.odin(11:1) Error: Cyclic importation of 'game'
```

That is Chapter 3's *dependencies point down* rule, checked by the compiler
instead of by a code review.

---

## 3. Data ownership — who holds what

```
World  ................... one struct, on the stack. The game never allocates
  │                         during play; the only allocation is the level file,
  │                         read once and freed.
  ├─ level:    Level ...... tiles [20][30]Tile  +  spawn markers
  ├─ entities: [64]Entity . a flat array. count says how many are live.
  ├─ player:   int ........ an INDEX, not a pointer: it survives a copy or a
  │                         save, and it cannot dangle
  ├─ state:    GameState .. Playing | Won | Dead
  ├─ events:   EventQueue . [64]Event, drained and cleared every frame
  └─ squash:   f32 ........ render-only feedback, written by an event listener
                            and read by nothing else

Entity ................... ONE struct for every kind of thing
  ├─ kind ....... EntityKind: None | Player | Walker | Goal
  ├─ pos, vel, size, facing
  ├─ on_ground .. a question asked of the world each frame, not a leftover
  └─ alive ...... false removes it from play without moving anything
```

A `Goal` carries a velocity it will never use. That costs eight bytes and buys
one array, one loop, one code path.

---

## 4. The one pair that names each other

```
   world.odin    Entity, EntityKind, World, MAX_ENTITIES      the entity model
       ▲  │
       │  │   World.level: Level              world.odin NAMES level.odin
       │  ▼
   level.odin    Level, Tile, the legend, parse_level         the level format
       │
       └──  SpawnMarker.kind: EntityKind      level.odin NAMES world.odin
            spawns: [MAX_ENTITIES]SpawnMarker
```

Neither file **calls** the other — they **name** each other's types, which a
call graph cannot see. Both are reasonable: the `World` obviously contains a
`Level`, and a level format obviously has to say what a `'P'` means.

Inside one package this costs nothing, which is exactly why `world.odin` and
`level.odin` live in `game/` together. Split them into two packages and it
stops compiling. The fix, when that day comes, is the one `source/jrpg` already
uses: a shared `types` package that both depend on and that depends on neither.

**You are not required to have no cycles. You are required to know where
they are.**

---

## The level is data

`level.txt` is the whole level. Edit it while the game is running, press `F5`.

```
'.' empty   '#' solid   'P' player spawn   'E' walker spawn   'T' turner spawn
'C' chaser spawn   'o' coin spawn   'G' goal
```

Every piece of content enters through the `legend` table in `game/level.odin`,
one row per character. `parse_level` rejects an unknown character rather than
silently loading an empty room.

## Tuning

Everything a designer would argue about is at the top of `game/rules.odin`. The
two numbers that decide the level's shape are `GRAVITY` (1800 px/s²) and
`JUMP_SPEED` (-700 px/s): together they make the jump **136 px** tall, so a
three-tile step is comfortable and a five-tile step is impossible.

## Things to try

**[ACTIVITY.md](ACTIVITY.md)** — two worked step by step (a second enemy type,
then a collectible), and six extra challenges after them, up to record-and-replay.
Each one names the files it should touch and the design decision it forces.

Encounter E2 is the paper version of that list — you name the files you *would*
touch, and argue about whether the answer smells.
