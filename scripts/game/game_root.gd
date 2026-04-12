extends Node2D

const STAGE_CATALOG := preload("res://scripts/game/stage_catalog.gd")
const STAGE_SCHEDULE := preload("res://scripts/game/stage_schedule.gd")
const RUN_BALANCE := preload("res://scripts/game/run_balance.gd")
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
			_boss_alarm_timer = RUN_BALANCE.BOSS_ALARM_INTERVAL
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
				"support_pattern": ["wave", "skirmisher", "wave", "skirmisher"],
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
				"support_pattern": ["sentinel", "lancer", "tank", "lancer"],
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
				"support_pattern": ["dart", "skirmisher", "dart", "skirmisher"],
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
				"support_pattern": ["lancer", "tank", "spinner", "lancer"],
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
				"support_pattern": ["dart", "skirmisher", "sentinel", "lancer", "sentinel"],
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
	return STAGE_SCHEDULE.sector_1()


func _build_sector_2_schedule() -> Array:
	return STAGE_SCHEDULE.sector_2()


func _build_sector_3_schedule() -> Array:
	return STAGE_SCHEDULE.sector_3()


func _build_sector_4_schedule() -> Array:
	return STAGE_SCHEDULE.sector_4()


func _build_sector_5_schedule() -> Array:
	return STAGE_SCHEDULE.sector_5()


func _build_final_schedule() -> Array:
	return STAGE_SCHEDULE.final_sector()


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
	return STAGE_CATALOG.enemy_config(enemy_type, base_y, overrides)


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
	_hud.show_notice(GameSession.loc(STAGE_CATALOG.boss_spawn_notice_key(String(_boss_config.get("profile", "")))), 1.2, GameSession.COLOR_ALERT)
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
	return STAGE_CATALOG.boss_support_overrides(enemy_type)


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
			_hud.show_notice(GameSession.loc(STAGE_CATALOG.boss_shift_notice_key(profile_name)), 1.15, GameSession.COLOR_ALERT)
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
	if RUN_BALANCE.should_spawn_guaranteed_drop(_kills_since_weapon_drop):
		var guaranteed_kind := RUN_BALANCE.guaranteed_drop_kind(_player_weapon)
		_spawn_runtime_powerup(guaranteed_kind, at_position)
		_kills_since_weapon_drop = 0
		_random_drop_cooldown = RUN_BALANCE.GUARANTEED_DROP_COOLDOWN
		return
	if not RUN_BALANCE.should_roll_random_drop(_random_drop_cooldown):
		return
	var random_kind := RUN_BALANCE.random_drop_kind(_player_weapon)
	_spawn_runtime_powerup(random_kind, at_position)
	_random_drop_cooldown = RUN_BALANCE.RANDOM_DROP_COOLDOWN


func _spawn_runtime_powerup(kind_name: String, at_position: Vector2) -> void:
	var pickup := POWERUP_SCENE.instantiate()
	_mark_gameplay_node(pickup)
	pickup.position = RUN_BALANCE.clamped_powerup_position(at_position)
	pickup.setup({
		"kind": kind_name,
		"speed": RUN_BALANCE.RUNTIME_POWERUP_SPEED,
	})
	add_child(pickup)


func _mark_gameplay_node(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_PAUSABLE


func _trigger_boss_warning() -> void:
	_boss_warning_active = true
	_hud.show_notice(GameSession.loc("boss_warning_notice"), 1.6, GameSession.COLOR_ALERT)
	_hud.show_danger_warning(1.55)
	AudioDirector.play_sfx("boss_alarm")
	_boss_alarm_bursts_left = RUN_BALANCE.BOSS_ALARM_BURSTS - 1
	_boss_alarm_timer = RUN_BALANCE.BOSS_ALARM_INTERVAL


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
