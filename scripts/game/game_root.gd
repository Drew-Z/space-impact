extends Node2D

const STARFIELD_SCENE := preload("res://scenes/game/starfield.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player_ship.tscn")
const ENEMY_SCENE := preload("res://scenes/entities/enemy_ship.tscn")
const BOSS_SCENE := preload("res://scenes/entities/boss_stage_1.tscn")
const BULLET_SCENE := preload("res://scenes/entities/bullet.tscn")
const POWERUP_SCENE := preload("res://scenes/entities/powerup_pickup.tscn")
const FEEDBACK_BURST_SCENE := preload("res://scenes/game/feedback_burst.tscn")

var _hud: CanvasLayer
var _starfield: Node2D
var _player: Area2D
var _boss: Area2D
var _player_beam: Area2D
var _elapsed := 0.0
var _score := 0
var _phase_text := "SECTOR 1"
var _spawn_schedule: Array = []
var _spawn_index := 0
var _boss_pending := false
var _boss_hull := 0
var _boss_max_hull := 0
var _boss_config: Dictionary = {}
var _finished := false
var _player_hull := 3
var _player_max_hull := 3
var _player_lives := 1
var _player_weapon := 1
var _player_status := ""
var _stages: Array = []
var _stage_index := 0
var _stage_elapsed := 0.0
var _pending_stage_index := -1
var _stage_transition_timer := 0.0
var _stages_cleared := 0
var _stage_name := "SECTOR 1"
var _is_paused := false
var _shot_sfx_timer := 0.0
var _beam_sfx_timer := 0.0
var _kills_since_weapon_drop := 0
var _random_drop_cooldown := 0.0
var _boss_warning_active := false
var _boss_frenzy_announced := false
var _boss_support_timer := 0.0
var _boss_support_wave_index := 0
var _boss_phase_alert_step := 0
var _final_boss_alert_step := 0
var _boss_alarm_bursts_left := 0
var _boss_alarm_timer := 0.0
var _ending_victory := false
var _ending_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioDirector.set_music_mode("combat")
	_stages = _build_stages()
	_starfield = STARFIELD_SCENE.instantiate()
	_mark_gameplay_node(_starfield)
	add_child(_starfield)
	_hud = HUD_SCENE.instantiate()
	_hud.resume_requested.connect(_resume_run)
	_hud.restart_requested.connect(_restart_run)
	_hud.menu_requested.connect(_return_to_menu)
	add_child(_hud)
	_player = PLAYER_SCENE.instantiate()
	_mark_gameplay_node(_player)
	_player.position = Vector2(120.0, GameSession.VIEW_SIZE.y * 0.5)
	_player.shoot_requested.connect(_spawn_player_shots)
	_player.beam_updated.connect(_on_player_beam_updated)
	_player.beam_released.connect(_clear_player_beam)
	_player.state_changed.connect(_on_player_state_changed)
	_player.defeated.connect(_on_player_defeated)
	_player.feedback_requested.connect(_on_player_feedback_requested)
	add_child(_player)
	var start_phase_index := clampi(GameSession.consume_pending_start_phase() - 1, 0, _stages.size() - 1)
	var start_weapon_level := GameSession.consume_pending_start_weapon()
	if _player.has_method("set_start_loadout"):
		_player.set_start_loadout(start_weapon_level)
	_load_stage(start_phase_index)
	_hud.show_center_message("%s START" % _stage_name, 1.6)
	_hud.show_notice(GameSession.loc("run_intro"), 2.5)


func _process(delta: float) -> void:
	if _finished:
		return
	if _is_paused:
		_sync_hud()
		return
	if _ending_timer > 0.0:
		_ending_timer = max(_ending_timer - delta, 0.0)
		if _ending_timer == 0.0:
			_finish_run(_ending_victory)
		_sync_hud()
		return
	_shot_sfx_timer = max(_shot_sfx_timer - delta, 0.0)
	_beam_sfx_timer = max(_beam_sfx_timer - delta, 0.0)
	if _boss_alarm_bursts_left > 0:
		_boss_alarm_timer = max(_boss_alarm_timer - delta, 0.0)
		if _boss_alarm_timer == 0.0:
			AudioDirector.play_sfx("boss_alarm")
			_boss_alarm_bursts_left -= 1
			_boss_alarm_timer = 0.34
	_random_drop_cooldown = max(_random_drop_cooldown - delta, 0.0)
	_elapsed += delta

	if _stage_transition_timer > 0.0:
		_stage_transition_timer = max(_stage_transition_timer - delta, 0.0)
		if _stage_transition_timer == 0.0 and _pending_stage_index >= 0:
			_load_stage(_pending_stage_index)
		_update_phase_text()
		_sync_hud()
		return

	_stage_elapsed += delta
	_process_schedule()
	if _boss_pending and not is_instance_valid(_boss) and get_tree().get_nodes_in_group("enemy_ship").is_empty():
		_spawn_boss()
		_boss_pending = false
	if is_instance_valid(_boss):
		_process_boss_support(delta)
	_update_phase_text()
	_sync_hud()
	

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("pause"):
		if _is_paused:
			_resume_run()
		else:
			_pause_run()


func _sync_hud() -> void:
	_hud.update_player(_score, _player_hull, _player_max_hull, _player_lives, _player_weapon, _phase_text, _player_status)
	_hud.update_stage(_stage_index + 1, _stages.size(), _stage_progress())
	_hud.update_boss(is_instance_valid(_boss), _boss_hull, _boss_max_hull)


func _process_schedule() -> void:
	while _spawn_index < _spawn_schedule.size() and _stage_elapsed >= float(_spawn_schedule[_spawn_index]["time"]):
		var event: Dictionary = _spawn_schedule[_spawn_index]
		match String(event["kind"]):
			"burst":
				_spawn_burst(event)
			"powerup":
				_spawn_powerup(event)
			"boss":
				_boss_pending = true
				if not _boss_warning_active:
					_trigger_boss_warning()
		_spawn_index += 1


