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
var _player: Area2D
var _boss: Area2D
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
var _player_hull := 4
var _player_max_hull := 4
var _player_lives := 3
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
var _kills_since_weapon_drop := 0
var _random_drop_cooldown := 0.0
var _boss_warning_active := false
var _boss_frenzy_announced := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioDirector.set_music_mode("combat")
	_stages = _build_stages()
	var starfield := STARFIELD_SCENE.instantiate()
	_mark_gameplay_node(starfield)
	add_child(starfield)
	_hud = HUD_SCENE.instantiate()
	_hud.resume_requested.connect(_resume_run)
	_hud.restart_requested.connect(_restart_run)
	_hud.menu_requested.connect(_return_to_menu)
	add_child(_hud)
	_player = PLAYER_SCENE.instantiate()
	_mark_gameplay_node(_player)
	_player.position = Vector2(120.0, GameSession.VIEW_SIZE.y * 0.5)
	_player.shoot_requested.connect(_spawn_player_shots)
	_player.state_changed.connect(_on_player_state_changed)
	_player.defeated.connect(_on_player_defeated)
	_player.feedback_requested.connect(_on_player_feedback_requested)
	add_child(_player)
	_load_stage(0)
	_hud.show_center_message("SECTOR 1 START", 1.6)
	_hud.show_notice("Push through two sectors and defeat both bosses.", 2.2)


