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