func _build_stages() -> Array:
	var sector_1_schedule := _build_sector_1_schedule()
	var sector_2_schedule := _build_sector_2_schedule()
	var sector_3_schedule := _build_sector_3_schedule()
	var sector_4_schedule := _build_sector_4_schedule()
	var sector_5_schedule := _build_sector_5_schedule()
	var final_schedule := _build_final_schedule()
	return [
		{
			"name": "SECTOR 1",
			"schedule": sector_1_schedule,
			"background": _stage_background(
				Color(0.03, 0.06, 0.03, 1.0),
				Color(0.12, 0.18, 0.10, 0.26),
				GameSession.COLOR_FG,
				44,
				18,
				90
			),
			"boss": {
				"profile": "striker",
				"max_hull": 96,
				"move_amplitude": 118.0,
				"move_speed": 1.9,
				"fire_cooldown": 1.0,
				"enrage_ratio": 0.34,
				"score_value": 2200,
				"support_interval": 7.6,
				"support_pattern": ["straight", "dart", "straight", "dart"],
				"support_lanes": [138.0, 270.0, 402.0],
				"support_count": 2,
				"support_cap": 2,
			},
		},
		{
			"name": "SECTOR 2",
			"schedule": sector_2_schedule,
			"background": _stage_background(
				Color(0.03, 0.05, 0.07, 1.0),
				Color(0.10, 0.16, 0.20, 0.24),
				Color(0.72, 0.92, 0.82, 1.0),
				52,
				16,
				84,
				Color(0.10, 0.18, 0.20, 0.12),
				120.0,
				148.0
			),
			"boss": {
				"profile": "carrier",
				"max_hull": 128,
				"move_amplitude": 78.0,
				"move_speed": 1.1,
				"entry_speed": 100.0,
				"fire_cooldown": 0.98,
				"enrage_ratio": 0.38,
				"enrage_fire_multiplier": 0.7,
				"score_value": 3600,
				"target_x": 748.0,
				"support_interval": 6.8,
				"support_pattern": ["wave", "dart", "wave", "dart"],
				"support_lanes": [126.0, 210.0, 330.0, 414.0],
				"support_count": 2,
				"support_cap": 2,
			},
		},
		{
			"name": "SECTOR 3",
			"schedule": sector_3_schedule,
			"background": _stage_background(
				Color(0.05, 0.04, 0.07, 1.0),
				Color(0.16, 0.12, 0.20, 0.26),
				Color(0.82, 0.82, 0.96, 1.0),
				48,
				17,
				96,
				Color(0.18, 0.10, 0.24, 0.16),
				94.0,
				218.0
			),
			"boss": {
				"profile": "fortress",
				"max_hull": 176,
				"move_amplitude": 64.0,
				"move_speed": 0.82,
				"entry_speed": 92.0,
				"fire_cooldown": 0.9,
				"enrage_ratio": 0.42,
				"enrage_fire_multiplier": 0.72,
				"score_value": 4800,
				"target_x": 724.0,
				"support_interval": 5.8,
				"support_pattern": ["sentinel", "spinner", "tank", "spinner"],
				"support_lanes": [118.0, 206.0, 334.0, 422.0],
				"support_count": 2,
				"support_cap": 3,
			},
		},
		{
			"name": "SECTOR 4",
			"schedule": sector_4_schedule,
			"background": _stage_background(
				Color(0.07, 0.04, 0.04, 1.0),
				Color(0.22, 0.12, 0.12, 0.26),
				Color(0.96, 0.84, 0.76, 1.0),
				56,
				15,
				74,
				Color(0.30, 0.12, 0.10, 0.14),
				86.0,
				170.0
			),
			"boss": {
				"profile": "reaper",
				"max_hull": 208,
				"move_amplitude": 126.0,
				"move_speed": 1.86,
				"entry_speed": 126.0,
				"fire_cooldown": 0.8,
				"enrage_ratio": 0.38,
				"enrage_fire_multiplier": 0.62,
				"enrage_move_bonus": 0.4,
				"score_value": 6800,
				"target_x": 756.0,
				"support_interval": 4.8,
				"support_pattern": ["dart", "spinner", "dart", "spinner"],
				"support_lanes": [132.0, 246.0, 360.0],
				"support_count": 2,
				"support_cap": 4,
			},
		},
		{
			"name": "SECTOR 5",
			"schedule": sector_5_schedule,
			"background": _stage_background(
				Color(0.05, 0.05, 0.02, 1.0),
				Color(0.20, 0.20, 0.10, 0.28),
				Color(0.90, 0.94, 0.70, 1.0),
				58,
				14,
				70,
				Color(0.24, 0.22, 0.08, 0.16),
				110.0,
				126.0
			),
			"boss": {
				"profile": "bastion",
				"max_hull": 260,
				"move_amplitude": 86.0,
				"move_speed": 0.94,
				"entry_speed": 96.0,
				"fire_cooldown": 0.76,
				"enrage_ratio": 0.4,
				"enrage_fire_multiplier": 0.66,
				"score_value": 8400,
				"target_x": 728.0,
				"support_interval": 4.4,
				"support_pattern": ["sentinel", "tank", "spinner", "tank"],
				"support_lanes": [124.0, 214.0, 326.0, 416.0],
				"support_count": 2,
				"support_cap": 4,
			},
		},
		{
			"name": "FINAL CORE",
			"schedule": final_schedule,
			"background": _stage_background(
				Color(0.08, 0.02, 0.02, 1.0),
				Color(0.26, 0.10, 0.10, 0.32),
				Color(1.0, 0.90, 0.74, 1.0),
				64,
				13,
				64,
				Color(0.36, 0.08, 0.08, 0.22),
				138.0,
				186.0
			),
			"boss": {
				"profile": "overlord",
				"max_hull": 408,
				"move_amplitude": 136.0,
				"move_speed": 1.08,
				"entry_speed": 88.0,
				"fire_cooldown": 0.58,
				"enrage_ratio": 0.46,
				"enrage_fire_multiplier": 0.55,
				"enrage_move_bonus": 0.24,
				"score_value": 18000,
				"target_x": 700.0,
				"support_interval": 3.5,
				"support_pattern": ["dart", "spinner", "sentinel", "dart", "sentinel"],
				"support_lanes": [118.0, 190.0, 270.0, 350.0, 422.0],
				"support_count": 3,
				"support_cap": 5,
				"critical_ratio": 0.22,
				"critical_fire_multiplier": 0.54,
				"critical_move_bonus": 0.6,
				"critical_amplitude_bonus": 28.0,
			},
		},
	]