func _process(delta: float) -> void:
	if _finished:
		return
	if _is_paused:
		_sync_hud()
		return
	_shot_sfx_timer = max(_shot_sfx_timer - delta, 0.0)
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
	return [
		{
			"name": "SECTOR 1",
			"schedule": [
				{"time": 1.0, "kind": "burst", "enemy_type": "straight", "lanes": [110.0, 188.0, 266.0, 344.0]},
				{"time": 4.8, "kind": "burst", "enemy_type": "wave", "lanes": [136.0, 220.0, 304.0, 388.0], "x_spacing": 66.0},
				{"time": 8.9, "kind": "burst", "enemy_type": "straight", "lanes": [388.0, 326.0, 264.0, 202.0, 140.0], "x_spacing": 60.0},
				{"time": 12.9, "kind": "burst", "enemy_type": "dart", "lanes": [118.0, 392.0], "overrides": {"shoot_interval": 1.95}},
				{"time": 17.8, "kind": "burst", "enemy_type": "tank", "lanes": [170.0, 336.0], "x_spacing": 94.0, "overrides": {"health": 4}},
				{"time": 22.9, "kind": "burst", "enemy_type": "wave", "lanes": [118.0, 190.0, 262.0, 334.0, 406.0], "x_spacing": 54.0},
				{"time": 27.1, "kind": "powerup", "kind_name": "repair", "position": Vector2(GameSession.VIEW_SIZE.x + 30.0, 180.0)},
				{"time": 29.9, "kind": "burst", "enemy_type": "dart", "lanes": [126.0, 208.0, 332.0, 414.0], "x_spacing": 76.0},
				{"time": 34.5, "kind": "burst", "enemy_type": "wave", "lanes": [150.0, 270.0, 390.0], "x_spacing": 86.0, "overrides": {"health": 3}},
				{"time": 39.8, "kind": "boss"},
			],
			"boss": {
				"profile": "striker",
				"max_hull": 34,
				"move_amplitude": 110.0,
				"move_speed": 1.6,
				"fire_cooldown": 1.05,
				"enrage_ratio": 0.34,
				"score_value": 2200,
			},
		},
		{
			"name": "SECTOR 2",
			"schedule": [
				{"time": 1.2, "kind": "burst", "enemy_type": "straight", "lanes": [102.0, 162.0, 222.0, 318.0, 378.0, 438.0], "x_spacing": 50.0},
				{"time": 4.8, "kind": "burst", "enemy_type": "dart", "lanes": [126.0, 248.0, 370.0], "x_spacing": 88.0, "overrides": {"shoot_interval": 1.62}},
				{"time": 8.5, "kind": "powerup", "kind_name": "overdrive", "position": Vector2(GameSession.VIEW_SIZE.x + 30.0, 300.0)},
				{"time": 10.3, "kind": "burst", "enemy_type": "wave", "lanes": [124.0, 184.0, 244.0, 304.0, 364.0, 424.0], "x_spacing": 46.0, "overrides": {"speed": 238.0}},
				{"time": 15.8, "kind": "burst", "enemy_type": "tank", "lanes": [142.0, 270.0, 398.0], "x_spacing": 82.0, "overrides": {"shoot_interval": 1.45, "health": 5}},
				{"time": 21.0, "kind": "burst", "enemy_type": "wave", "lanes": [152.0, 248.0, 344.0], "x_spacing": 88.0, "overrides": {"health": 3, "speed": 228.0}},
				{"time": 24.0, "kind": "burst", "enemy_type": "dart", "lanes": [114.0, 174.0, 366.0, 426.0], "x_spacing": 62.0, "overrides": {"shoot_interval": 1.3}},
				{"time": 29.6, "kind": "burst", "enemy_type": "wave", "lanes": [132.0, 208.0, 284.0, 360.0], "x_spacing": 56.0, "overrides": {"health": 3}},
				{"time": 33.3, "kind": "powerup", "kind_name": "repair", "position": Vector2(GameSession.VIEW_SIZE.x + 30.0, 380.0)},
				{"time": 36.4, "kind": "burst", "enemy_type": "tank", "lanes": [120.0, 220.0, 320.0, 420.0], "x_spacing": 66.0, "overrides": {"health": 5, "shoot_interval": 1.28}},
				{"time": 43.8, "kind": "boss"},
			],
			"boss": {
				"profile": "carrier",
				"max_hull": 52,
				"move_amplitude": 78.0,
				"move_speed": 1.1,
				"entry_speed": 100.0,
				"fire_cooldown": 0.94,
				"enrage_ratio": 0.38,
				"enrage_fire_multiplier": 0.7,
				"score_value": 3600,
				"target_x": 748.0,
			},
		},
	]


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
	var stage: Dictionary = _stages[index]
	_stage_name = String(stage["name"])
	_spawn_schedule = stage["schedule"]
	_boss_config = stage["boss"]
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
				"tint": GameSession.COLOR_ALERT,
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
	_boss.fire_requested.connect(_spawn_enemy_shots)
	_boss.hull_changed.connect(_on_boss_hull_changed)
	_boss.damaged.connect(_on_boss_damaged)
	add_child(_boss)
	_hud.show_center_message("%s BOSS" % _stage_name, 1.4)
	_hud.flash(GameSession.COLOR_ALERT, 0.18)
	AudioDirector.play_sfx("boss_alarm")
	_boss_warning_active = false


func _spawn_player_shots(shots: Array) -> void:
	for shot in shots:
		var bullet := BULLET_SCENE.instantiate()
		_mark_gameplay_node(bullet)
		bullet.setup(shot["position"], shot["direction"], float(shot["speed"]), int(shot["damage"]), true)
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
	if _boss_frenzy_announced:
		return
	if max_hull <= 0:
		return
	if float(current_hull) / float(max_hull) > 0.38:
		return
	_boss_frenzy_announced = true
	_hud.show_notice("BOSS FRENZY", 1.3, GameSession.COLOR_ALERT)
	_hud.flash(GameSession.COLOR_ALERT, 0.22)


func _on_boss_destroyed(score_value: int, burst_position: Vector2) -> void:
	_score += score_value
	_stages_cleared = _stage_index + 1
	_clear_projectiles()
	_spawn_burst_effect(burst_position, GameSession.COLOR_ALERT, 48.0)
	_hud.flash(GameSession.COLOR_ALERT, 0.26)
	_hud.show_notice("%s CLEAR" % _stage_name, 1.8, GameSession.COLOR_ALERT)
	AudioDirector.play_sfx("boss_down")
	if _stage_index < _stages.size() - 1:
		_pending_stage_index = _stage_index + 1
		_stage_transition_timer = 2.4
		_boss = null
		_boss_hull = 0
		_boss_max_hull = 0
		return
	_finish_run(true)


