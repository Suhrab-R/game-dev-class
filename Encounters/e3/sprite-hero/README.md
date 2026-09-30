# sprite-hero — Class 7, Encounter E3 (1 pt): your character

One blue rectangle that walks left and right on the ground. That's all.
Your job, in two steps:

1. **Your character** - replace the rectangle with a pixel-art character you
   drew yourself (TODOs 1-3).
2. **Make it walk** - a sprite-strip walking animation (TODOs 4-6).

## Run

Unzip `sprite-hero.zip`, then from inside the `sprite-hero` folder:

```sh
odin run .
```

The PNG paths are relative to the `.odin` file (`#directory`), so it also works
from anywhere else, e.g. `odin run sprite-hero`.

`←` `→` walk.

## Step 1: your character (TODOs 1-3)

1. **Draw** a **16×16** character in
   [Pixelorama](https://pixelorama.org), [LibreSprite](https://libresprite.github.io)
   or [Piskel](https://www.piskelapp.com) (browser, no install). Transparent
   background. Export it as **`assets/hero.png`** (next to the `.odin` file).
2. **Load it once**, before the loop: uncomment the two lines under TODO 2.
3. **Replace the rectangle** with `DrawTexturePro` (TODO 3):
   - `src`: the whole image - `{0, 0, w, h}`
   - `dst`: at `player.pos`, size `w * SCALE` × `h * SCALE`
   - `origin`: the **feet** - bottom-centre of the scaled sprite

## Hand in (Encounter E3, 1 pt)

On Canvas, **before you leave the room**: a **ZIP of your whole `sprite-hero`
folder**, with

- `assets/hero.png` - **16×16**
- `assets/hero-walk.png` - 4 frames of 16×16 side by side = **64×16**
- `sprite-hero.odin` drawing **your character** (not the blue rectangle)

Individual work, in the room only - no make-ups, no remote submission. The
point is for completion; the quality of the drawing is never graded.

**Stretch:** face left when walking left - a **negative** `src.width` mirrors
the sprite.

## Step 2: make it walk (TODOs 4-6)

A **sprite strip** is every frame of an animation side by side in ONE PNG.
The texture never changes; only `src` moves along the strip.

```text
assets/hero-walk.png  (4 frames of 16x16 = one 64x16 image)
+--------+--------+--------+--------+
| frame0 | frame1 | frame2 | frame3 |    src.x = frame * 16
+--------+--------+--------+--------+
```

4. **Draw the strip.** In your editor, duplicate your character into 4 frames
   side by side and move the legs (frames 0 and 2 can be the same "passing"
   pose). Export as **`assets/hero-walk.png`** and load it next to `hero.png`.
   Pixelorama, LibreSprite and Piskel all export animations as a horizontal
   strip ("spritesheet", 1 row).
5. **Animate** in UPDATE: while walking, add `dt` to `player.frame_timer`; each
   time it passes `FRAME_TIME`, advance `player.frame` and wrap with
   `% WALK_FRAMES`. Standing still -> frame 0.
6. **Draw one frame**: a frame is `walk.width / WALK_FRAMES` wide, and
   `src.x = player.frame * frame_width`.

**Stretch:** tune `FRAME_TIME` until the feet stop "sliding" on the ground ·
add a separate idle strip · try `SCALE :: 3` or `5` (whole numbers only).

## If something is wrong

| Symptom | Cause |
|---------|-------|
| Character invisible | the PNG didn't load - look for a `WARNING` about `hero.png` in the terminal; check the file name and folder |
| Character floats or sinks into the ground | `origin` isn't the feet: it must be `{scaled_w / 2, scaled_h}` |
| Character is blurry | a texture filter was set to `.BILINEAR` - raylib's default `.POINT` keeps pixel art crisp |
| Game gets slower and slower | `LoadTexture` ended up **inside** the loop |
| Two characters squashed side by side | `src.width` is the whole strip - divide by `WALK_FRAMES` |
| Animation frozen | `frame_timer` never grows (missing `+= dt`) or never wraps |
| Animation runs faster on a 144 Hz monitor | the timer counts frames, not seconds - use `dt` |