func _stage_background(
	background: Color,
	grid: Color,
	star: Color,
	stars: int,
	scanline_step: int,
	column_step: int,
	band_color: Color = Color(0.0, 0.0, 0.0, 0.0),
	band_height: float = 0.0,
	band_y: float = 0.0
) -> Dictionary:
	return {
		"background": background,
		"frame": Color(background.r * 0.8, background.g * 0.9, background.b * 0.8, 0.4),
		"grid": grid,
		"border_top": star,
		"border_bottom": grid,
		"column": Color(grid.r, grid.g, grid.b, 0.34),
		"star": star,
		"stars": stars,
		"scanline_step": scanline_step,
		"column_step": column_step,
		"band_color": band_color,
		"band_height": band_height,
		"band_y": band_y,
	}


func _build_sector_1_schedule() -> Array:
	var schedule: Array = []
	schedule.append(_burst_event(1.0, "straight", [112.0, 188.0, 264.0, 340.0], {"x_spacing": 58.0}))
	schedule.append_array(_staggered_bursts(4.4, "straight", [108.0, 392.0, 148.0, 352.0, 188.0, 312.0], 0.42, {
		"overrides": {"speed": 246.0},
	}))
	schedule.append(_burst_event(8.1, "wave", [138.0, 218.0, 298.0, 378.0], {"x_spacing": 66.0}))
	schedule.append_array(_staggered_bursts(11.8, "dart", [122.0, 404.0, 168.0, 358.0], 0.38, {
		"overrides": {"shoot_interval": 1.9},
	}))
	schedule.append(_burst_event(15.7, "tank", [166.0, 336.0], {
		"x_spacing": 102.0,
		"overrides": {"health": 4},
	}))
	schedule.append(_burst_event(17.0, "straight", [124.0, 210.0, 296.0, 382.0], {
		"x_spacing": 66.0,
		"overrides": {"speed": 258.0},
	}))
	schedule.append(_powerup_event(20.2, "weapon", 254.0))
	schedule.append(_powerup_event(30.2, "overdrive", 196.0))
	schedule.append_array(_staggered_bursts(23.2, "wave", [118.0, 194.0, 270.0, 346.0, 422.0], 0.34, {
		"overrides": {"speed": 224.0},
	}))
	schedule.append(_powerup_event(34.8, "weapon", 312.0))
	schedule.append(_burst_event(27.6, "dart", [124.0, 240.0, 356.0], {
		"x_spacing": 80.0,
		"overrides": {"shoot_interval": 1.72},
	}))
	schedule.append(_burst_event(31.2, "straight", [148.0, 230.0, 312.0, 394.0], {
		"x_spacing": 60.0,
		"overrides": {"speed": 266.0},
	}))
	schedule.append(_burst_event(34.6, "tank", [138.0, 270.0, 402.0], {
		"x_spacing": 84.0,
		"overrides": {"health": 4, "shoot_interval": 1.58},
	}))
	schedule.append(_boss_event(38.8))
	return schedule


func _build_sector_2_schedule() -> Array:
	var schedule: Array = []
	schedule.append_array(_staggered_bursts(1.2, "straight", [106.0, 434.0, 154.0, 386.0, 202.0, 338.0, 250.0, 290.0], 0.28, {
		"overrides": {"speed": 264.0},
	}))
	schedule.append(_burst_event(5.2, "wave", [126.0, 186.0, 246.0, 306.0, 366.0, 426.0], {
		"x_spacing": 48.0,
		"overrides": {"speed": 238.0},
	}))
	schedule.append(_powerup_event(8.6, "overdrive", 300.0))
	schedule.append_array(_staggered_bursts(10.2, "dart", [124.0, 248.0, 372.0, 186.0, 310.0], 0.24, {
		"overrides": {"shoot_interval": 1.48},
	}))
	schedule.append(_burst_event(14.0, "tank", [142.0, 270.0, 398.0], {
		"x_spacing": 82.0,
		"overrides": {"health": 5, "shoot_interval": 1.4},
	}))
	schedule.append(_burst_event(18.2, "wave", [152.0, 248.0, 344.0], {
		"x_spacing": 88.0,
		"overrides": {"health": 3, "speed": 232.0},
	}))
	schedule.append(_powerup_event(23.6, "weapon", 240.0))
	schedule.append_array(_staggered_bursts(21.6, "straight", [118.0, 422.0, 162.0, 378.0, 206.0, 334.0], 0.26, {
		"overrides": {"speed": 276.0},
	}))
	schedule.append(_burst_event(25.2, "dart", [114.0, 174.0, 366.0, 426.0], {
		"x_spacing": 62.0,
		"overrides": {"shoot_interval": 1.24},
	}))
	schedule.append(_powerup_event(31.2, "overdrive", 214.0))
	schedule.append(_burst_event(30.0, "tank", [120.0, 220.0, 320.0, 420.0], {
		"x_spacing": 66.0,
		"overrides": {"health": 5, "shoot_interval": 1.22},
	}))
	schedule.append(_powerup_event(37.8, "weapon", 374.0))
	schedule.append(_burst_event(35.0, "wave", [138.0, 210.0, 282.0, 354.0, 426.0], {
		"x_spacing": 52.0,
		"overrides": {"health": 3, "speed": 236.0},
	}))
	schedule.append_array(_staggered_bursts(39.0, "dart", [116.0, 424.0, 164.0, 376.0, 212.0, 328.0], 0.22, {
		"overrides": {"shoot_interval": 1.14},
	}))
	schedule.append(_boss_event(44.8))
	return schedule


