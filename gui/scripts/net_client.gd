class_name NetClient
extends Node
## TCP client for bloxorz/server.py (docs/ARCHITECTURE.md section 3).
## One JSON object per line in both directions.

const HOST := "127.0.0.1"
const PORT := 5555

var connected: bool = false
var _tcp := StreamPeerTCP.new()
var _buffer: String = ""


## Try to connect for up to `timeout` seconds. Returns true when connected.
func try_connect(timeout: float = 0.6) -> bool:
	_tcp.disconnect_from_host()   # reset a peer left in an error state
	_buffer = ""
	if _tcp.connect_to_host(HOST, PORT) != OK:
		return false
	var deadline := Time.get_ticks_msec() + int(timeout * 1000)
	while Time.get_ticks_msec() < deadline:
		_tcp.poll()
		var st := _tcp.get_status()
		if st == StreamPeerTCP.STATUS_CONNECTED:
			connected = true
			return true
		if st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE:
			return false
		await get_tree().process_frame
	_tcp.disconnect_from_host()
	return false


## main.gd bumps this on Restart / new level / new solve.
var epoch: int = 0
var _in_flight: bool = false


## Send one request and wait for its reply. Returns {} if the connection drops,
## {"stale": true} if the game moved on (epoch changed) before it could be sent.
## Only one request is on the wire at a time, so replies cannot be mixed up.
func request(msg: Dictionary, ep: int = -1) -> Dictionary:
	while _in_flight:
		await get_tree().process_frame
	if ep >= 0 and ep != epoch:
		return {"stale": true}
	_in_flight = true
	var reply := await _send(msg)
	_in_flight = false
	return reply


func _send(msg: Dictionary) -> Dictionary:
	if not connected:
		return {}
	var err := _tcp.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())
	if err != OK:
		connected = false
		return {}
	while true:
		_tcp.poll()
		if _tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			connected = false
			return {}
		var n := _tcp.get_available_bytes()
		if n > 0:
			var chunk: Array = _tcp.get_partial_data(n)
			_buffer += (chunk[1] as PackedByteArray).get_string_from_utf8()
			var nl := _buffer.find("\n")
			if nl >= 0:
				var line := _buffer.substr(0, nl)
				_buffer = _buffer.substr(nl + 1)
				var data: Variant = JSON.parse_string(line)
				return data if typeof(data) == TYPE_DICTIONARY else {"ok": false, "error": "bad reply"}
		await get_tree().process_frame
	return {}


## Server state JSON (docs/JSON_FORMAT.md section 3) -> GUI state dictionary.
static func state_from_json(j: Variant) -> Variant:
	if j == null:
		return null
	var open := {}
	for b in j.get("open_bridges", []):
		open[str(b)] = true
	if j.get("mode", "whole") == "split":
		var cubes: Array = [LevelData._cell(j["cubes"][0]), LevelData._cell(j["cubes"][1])]
		return {"pos": cubes[0], "orient": "SPLIT", "open": open, "cubes": cubes, "active": int(j.get("active", 0))}
	return {"pos": LevelData._cell(j["pos"]), "orient": str(j["orient"]), "open": open}
