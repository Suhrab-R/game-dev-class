"""Stats for one mini-jam session, for a jam-log.csv row.

Reads this machine's Claude Code transcripts for the game-dev-class repo
(~/.claude/projects/*game-dev-class*/) and reports, for one jam session:
date, active minutes, prompts, models, tokens (via ccusage, incl. cache), and
the files Claude wrote or edited (for ATTRIBUTION.md). --prompts also prints
the prompts themselves, so they can be summarized.

A jam session is bounded by two one-line prompts from the user, "session start"
and "session end" (any letter case). The window runs from the latest
"session start" to the "session end" after it, or to now if the session is
still open. Neither marker is counted as a prompt. If there is no
"session start", the script falls back to the first prompt after the previous
"session end" and warns. Nothing before JAM_START (setup) is ever counted.
Override with --since / --until (ISO 8601, e.g. 2026-09-27T21:29:00Z).

Only sees transcripts on THIS machine. Work done on another device must be
measured there (run this script on that device) and added by hand.

Usage:  python Side_Quests/sq1/tools/jam_session_stats.py [--since T] [--until T] [--gap 30] [--prompts] [--no-ccusage]
"""

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"
REPO_KEY = "gamedev-game-dev-class"  # encoded repo path suffix, lower-cased
START, END = "session start", "session end"
EDIT_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
# Everything before this is setup (gitignore, CLAUDE.md), not jam work. Never counted.
JAM_START = datetime(2026, 9, 27, 21, 56, 33, tzinfo=timezone.utc)


def parse_ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def user_text(msg):
    """The text the user typed, without IDE / system blocks. None if not a prompt."""
    content = msg.get("content")
    if isinstance(content, str):
        blocks = [content]
    else:
        if any(b.get("type") == "tool_result" for b in content):
            return None
        blocks = [b.get("text", "") for b in content if b.get("type") == "text"]
    typed = [b for b in blocks if not b.lstrip().startswith("<")]
    return "\n".join(typed).strip() or None


def marker(text):
    """START or END if the prompt is just a session marker (any case), else None."""
    words = " ".join(text.lower().strip(" .!\"'").split())
    return words if words in (START, END) else None


def load_events():
    prompts, usage, edits, seen = [], [], [], set()
    dirs = [d for d in PROJECTS.iterdir() if REPO_KEY in d.name.lower()]
    for d in dirs:
        for f in d.rglob("*.jsonl"):
            session_id = f.stem
            for line in f.open(encoding="utf-8"):
                try:
                    e = json.loads(line)
                except json.JSONDecodeError:
                    continue
                ts = e.get("timestamp")
                if not ts:
                    continue
                if e.get("type") == "user" and not e.get("isMeta") and not e.get("isSidechain"):
                    text = user_text(e["message"])
                    if text:
                        prompts.append((parse_ts(ts), text, session_id))
                elif e.get("type") == "assistant":
                    m = e.get("message", {})
                    for b in m.get("content") or []:
                        if b.get("type") == "tool_use" and b.get("name") in EDIT_TOOLS:
                            path = (b.get("input") or {}).get("file_path") or (b.get("input") or {}).get("notebook_path")
                            if path:
                                edits.append((parse_ts(ts), path))
                    key = (m.get("id"), e.get("requestId"))
                    if m.get("usage") and key not in seen:
                        seen.add(key)
                        usage.append((parse_ts(ts), m.get("model"), m["usage"], session_id))
    prompts.sort(key=lambda p: p[0])
    usage.sort(key=lambda u: u[0])
    return prompts, usage, edits