func _build_sector_3_schedule() -> Array:
	var schedule: Array = []
	schedule.append_array(_staggered_bursts(1.0, "spinner", [120.0, 420.0, 168.0, 372.0], 0.32, {
		"overrides": {"shoot_interval": 1.4},
	}))
	schedule.append(_powerup_event(9.0, "weapon", 268.0))
	schedule.append(_burst_event(6.2, "sentinel", [146.0, 268.0, 390.0], {
		"x_spacing": 86.0,
		"overrides": {"shoot_interval": 1.52},
	}))
	schedule.append_array(_staggered_bursts(10.4, "dart", [118.0, 202.0, 338.0, 422.0], 0.24, {
		"overrides": {"shoot_interval": 1.18},
	}))
	schedule.append(_powerup_event(20.4, "overdrive", 194.0))
	schedule.append(_burst_event(15.4, "tank", [140.0, 270.0, 400.0], {
		"x_spacing": 78.0,
		"overrides": {"health": 6, "shoot_interval": 1.3},
	}))
	schedule.append(_burst_event(19.2, "spinner", [150.0, 250.0, 350.0], {
		"x_spacing": 74.0,
		"overrides": {"shoot_interval": 1.12},
	}))
	schedule.append(_burst_event(24.2, "wave", [132.0, 192.0, 252.0, 312.0, 372.0, 432.0], {
		"x_spacing": 46.0,
		"overrides": {"health": 3, "speed": 242.0},
	}))
	schedule.append(_burst_event(29.0, "sentinel", [118.0, 220.0, 322.0, 424.0], {
		"x_spacing": 70.0,
		"overrides": {"health": 4, "shoot_interval": 1.18},
	}))
	schedule.append(_powerup_event(33.8, "overdrive", 360.0))
	schedule.append_array(_staggered_bursts(34.2, "spinner", [110.0, 430.0, 160.0, 380.0, 210.0, 330.0], 0.22, {
		"overrides": {"shoot_interval": 0.98},
	}))
	schedule.append(_boss_event(43.2))
	return schedule


func _build_sector_4_schedule() -> Array:
	var schedule: Array = []
	schedule.append(_burst_event(1.0, "sentinel", [124.0, 214.0, 304.0, 394.0], {
		"x_spacing": 68.0,
		"overrides": {"health": 4, "shoot_interval": 1.14},
	}))
	schedule.append_array(_staggered_bursts(4.0, "dart", [116.0, 426.0, 160.0, 382.0, 204.0, 338.0], 0.18, {
		"overrides": {"shoot_interval": 1.02},
	}))
	schedule.append(_powerup_event(11.0, "weapon", 210.0))
	schedule.append(_burst_event(9.6, "spinner", [142.0, 232.0, 322.0, 412.0], {
		"x_spacing": 62.0,
		"overrides": {"shoot_interval": 0.96},
	}))
	schedule.append(_burst_event(13.8, "tank", [136.0, 232.0, 328.0, 424.0], {
		"x_spacing": 70.0,
		"overrides": {"health": 6, "shoot_interval": 1.14},
	}))
	schedule.append(_powerup_event(24.8, "weapon", 286.0))
	schedule.append(_burst_event(18.4, "wave", [126.0, 178.0, 230.0, 282.0, 334.0, 386.0, 438.0], {
		"x_spacing": 42.0,
		"overrides": {"health": 3, "speed": 248.0},
	}))
	schedule.append(_burst_event(24.2, "sentinel", [120.0, 188.0, 256.0, 324.0, 392.0], {
		"x_spacing": 54.0,
		"overrides": {"health": 4, "shoot_interval": 1.02},
	}))
	schedule.append_array(_staggered_bursts(28.2, "spinner", [112.0, 428.0, 164.0, 376.0, 216.0, 324.0], 0.18, {
		"overrides": {"shoot_interval": 0.84},
	}))
	schedule.append(_powerup_event(35.4, "overdrive", 178.0))
	schedule.append(_burst_event(33.0, "tank", [150.0, 270.0, 390.0], {
		"x_spacing": 82.0,
		"overrides": {"health": 7, "shoot_interval": 1.02},
	}))
	schedule.append(_burst_event(38.0, "dart", [122.0, 202.0, 282.0, 362.0, 442.0], {
		"x_spacing": 58.0,
		"overrides": {"shoot_interval": 0.92},
	}))
	schedule.append(_powerup_event(42.2, "overdrive", 320.0))
	schedule.append(_boss_event(46.8))
	return schedule


func _build_sector_5_schedule() -> Array:
	var schedule: Array = []
	schedule.append_array(_staggered_bursts(1.0, "sentinel", [116.0, 424.0, 164.0, 376.0, 212.0, 328.0], 0.2, {
		"overrides": {"health": 4, "shoot_interval": 1.0},
	}))
	schedule.append(_burst_event(5.4, "spinner", [130.0, 206.0, 282.0, 358.0, 434.0], {
		"x_spacing": 52.0,
		"overrides": {"shoot_interval": 0.94},
	}))
	schedule.append(_powerup_event(12.2, "weapon", 250.0))
	schedule.append(_burst_event(14.0, "tank", [132.0, 224.0, 316.0, 408.0], {
		"x_spacing": 66.0,
		"overrides": {"health": 7, "shoot_interval": 0.98},
	}))
	schedule.append_array(_staggered_bursts(19.4, "dart", [118.0, 422.0, 174.0, 366.0, 230.0, 310.0], 0.18, {
		"overrides": {"shoot_interval": 0.84},
	}))
	schedule.append(_powerup_event(24.8, "overdrive", 178.0))
	schedule.append(_burst_event(27.4, "sentinel", [136.0, 228.0, 320.0, 412.0], {
		"x_spacing": 58.0,
		"overrides": {"health": 5, "shoot_interval": 0.92},
	}))
	schedule.append(_burst_event(32.6, "wave", [124.0, 176.0, 228.0, 280.0, 332.0, 384.0, 436.0], {
		"x_spacing": 40.0,
		"overrides": {"health": 3, "speed": 252.0},
	}))
	schedule.append(_powerup_event(37.0, "weapon", 302.0))
	schedule.append_array(_staggered_bursts(39.2, "spinner", [120.0, 420.0, 170.0, 370.0, 220.0, 320.0], 0.16, {
		"overrides": {"shoot_interval": 0.8},
	}))
	schedule.append(_burst_event(44.4, "tank", [152.0, 270.0, 388.0], {
		"x_spacing": 84.0,
		"overrides": {"health": 8, "shoot_interval": 0.92},
	}))
	schedule.append(_boss_event(52.0))
	return schedule


func _build_final_schedule() -> Array:
	return [
		_powerup_event(1.4, "overdrive", 270.0),
		_boss_event(3.4),
	]


