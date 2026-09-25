package game

// -----------------------------------------------------------------------------
// EVENT SYSTEM  --  the decoupling seam.
//
// The code that makes something happen POSTS. The code that cares LISTENS.
// Neither one imports the other, and neither one can break the other by
// changing. Adding a seventh thing that reacts to a death edits ONE switch.
// -----------------------------------------------------------------------------

import rl "vendor:raylib"

EventKind :: enum {
	PlayerJumped,
	PlayerLanded,
	PlayerDied,
	GoalReached,
	CoinCollected,
}

Event :: struct {
	kind:   EventKind,
	at:     rl.Vector2, // where it happened -- for sounds, particles, camera
	entity: int,        // who it happened to; -1 when nobody in particular
}

MAX_EVENTS :: 64

// A queue, not a callback list. Posting during a loop is safe because nothing
// is handled until the loop is finished -- the same reason spawning is deferred.
EventQueue :: struct {
	items: [MAX_EVENTS]Event,
	count: int,
}

post :: proc(q: ^EventQueue, kind: EventKind, at: rl.Vector2, entity := -1) {
	if q.count >= MAX_EVENTS do return // full: drop it. Never allocate mid-frame.
	q.items[q.count] = Event{kind = kind, at = at, entity = entity}
	q.count += 1
}

drain :: proc(q: ^EventQueue) -> []Event {
	return q.items[:q.count]
}

clear_events :: proc(q: ^EventQueue) {
	q.count = 0
}
