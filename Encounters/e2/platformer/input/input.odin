package input

// -----------------------------------------------------------------------------
// HID / PLATFORM  --  the only file in this game that knows a keyboard exists.
//
// THE RULE: rl.IsKey* appears here and nowhere else. Grep for it.
// Everything above this floor deals in ACTIONS -- things a player can WANT.
// "Jump" is a game concept. ".SPACE" is a hardware fact. They do not mix.
// -----------------------------------------------------------------------------

import rl "vendor:raylib"

Action :: enum u8 {
	Left,
	Right,
	Jump,
	Restart,
	ReloadLevel,
}

ActionSet :: bit_set[Action]

Input :: struct {
	held:    ActionSet, // true every frame it is active -- movement, aiming
	pressed: ActionSet, // true only on the frame it BEGINS -- jump, menus, fire
}

// Bindings are DATA, and two rows may name the same action: WASD and the arrow
// keys are the same game. A rebinding screen is a program that edits this table.
Binding :: struct {
	action: Action,
	key:    rl.KeyboardKey,
}

bindings := [?]Binding {
	{.Left, .A},
	{.Left, .LEFT},
	{.Right, .D},
	{.Right, .RIGHT},
	{.Jump, .SPACE},
	{.Jump, .W},
	{.Jump, .UP},
	{.Restart, .R},
	{.ReloadLevel, .F5},
}

poll_input :: proc() -> (f: Input) {
	for b in bindings {
		if rl.IsKeyDown(b.key) do f.held += {b.action}
		if rl.IsKeyPressed(b.key) do f.pressed += {b.action}
	}
	return
}