func _on_player_defeated() -> void:
	_finish_run(false)


func _on_player_feedback_requested(event_name: String, event_position: Vector2) -> void:
	match event_name:
		"hit":
			_spawn_burst_effect(event_position, GameSession.COLOR_HIT, 20.0, "cross")
			_hud.flash(GameSession.COLOR_HIT, 0.22)
			_hud.show_notice("HULL DAMAGED", 0.7, GameSession.COLOR_HIT)
			AudioDirector.play_sfx("hit")
		"weapon":
			_spawn_burst_effect(event_position, GameSession.COLOR_ALERT, 24.0)
			_hud.show_notice("WEAPON UPGRADE", 1.1, GameSession.COLOR_ALERT)
			AudioDirector.play_sfx("pickup")
		"repair":
			_spawn_burst_effect(event_position, GameSession.COLOR_FG, 24.0)
			_hud.show_notice("HULL REPAIRED", 1.0, GameSession.COLOR_FG)
			AudioDirector.play_sfx("repair")
		"overdrive":
			_spawn_burst_effect(event_position, GameSession.COLOR_ALERT, 28.0)
			_hud.flash(GameSession.COLOR_ALERT, 0.16)
			_hud.show_notice("OVERDRIVE ENGAGED", 1.3, GameSession.COLOR_ALERT)
			AudioDirector.play_sfx("overdrive")
		"respawn":
			_hud.show_notice("LIFE LOST - RETURNING TO FORMATION", 1.3, GameSession.COLOR_DIM)
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
		var guaranteed_kind := "weapon" if _player_weapon < 3 else "repair"
		_spawn_runtime_powerup(guaranteed_kind, at_position)
		_kills_since_weapon_drop = 0
		_random_drop_cooldown = 4.0
		return
	if _random_drop_cooldown > 0.0:
		return
	if randf() > 0.11:
		return
	var random_kind := _roll_random_drop_kind()
	_spawn_runtime_powerup(random_kind, at_position)
	_random_drop_cooldown = 5.5


func _roll_random_drop_kind() -> String:
	var roll := randf()
	if _player_weapon < 3 and roll < 0.2:
		return "weapon"
	if roll < 0.72:
		return "repair"
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
	_hud.show_center_message("%s WARNING" % _stage_name, 1.2, GameSession.COLOR_ALERT)
	_hud.show_notice("Boss signature detected. Hold formation.", 1.4, GameSession.COLOR_ALERT)
	_hud.flash(GameSession.COLOR_ALERT, 0.32)
	AudioDirector.play_sfx("boss_alarm")


func _clear_projectiles() -> void:
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
		_phase_text = "%s CLEAR" % _stage_name
	elif is_instance_valid(_boss):
		_phase_text = "%s BOSS" % _stage_name
	elif _boss_pending:
		_phase_text = "%s WARNING" % _stage_name
	elif _stage_elapsed < 10.0:
		_phase_text = "%s OPENING" % _stage_name
	elif _stage_elapsed < 24.0:
		_phase_text = "%s PRESSURE" % _stage_name
	else:
		_phase_text = "%s FINAL WAVE" % _stage_name


func _pause_run() -> void:
	if _is_paused or _finished:
		return
	_is_paused = true
	get_tree().paused = true
	AudioDirector.set_music_mode("pause")
	_hud.show_pause(_score, GameSession.high_score)
	_hud.show_notice("RUN PAUSED", 0.8, GameSession.COLOR_ALERT)
	AudioDirector.play_sfx("pause")


func _resume_run() -> void:
	if not _is_paused:
		return
	_is_paused = false
	get_tree().paused = false
	AudioDirector.set_music_mode("combat")
	_hud.hide_pause()
	_hud.show_notice("BACK IN ACTION", 0.8, GameSession.COLOR_FG)
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
	GameSession.save_result(victory, _score, _elapsed, _player_weapon, _player_lives, _stages_cleared, stage_reached)
	AudioDirector.set_music_mode("victory" if victory else "defeat")
	get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")