func _burst_event(time: float, enemy_type: String, lanes: Array, extra: Dictionary = {}) -> Dictionary:
	var event: Dictionary = {
		"time": time,
		"kind": "burst",
		"enemy_type": enemy_type,
		"lanes": lanes.duplicate(),
	}
	for key in extra.keys():
		event[key] = extra[key]
	return event


func _powerup_event(time: float, kind_name: String, y: float) -> Dictionary:
	return {
		"time": time,
		"kind": "powerup",
		"kind_name": kind_name,
		"position": Vector2(GameSession.VIEW_SIZE.x + 30.0, y),
	}


func _boss_event(time: float) -> Dictionary:
	return {
		"time": time,
		"kind": "boss",
	}


func _staggered_bursts(start_time: float, enemy_type: String, lanes: Array, step: float, extra: Dictionary = {}) -> Array:
	var events: Array = []
	for index in range(lanes.size()):
		var event_extra := extra.duplicate(true)
		if event_extra.has("lanes"):
			event_extra.erase("lanes")
		events.append(_burst_event(start_time + float(index) * step, enemy_type, [float(lanes[index])], event_extra))
	return events


func _load_stage(index: int) -> void:
	_clear_stage_objects()
	_stage_index = index
	_pending_stage_index = -1
	_stage_elapsed = 0.0
	_spawn_index = 0
	_boss_pending = false
	_boss_hull = 0
	_boss_max_hull = 0
	_boss = null
	_boss_warning_active = false
	_boss_frenzy_announced = false
	_boss_support_timer = 0.0
	_boss_support_wave_index = 0
	_boss_phase_alert_step = 0
	_final_boss_alert_step = 0
	_boss_alarm_bursts_left = 0
	_boss_alarm_timer = 0.0
	_ending_victory = false
	_ending_timer = 0.0
	var stage: Dictionary = _stages[index]
	_stage_name = String(stage["name"])
	_spawn_schedule = stage["schedule"]
	_boss_config = stage["boss"]
	if is_instance_valid(_starfield) and _starfield.has_method("setup_theme"):
		_starfield.setup_theme(stage.get("background", {}))
	_hud.show_center_message("%s START" % _stage_name, 1.5)
	AudioDirector.play_sfx("clear")


func _spawn_burst(event: Dictionary) -> void:
	var lanes: Array = event.get("lanes", [])
	var x_spacing := float(event.get("x_spacing", 74.0))
	if lanes.is_empty():
		for row in range(int(event.get("count", 0))):
			lanes.append(float(event.get("start_y", 120.0)) + float(row) * float(event.get("spacing", 70.0)))
	for index in range(lanes.size()):
		var enemy := ENEMY_SCENE.instantiate()
		_mark_gameplay_node(enemy)
		var spawn_position := Vector2(
			GameSession.VIEW_SIZE.x + 70.0 + float(index) * x_spacing,
			clamp(float(lanes[index]), 86.0, GameSession.VIEW_SIZE.y - 86.0)
		)
		enemy.position = spawn_position
		enemy.setup(_enemy_config(String(event["enemy_type"]), spawn_position.y, event.get("overrides", {})))
		enemy.destroyed.connect(_on_enemy_destroyed)
		enemy.damaged.connect(_on_enemy_damaged)
		enemy.fire_requested.connect(_spawn_enemy_shots)
		add_child(enemy)


func _enemy_config(enemy_type: String, base_y: float, overrides: Dictionary = {}) -> Dictionary:
	var config: Dictionary
	match enemy_type:
		"wave":
			config = {
				"enemy_type": "wave",
				"speed": 218.0,
				"health": 2,
				"amplitude": 34.0,
				"frequency": 3.8,
				"base_y": base_y,
				"score_value": 140,
				"tint": GameSession.COLOR_FG,
			}
		"tank":
			config = {
				"enemy_type": "tank",
				"speed": 154.0,
				"health": 5,
				"amplitude": 24.0,
				"frequency": 2.2,
				"base_y": base_y,
				"score_value": 260,
				"shoot_interval": 1.7,
				"shot_mode": "single",
				"tint": GameSession.COLOR_ALERT,
			}
		"spinner":
			config = {
				"enemy_type": "spinner",
				"speed": 208.0,
				"health": 3,
				"amplitude": 46.0,
				"frequency": 4.8,
				"base_y": base_y,
				"score_value": 220,
				"shoot_interval": 1.32,
				"shot_mode": "spread",
				"tint": GameSession.COLOR_ALERT,
			}
		"sentinel":
			config = {
				"enemy_type": "sentinel",
				"speed": 174.0,
				"health": 4,
				"amplitude": 18.0,
				"frequency": 2.6,
				"base_y": base_y,
				"score_value": 240,
				"shoot_interval": 1.45,
				"shot_mode": "aimed",
				"tint": GameSession.COLOR_FG,
			}
		"dart":
			var drift := -1.0 if base_y > GameSession.VIEW_SIZE.y * 0.5 else 1.0
			config = {
				"enemy_type": "dart",
				"speed": 270.0,
				"health": 2,
				"base_y": base_y,
				"score_value": 170,
				"shoot_interval": 0.0,
				"shot_mode": "dart",
				"vertical_speed": 118.0,
				"drift_direction": drift,
				"tint": GameSession.COLOR_HIT,
			}
		_:
			config = {
				"enemy_type": "straight",
				"speed": 252.0,
				"health": 2,
				"base_y": base_y,
				"score_value": 110,
				"tint": GameSession.COLOR_DIM,
			}
	for key in overrides.keys():
		config[key] = overrides[key]
	return config


func _spawn_powerup(event: Dictionary) -> void:
	var pickup := POWERUP_SCENE.instantiate()
	_mark_gameplay_node(pickup)
	pickup.position = event.get("position", Vector2(GameSession.VIEW_SIZE.x + 30.0, GameSession.VIEW_SIZE.y * 0.5))
	pickup.setup({
		"kind": String(event.get("kind_name", "weapon")),
	})
	add_child(pickup)


