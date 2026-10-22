"""Session logic of the TCP server, without opening a socket."""
from bloxorz.server import Session
from conftest import LEVELS
from test_golden import GOLDEN


def test_apply_runs_many_moves_like_single_moves():
    s = Session()
    s.handle({"cmd": "load", "path": str(LEVELS / "level01.json")})
    r = s.handle({"cmd": "apply", "actions": GOLDEN["level01.json"]})
    assert r["ok"] and "win" in r["events"]


def test_apply_stops_at_a_fall():
    s = Session()
    s.handle({"cmd": "load", "path": str(LEVELS / "level01.json")})
    r = s.handle({"cmd": "apply", "actions": ["U", "U", "U"]})
    assert r["ok"] and r["state"] is None and "fall" in r["events"]


def test_load_accepts_level_json_from_the_gui():
    import json
    data = json.loads((LEVELS / "level14.json").read_text(encoding="utf-8"))
    s = Session()
    r = s.handle({"cmd": "load", "level": data})
    assert r["ok"] and s.level.id == 14


def _poll_until(s, phases, timeout=60.0):
    import time
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        r = s.handle({"cmd": "solve_poll"})
        if r["phase"] in phases:
            return r
        time.sleep(0.05)
    raise AssertionError(f"still {r['phase']} after {timeout} s")


def test_background_solve_sends_actions_then_peak_memory():
    s = Session()
    try:
        s.handle({"cmd": "load", "path": str(LEVELS / "level01.json")})
        assert s.handle({"cmd": "solve_start", "algo": "bfs"})["ok"]
        r = _poll_until(s, ("measuring", "done"))
        assert r["result"]["actions"] == GOLDEN["level01.json"]
        r = _poll_until(s, ("done",))
        assert r["result"]["metrics"]["peak_kb"] > 0
    finally:
        s.job.close()


def test_load_cancels_a_running_solve_at_once():
    import time
    s = Session()
    try:
        s.handle({"cmd": "load", "path": str(LEVELS / "level15.json")})   # BFS needs seconds
        s.handle({"cmd": "solve_start", "algo": "bfs"})
        time.sleep(0.3)
        t0 = time.monotonic()
        s.handle({"cmd": "load", "path": str(LEVELS / "level01.json")})
        assert time.monotonic() - t0 < 3
        assert s.handle({"cmd": "solve_poll"})["phase"] == "idle"
        s.handle({"cmd": "solve_start", "algo": "astar"})   # the fresh worker still works
        r = _poll_until(s, ("done",))
        assert r["result"]["found"] and r["result"]["level"] == 1
    finally:
        s.job.close()


def test_solve_poll_reports_progress_and_total():
    import time
    s = Session()
    s.handle({"cmd": "load", "path": str(LEVELS / "level14.json")})
    s.handle({"cmd": "solve_start", "algo": "bfs"})
    seen = 0
    for _ in range(200):
        p = s.handle({"cmd": "solve_poll"})
        assert p["total"] == 61579
        seen = max(seen, p["progress"])
        if p["phase"] in ("measuring", "done"):
            break
        time.sleep(0.05)
    assert p["phase"] in ("measuring", "done")
    assert p["progress"] == p["result"]["metrics"]["expanded"] > 0
    s.job.close()
