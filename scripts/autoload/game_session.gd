extends Node

const VIEW_SIZE := Vector2(960.0, 540.0)
const PLAYER_BOUNDS := Rect2(22.0, 70.0, VIEW_SIZE.x - 44.0, VIEW_SIZE.y - 118.0)
const COLOR_BG := Color(0.03, 0.06, 0.03, 1.0)
const COLOR_GRID := Color(0.09, 0.18, 0.09, 1.0)
const COLOR_DIM := Color(0.23, 0.42, 0.23, 1.0)
const COLOR_FG := Color(0.62, 0.92, 0.56, 1.0)
const COLOR_ALERT := Color(0.95, 0.96, 0.58, 1.0)
const COLOR_HIT := Color(1.0, 1.0, 1.0, 1.0)
const PROFILE_PATH := "user://profile.cfg"

var high_score := 0
var total_runs := 0

var last_result := {
	"victory": false,
	"score": 0,
	"time": 0.0,
	"weapon_level": 1,
	"lives_left": 0,
	"stages_cleared": 0,
	"stage_reached": 1,
	"best_score": 0,
	"new_record": false,
}


func _ready() -> void:
	_configure_input_map()
	_load_profile()


func _configure_input_map() -> void:
	_bind_action("move_up", [KEY_W, KEY_UP])
	_bind_action("move_down", [KEY_S, KEY_DOWN])
	_bind_action("move_left", [KEY_A, KEY_LEFT])
	_bind_action("move_right", [KEY_D, KEY_RIGHT])
	_bind_action("fire", [KEY_SPACE, KEY_Z])
	_bind_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_bind_action("back", [KEY_ESCAPE, KEY_X])
	_bind_action("pause", [KEY_P, KEY_ESCAPE])


func _bind_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, event)
	for keycode in keys:
		var input_event := InputEventKey.new()
		input_event.keycode = keycode
		input_event.physical_keycode = keycode
		InputMap.action_add_event(action_name, input_event)


func save_result(victory: bool, score: int, elapsed: float, weapon_level: int, lives_left: int, stages_cleared: int, stage_reached: int) -> void:
	total_runs += 1
	var new_record := score > high_score
	if new_record:
		high_score = score
	_save_profile()
	last_result = {
		"victory": victory,
		"score": score,
		"time": elapsed,
		"weapon_level": weapon_level,
		"lives_left": lives_left,
		"stages_cleared": stages_cleared,
		"stage_reached": stage_reached,
		"best_score": high_score,
		"new_record": new_record,
	}


func weapon_label(level: int) -> String:
	match clamp(level, 1, 3):
		1:
			return "PULSE"
		2:
			return "DOUBLE"
		3:
			return "SPREAD"
	return "PULSE"


func _load_profile() -> void:
	var config := ConfigFile.new()
	var error := config.load(PROFILE_PATH)
	if error != OK:
		return
	high_score = int(config.get_value("profile", "high_score", 0))
	total_runs = int(config.get_value("profile", "total_runs", 0))


func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "high_score", high_score)
	config.set_value("profile", "total_runs", total_runs)
	config.save(PROFILE_PATH)