func _spawn_boss() -> void:
	_boss = BOSS_SCENE.instantiate()
	_mark_gameplay_node(_boss)
	_boss.setup(_boss_config)
	_boss.position = Vector2(GameSession.VIEW_SIZE.x + 80.0, GameSession.VIEW_SIZE.y * 0.5)
	_boss.destroyed.connect(_on_boss_destroyed)
	_boss.fire_requested.connect(_spawn_boss_shots)
	_boss.hull_changed.connect(_on_boss_hull_changed)
	_boss.damaged.connect(_on_boss_damaged)
	add_child(_boss)
	_hud.show_center_message(GameSession.loc("stage_boss", [_stage_name]), 1.4)
	_boss_warning_active = false
	_boss_support_timer = float(_boss_config.get("support_interval", 0.0))
	_boss_support_wave_index = 0
	_boss_phase_alert_step = 0


func _spawn_player_shots(shots: Array) -> void:
	for shot in shots:
		var bullet := BULLET_SCENE.instantiate()
		_mark_gameplay_node(bullet)
		if shot.has("visual_size"):
			bullet.player_visual_size = shot["visual_size"]
		if shot.has("core_size"):
			bullet.player_core_size = shot["core_size"]
		if shot.has("trail_length"):
			bullet.player_trail_length = float(shot["trail_length"])
		if shot.has("beam_mode"):
			bullet.player_beam = bool(shot["beam_mode"])
		if shot.has("life_time"):
			bullet.life_time = float(shot["life_time"])
		if shot.has("tick_interval"):
			bullet.beam_tick_interval = float(shot["tick_interval"])
		bullet.setup(shot["position"], shot["direction"], float(shot["speed"]), int(shot["damage"]), true)
		if bullet.has_method("refresh_player_visual"):
			bullet.refresh_player_visual(
				bullet.player_visual_size,
				bullet.player_core_size,
				bullet.player_trail_length,
				bullet.player_beam,
				bullet.beam_tick_interval
			)
		add_child(bullet)
	if _shot_sfx_timer <= 0.0:
		_shot_sfx_timer = 0.11
		AudioDirector.play_sfx("shoot")


func _spawn_enemy_shots(shots: Array) -> void:
	for shot in shots:
		var bullet := BULLET_SCENE.instantiate()
		_mark_gameplay_node(bullet)
		bullet.setup(shot["position"], shot["direction"], float(shot["speed"]), int(shot["damage"]), false)
		add_child(bullet)


func _spawn_boss_shots(shots: Array) -> void:
	_spawn_enemy_shots(shots)
	AudioDirector.play_sfx("boss_fire")


func _on_player_beam_updated(beam_data: Dictionary) -> void:
	if not is_instance_valid(_player_beam):
		_player_beam = BULLET_SCENE.instantiate()
		_mark_gameplay_node(_player_beam)
		_player_beam.player_beam = true
		_player_beam.setup(beam_data["position"], Vector2.ZERO, 0.0, int(beam_data["damage"]), true)
		add_child(_player_beam)
	if _beam_sfx_timer <= 0.0:
		_beam_sfx_timer = 0.14
		AudioDirector.play_sfx("beam")
	_update_player_beam(beam_data)


func _update_player_beam(beam_data: Dictionary) -> void:
	if not is_instance_valid(_player_beam):
		return
	_player_beam.global_position = beam_data["position"]
	_player_beam.damage = int(beam_data["damage"])
	_player_beam.life_time = -1.0
	if _player_beam.has_method("refresh_player_visual"):
		_player_beam.refresh_player_visual(
			beam_data["visual_size"],
			beam_data["core_size"],
			float(beam_data.get("trail_length", 0.0)),
			true,
			float(beam_data.get("tick_interval", 0.12))
		)


func _clear_player_beam() -> void:
	if not is_instance_valid(_player_beam):
		return
	_player_beam.queue_free()
	_player_beam = null
	_beam_sfx_timer = 0.0


func _process_boss_support(delta: float) -> void:
	if _boss_config.is_empty():
		return
	var support_interval := float(_boss_config.get("support_interval", 0.0))
	if support_interval <= 0.0:
		return
	_boss_support_timer -= delta
	if _boss_support_timer > 0.0:
		return
	_boss_support_timer = support_interval
	_spawn_boss_support()


func _spawn_boss_support() -> void:
	var cap := int(_boss_config.get("support_cap", 3))
	if get_tree().get_nodes_in_group("enemy_ship").size() >= cap:
		return
	var support_pattern: Array = _boss_config.get("support_pattern", ["straight"])
	if support_pattern.is_empty():
		return
	var support_lanes: Array = _boss_config.get("support_lanes", [120.0, 210.0, 300.0, 390.0])
	if support_lanes.is_empty():
		return
	var count := int(_boss_config.get("support_count", 1))
	for support_index in range(count):
		if get_tree().get_nodes_in_group("enemy_ship").size() >= cap:
			return
		var pattern_index := (_boss_support_wave_index + support_index) % support_pattern.size()
		var lane_index := (_boss_support_wave_index + support_index) % support_lanes.size()
		var type_name := String(support_pattern[pattern_index])
		var spawn_y := float(support_lanes[lane_index])
		var overrides := _boss_support_overrides(type_name)
		var enemy := ENEMY_SCENE.instantiate()
		_mark_gameplay_node(enemy)
		enemy.position = Vector2(GameSession.VIEW_SIZE.x + 48.0 + float(support_index) * 28.0, spawn_y)
		enemy.setup(_enemy_config(type_name, spawn_y, overrides))
		enemy.destroyed.connect(_on_enemy_destroyed)
		enemy.damaged.connect(_on_enemy_damaged)
		enemy.fire_requested.connect(_spawn_enemy_shots)
		add_child(enemy)
	_boss_support_wave_index += count


func _boss_support_overrides(enemy_type: String) -> Dictionary:
	match enemy_type:
		"tank":
			return {"health": 1, "shoot_interval": 1.28, "speed": 184.0}
		"spinner":
			return {"health": 1, "shoot_interval": 1.08, "speed": 230.0}
		"sentinel":
			return {"health": 1, "shoot_interval": 1.16, "speed": 198.0}
		"dart":
			return {"health": 1, "shoot_interval": 0.0, "speed": 284.0}
		"wave":
			return {"health": 1, "speed": 240.0}
	return {"health": 1, "speed": 260.0}


func _on_player_state_changed(hull: int, max_hull: int, lives: int, weapon_level: int, status_text: String) -> void:
	_player_hull = hull
	_player_max_hull = max_hull
	_player_lives = lives
	_player_weapon = weapon_level
	_player_status = status_text