def ccusage_tokens(session_ids, start, end):
    """Sum ccusage's per-request entries inside the window. None if ccusage is unavailable."""
    npx = shutil.which("npx")
    if not npx:
        return None
    tin = tout = 0
    for sid in session_ids:
        r = subprocess.run([npx, "-y", "ccusage@latest", "session", "-i", sid, "--json", "--offline"],
                           capture_output=True, text=True, encoding="utf-8")
        if r.returncode != 0:
            return None
        for en in json.loads(r.stdout).get("entries", []):
            if start < parse_ts(en["timestamp"]) <= end:
                tin += en["inputTokens"] + en["cacheCreationTokens"] + en["cacheReadTokens"]
                tout += en["outputTokens"]
    return tin, tout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", help="window start (exclusive), ISO 8601")
    ap.add_argument("--until", help="window end (inclusive), ISO 8601")
    ap.add_argument("--gap", type=float, default=30, help="minutes of silence that count as a break")
    ap.add_argument("--prompts", action="store_true", help="also print every prompt in the window")
    ap.add_argument("--no-ccusage", action="store_true", help="sum tokens from the logs directly")
    args = ap.parse_args()

    prompts, usage, edits = load_events()
    if not prompts:
        sys.exit("no transcripts found for this repo on this machine")
    starts = [p[0] for p in prompts if marker(p[1]) == START and p[0] > JAM_START]
    ends = [p[0] for p in prompts if marker(p[1]) == END and p[0] > JAM_START]

    if args.until:
        end = parse_ts(args.until)
    elif ends and (not starts or ends[-1] > starts[-1]):
        end = ends[-1]
    else:
        end = datetime.now(timezone.utc)  # session still open

    # A "session start" only belongs to this session if it comes after the previous "session end".
    prev_end = max([e for e in ends if e < end], default=JAM_START)
    own_starts = [s for s in starts if prev_end < s < end]
    trim_to_first_prompt = False
    if args.since:
        start = parse_ts(args.since)
    elif own_starts:
        start = own_starts[-1]
    else:
        start = prev_end
        trim_to_first_prompt = True
        print("WARNING: no 'session start' found; using the first prompt after the previous "
              "'session end'. Pass --since if that is wrong.\n")
    start = max(start, JAM_START)

    win_prompts = [p for p in prompts if start < p[0] <= end and not marker(p[1])]
    if not win_prompts:
        sys.exit(f"no prompts between {start} and {end}")
    if trim_to_first_prompt:
        start = win_prompts[0][0] - timedelta(milliseconds=1)
    marks = [p[0] for p in prompts if start <= p[0] <= end and marker(p[1])]
    win_usage = [u for u in usage if start < u[0] <= end]

    # Active minutes: sum gaps between consecutive events, skipping breaks longer than --gap.
    times = sorted([p[0] for p in win_prompts] + [u[0] for u in win_usage] + marks)
    active, breaks = 0.0, []
    for a, b in zip(times, times[1:]):
        mins = (b - a).total_seconds() / 60
        if mins <= args.gap:
            active += mins
        else:
            breaks.append((a, b, mins))

    session_ids = sorted({u[3] for u in win_usage})
    models = sorted({u[1] for u in win_usage if u[1] and not u[1].startswith("<")})

    tokens, source = None, None
    if not args.no_ccusage:
        tokens = ccusage_tokens(session_ids, start, end)
        source = "ccusage incl. cache"
    if tokens is None:
        u = [x[2] for x in win_usage]
        tokens = (sum(x.get("input_tokens", 0) + x.get("cache_creation_input_tokens", 0)
                      + x.get("cache_read_input_tokens", 0) for x in u),
                  sum(x.get("output_tokens", 0) for x in u))
        source = "claude-code logs incl. cache"

    local = lambda t: t.astimezone().strftime("%Y-%m-%d %H:%M")
    print(f"window        : {local(times[0])} -> {local(times[-1])} (local time)")
    print(f"date          : {times[0].astimezone().date()}")
    print(f"minutes       : {round(active)}  (active; breaks > {args.gap:g} min excluded)")
    print(f"tool          : claude-code")
    print(f"model         : {';'.join(models)}")
    print(f"tokens_in     : {tokens[0]}")
    print(f"tokens_out    : {tokens[1]}")
    print(f"tokens_source : {source}")
    print(f"prompts       : {len(win_prompts)}")
    print(f"transcripts   : {', '.join(session_ids)}")
    edited = sorted({Path(p).as_posix() for t, p in edits if start < t <= end}, key=str.lower)
    print("files edited  : (via Claude's Write/Edit tools; edits made through shell commands or by hand are NOT listed, check git too)")
    for p in edited:
        print(f"                {p}")
    for a, b, mins in breaks:
        print(f"BREAK         : {local(a)} -> {local(b)} ({mins:.0f} min). Per the README this "
              f"ends a session; ask the user whether it should be split into two rows.")
    if args.prompts:
        # Each prompt, followed by the files Claude edited in response to it (every edit
        # between this prompt and the next one). This is what ATTRIBUTION.md rows are built
        # from: one row per (file, prompt), with a summary of that prompt.
        print("\nprompts (with the files edited in response to each):")
        for i, (t, text, _) in enumerate(win_prompts):
            next_t = win_prompts[i + 1][0] if i + 1 < len(win_prompts) else end
            files = sorted({Path(p).name for et, p in edits if t < et <= next_t}, key=str.lower)
            print(f"\n  [{local(t)}] {' '.join(text.split())}")
            print(f"    -> edited: {', '.join(files) if files else '(nothing)'}")


if __name__ == "__main__":
    main()
