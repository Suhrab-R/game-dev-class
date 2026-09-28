package arena

import rl "vendor:raylib"

// Reads this computer's keyboard and mouse into a Player_Input.
// The simulation never reads the keyboard directly: it only sees Player_Inputs,
// so the host can treat its own input and player 2's (from the network) the same way.
read_local_input :: proc() -> Player_Input {
	input: Player_Input // variables start zeroed in Odin, so move = {0, 0} and the bools are false

	// `if cond do statement` is Odin's one-line if.
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)    do input.move.y -= 1
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)  do input.move.y += 1
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)  do input.move.x -= 1
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) do input.move.x += 1

	input.aim = rl.GetMousePosition()
	input.shooting = rl.IsMouseButtonDown(.LEFT)
	// "Held" rather than "pressed this frame": a single-frame press could be lost if
	// that one network packet is dropped, but a held key is sent in many packets.
	input.restart = rl.IsKeyDown(.R) || rl.IsKeyDown(.ENTER)
	return input
}