func _on_enemy_destroyed(score_value: int, burst_position: Vector2) -> void:
	_score += score_value
	_kills_since_weapon_drop += 1
	_maybe_spawn_powerup_drop(burst_position)
	_spawn_burst_effect(burst_position, GameSession.COLOR_FG, 18.0, "burst")
	AudioDirector.play_sfx("enemy_pop")


func _on_enemy_damaged(hit_position: Vector2, enemy_type: String, remaining_hull: int) -> void:
	var radius := 10.0 if enemy_type != "tank" else 14.0
	var color := GameSession.COLOR_HIT if remaining_hull <= 1 else GameSession.COLOR_ALERT
	_spawn_burst_effect(hit_position, color, radius, "spark")


func _on_boss_hull_changed(current_hull: int, max_hull: int) -> void:
	_boss_hull = current_hull
	_boss_max_hull = max_hull


func _on_boss_damaged(hit_position: Vector2, current_hull: int, max_hull: int) -> void:
	_spawn_burst_effect(hit_position, GameSession.COLOR_ALERT, 20.0, "spark")
	var profile_name := String(_boss_config.get("profile", ""))
	if profile_name != "overlord" and max_hull > 0:
		var normal_ratio := float(current_hull) / float(max_hull)
		if _boss_phase_alert_step < 1 and normal_ratio <= 0.72:
			_boss_phase_alert_step = 1
			_hud.show_notice(GameSession.loc("boss_shift"), 1.15, GameSession.COLOR_ALERT)
			_hud.flash(GameSession.COLOR_ALERT, 0.16)
	if profile_name == "overlord" and max_hull > 0:
		var ratio := float(current_hull) / float(max_hull)
		if _final_boss_alert_step < 1 and ratio <= 0.66:
			_final_boss_alert_step = 1
			_hud.show_notice(GameSession.loc("final_boss_shift"), 1.3, GameSession.COLOR_ALERT)
			_hud.flash(GameSession.COLOR_ALERT, 0.2)
		elif _final_boss_alert_step < 2 and ratio <= 0.33:
			_final_boss_alert_step = 2
			_hud.show_notice(GameSession.loc("final_boss_meltdown"), 1.45, GameSession.COLOR_HIT)
			_hud.flash(GameSession.COLOR_HIT, 0.24)
	if _boss_frenzy_announced:
		return
	if max_hull <= 0:
		return
	if float(current_hull) / float(max_hull) > 0.45:
		return
	_boss_frenzy_announced = true
	_hud.show_notice(GameSession.loc("boss_frenzy"), 1.3, GameSession.COLOR_ALERT)
	_hud.flash(GameSession.COLOR_ALERT, 0.22)


func _on_boss_destroyed(score_value: int, burst_position: Vector2) -> void:
	_score += score_value
	_stages_cleared = _stage_index + 1
	_clear_projectiles()
	_spawn_burst_effect(burst_position, GameSession.COLOR_ALERT, 48.0)
	if String(_boss_config.get("profile", "")) == "overlord":
		_spawn_burst_effect(burst_position + Vector2(-48.0, -24.0), GameSession.COLOR_HIT, 36.0)
		_spawn_burst_effect(burst_position + Vector2(52.0, 18.0), GameSession.COLOR_HIT, 40.0)
		_spawn_burst_effect(burst_position + Vector2(0.0, -54.0), GameSession.COLOR_ALERT, 32.0, "cross")
	_hud.flash(GameSession.COLOR_ALERT, 0.26)
	if String(_boss_config.get("profile", "")) == "overlord":
		_hud.show_center_message(GameSession.loc("final_core_destroyed"), 2.2, GameSession.COLOR_HIT)
		_hud.show_notice(GameSession.loc("final_escape"), 2.6, GameSession.COLOR_ALERT)
	else:
		_hud.show_notice(GameSession.loc("phase_clear", [_stage_name]), 1.8, GameSession.COLOR_ALERT)
	AudioDirector.play_sfx("boss_down")
	if _stage_index < _stages.size() - 1:
		_pending_stage_index = _stage_index + 1
		_stage_transition_timer = 2.4
		_boss = null
		_boss_hull = 0
		_boss_max_hull = 0
		_boss_support_timer = 0.0
		return
	_boss = null
	_boss_hull = 0
	_boss_max_hull = 0
	_boss_support_timer = 0.0
	_ending_victory = true
	_ending_timer = 2.8


func _on_player_defeated() -> void:
	_finish_run(false)


func _on_player_feedback_requested(event_name: String, event_position: Vector2) -> void:
	match event_name:
		"hit":
			_spawn_burst_effect(event_position, GameSession.COLOR_HIT, 20.0, "cross")
			_hud.flash(GameSession.COLOR_HIT, 0.22)
			_hud.show_notice(GameSession.loc("feedback_hull"), 0.7, GameSession.COLOR_HIT)
			AudioDirector.play_sfx("hit")
		"weapon_down":
			_spawn_burst_effect(event_position, GameSession.COLOR_ALERT, 18.0, "spark")
			_hud.show_notice(GameSession.loc("feedback_weapon_down"), 0.95, GameSession.COLOR_ALERT)
			AudioDirector.play_sfx("hit")
		"weapon":
			_spawn_burst_effect(event_position, GameSession.COLOR_ALERT, 24.0)
			_hud.show_notice(GameSession.loc("feedback_weapon_up"), 1.1, GameSession.COLOR_ALERT)
			AudioDirector.play_sfx("pickup")
		"repair":
			_spawn_burst_effect(event_position, GameSession.COLOR_FG, 24.0)
			_hud.show_notice(GameSession.loc("feedback_repair"), 1.0, GameSession.COLOR_FG)
			AudioDirector.play_sfx("repair")
		"shield":
			_spawn_burst_effect(event_position, GameSession.COLOR_ALERT, 26.0, "ring")
			_hud.show_notice(GameSession.loc("feedback_shield"), 1.1, GameSession.COLOR_ALERT)
			AudioDirector.play_sfx("pickup")
		"shield_break":
			_spawn_burst_effect(event_position, GameSession.COLOR_ALERT, 28.0, "ring")
			_hud.flash(GameSession.COLOR_ALERT, 0.14)
			_hud.show_notice(GameSession.loc("feedback_shield_break"), 0.9, GameSession.COLOR_ALERT)
			AudioDirector.play_sfx("hit")
		"overdrive":
			_spawn_burst_effect(event_position, GameSession.COLOR_ALERT, 28.0)
			_hud.flash(GameSession.COLOR_ALERT, 0.16)
			_hud.show_notice(GameSession.loc("feedback_overdrive"), 1.3, GameSession.COLOR_ALERT)
			AudioDirector.play_sfx("overdrive")
		"respawn":
			_hud.show_notice(GameSession.loc("feedback_hull"), 1.0, GameSession.COLOR_DIM)
			AudioDirector.play_sfx("hit")
		"destroyed":
			_spawn_burst_effect(event_position, GameSession.COLOR_HIT, 34.0)
			AudioDirector.play_sfx("defeat")


func _spawn_burst_effect(at_position: Vector2, color: Color, radius: float, mode: String = "ring") -> void:
	var effect := FEEDBACK_BURST_SCENE.instantiate()
	_mark_gameplay_node(effect)
	effect.position = at_position
	effect.setup({
		"color": color,
		"radius": radius,
		"mode": mode,
	})
	add_child(effect)


func _maybe_spawn_powerup_drop(at_position: Vector2) -> void:
	if get_tree().get_nodes_in_group("powerup").size() > 0:
		return
	if _kills_since_weapon_drop >= 8:
		var guaranteed_kind := "weapon" if _player_weapon < 13 else "overdrive"
		_spawn_runtime_powerup(guaranteed_kind, at_position)
		_kills_since_weapon_drop = 0
		_random_drop_cooldown = 6.4
		return
	if _random_drop_cooldown > 0.0:
		return
	if randf() > 0.06:
		return
	var random_kind := _roll_random_drop_kind()
	_spawn_runtime_powerup(random_kind, at_position)
	_random_drop_cooldown = 6.2


func _roll_random_drop_kind() -> String:
	var roll := randf()
	if _player_weapon < 13 and roll < 0.34:
		return "weapon"
	if roll < 0.46:
		return "repair"
	if roll < 0.58:
		return "shield"
	return "overdrive"


func _spawn_runtime_powerup(kind_name: String, at_position: Vector2) -> void:
	var pickup := POWERUP_SCENE.instantiate()
	_mark_gameplay_node(pickup)
	pickup.position = Vector2(
		clamp(at_position.x, 140.0, GameSession.VIEW_SIZE.x - 120.0),
		clamp(at_position.y, 96.0, GameSession.VIEW_SIZE.y - 84.0)
	)
	pickup.setup({
		"kind": kind_name,
		"speed": 118.0,
	})
	add_child(pickup)


func _mark_gameplay_node(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_PAUSABLE


func _trigger_boss_warning() -> void:
	_boss_warning_active = true
	_hud.show_notice(GameSession.loc("boss_warning_notice"), 1.6, GameSession.COLOR_ALERT)
	_hud.show_danger_warning(1.55)
	AudioDirector.play_sfx("boss_alarm")
	_boss_alarm_bursts_left = 4
	_boss_alarm_timer = 0.34


func _clear_projectiles() -> void:
	_clear_player_beam()
	for bullet in get_tree().get_nodes_in_group("player_bullet"):
		bullet.queue_free()
	for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
		bullet.queue_free()
	for pickup in get_tree().get_nodes_in_group("powerup"):
		pickup.queue_free()


func _clear_stage_objects() -> void:
	_clear_projectiles()
	for enemy in get_tree().get_nodes_in_group("enemy_ship"):
		enemy.queue_free()
	for boss in get_tree().get_nodes_in_group("boss"):
		boss.queue_free()


func _stage_progress() -> float:
	if _spawn_schedule.is_empty():
		return 0.0
	var final_event_time := float(_spawn_schedule[_spawn_schedule.size() - 1]["time"])
	if final_event_time <= 0.0:
		return 0.0
	return min(_stage_elapsed / final_event_time, 1.0)


func _update_phase_text() -> void:
	if _stage_transition_timer > 0.0 and _pending_stage_index >= 0:
		_phase_text = GameSession.loc("phase_clear", [_stage_name])
	elif is_instance_valid(_boss):
		_phase_text = GameSession.loc("stage_boss", [_stage_name])
	elif _boss_pending:
		_phase_text = GameSession.loc("phase_warning", [_stage_name])
	elif _stage_elapsed < 10.0:
		_phase_text = GameSession.loc("stage_opening", [_stage_name])
	elif _stage_elapsed < 24.0:
		_phase_text = GameSession.loc("stage_pressure", [_stage_name])
	else:
		_phase_text = GameSession.loc("stage_final_wave", [_stage_name])


func _pause_run() -> void:
	if _is_paused or _finished:
		return
	_is_paused = true
	get_tree().paused = true
	AudioDirector.set_music_mode("pause")
	_hud.show_pause(_score, GameSession.high_score)
	_hud.show_notice(GameSession.loc("feedback_paused"), 0.8, GameSession.COLOR_ALERT)
	AudioDirector.play_sfx("pause")


func _resume_run() -> void:
	if not _is_paused:
		return
	_is_paused = false
	get_tree().paused = false
	AudioDirector.set_music_mode("combat")
	_hud.hide_pause()
	_hud.show_notice(GameSession.loc("feedback_resume"), 0.8, GameSession.COLOR_FG)
	AudioDirector.play_sfx("resume")


func _restart_run() -> void:
	get_tree().paused = false
	_is_paused = false
	AudioDirector.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/game/game_root.tscn")


func _return_to_menu() -> void:
	get_tree().paused = false
	_is_paused = false
	AudioDirector.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _finish_run(victory: bool) -> void:
	if _finished:
		return
	_finished = true
	get_tree().paused = false
	_is_paused = false
	var stage_reached := _stage_index + 1
	if _pending_stage_index >= 0:
		stage_reached = _pending_stage_index + 1
	GameSession.save_result(victory, _score, _elapsed, _player_weapon, _player_hull, _stages_cleared, stage_reached, _stages.size())
	AudioDirector.set_music_mode("victory" if victory else "defeat")
	get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")
