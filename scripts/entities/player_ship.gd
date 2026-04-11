extends Area2D

signal shoot_requested(shots: Array)
signal beam_updated(beam_data: Dictionary)
signal beam_released
signal state_changed(hull: int, max_hull: int, lives: int, weapon_level: int, status_text: String)
signal defeated
signal feedback_requested(event_name: String, event_position: Vector2)

const MAX_HULL := 3
const STARTING_LIVES := 1
const HIT_INVULNERABLE_TIME := 0.72
const RESPAWN_INVULNERABLE_TIME := 1.5
const MAX_WEAPON_LEVEL := 13

var move_speed := 336.0
var fire_cooldown := 0.165
var _fire_timer := 0.0
var _invulnerable_time := 0.0
var hull := MAX_HULL
var lives := STARTING_LIVES
var weapon_level := 1
var overdrive_time := 0.0
var shield_hits := 0
var _defeated := false
var _beam_active := false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 2 | 8 | 16
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(28.0, 16.0)
	shape.shape = rectangle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	_emit_state_changed()


func _process(delta: float) -> void:
	if _defeated:
		return
	_fire_timer = max(_fire_timer - delta, 0.0)
	_invulnerable_time = max(_invulnerable_time - delta, 0.0)
	var previous_overdrive := overdrive_time
	overdrive_time = max(overdrive_time - delta, 0.0)
	if previous_overdrive > 0.0 and overdrive_time == 0.0:
		_emit_state_changed()

	var input_vector := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	var current_speed := move_speed + (28.0 if overdrive_time > 0.0 else 0.0)
	position += input_vector * current_speed * delta
	position.x = clamp(position.x, GameSession.PLAYER_BOUNDS.position.x, GameSession.PLAYER_BOUNDS.end.x)
	position.y = clamp(position.y, GameSession.PLAYER_BOUNDS.position.y, GameSession.PLAYER_BOUNDS.end.y)

	var current_cooldown := fire_cooldown * 0.6 if overdrive_time > 0.0 else fire_cooldown
	var fire_pressed := Input.is_action_pressed("fire")
	if weapon_level >= 9:
		if fire_pressed:
			_emit_beam(current_cooldown)
		else:
			_release_beam()
	elif fire_pressed and _fire_timer <= 0.0:
		_release_beam()
		_fire_timer = current_cooldown
		emit_signal("shoot_requested", _build_shots())
	else:
		_release_beam()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if _defeated:
		return
	if area.is_in_group("enemy_bullet"):
		if area.has_method("consume"):
			area.consume()
		_apply_damage(1)
	elif area.is_in_group("enemy"):
		if area.has_method("collide_with_player"):
			area.collide_with_player()
		_apply_damage(1)
	elif area.is_in_group("powerup"):
		var powerup_kind := "weapon"
		if area.has_method("collect"):
			powerup_kind = area.collect()
		feedback_requested.emit(powerup_kind, global_position)
		_apply_powerup(powerup_kind)


func _build_shots() -> Array:
	var shots: Array = []
	if weapon_level <= 4:
		shots.append_array(_spread_pattern(weapon_level, false))
	elif weapon_level <= 8:
		shots.append_array(_spread_pattern(weapon_level - 4, true))
	if overdrive_time > 0.0:
		shots.append(_player_shot(Vector2(24.0, 0.0), Vector2.RIGHT, 790.0, 2, Vector2(22.0, 7.0), Vector2(8.0, 7.0), 10.0))
	return shots


func _spread_pattern(level: int, thickened: bool) -> Array:
	var shots: Array = []
	var size := Vector2(18.0, 4.0)
	var core_size := Vector2(7.0, 6.0)
	var damage := 1
	var speed := 690.0
	var trail_length := 8.0
	if thickened:
		size = Vector2(22.0, 7.0)
		core_size = Vector2(9.0, 9.0)
		damage = 2
		speed = 732.0
		trail_length = 10.0
	match level:
		1:
			shots.append(_player_shot(Vector2(22.0, 0.0), Vector2.RIGHT, speed, damage, size, core_size, trail_length))
		2:
			shots.append(_player_shot(Vector2(20.0, -4.0), Vector2.RIGHT, speed, damage, size, core_size, trail_length))
			shots.append(_player_shot(Vector2(20.0, 4.0), Vector2.RIGHT, speed, damage, size, core_size, trail_length))
		3:
			shots.append(_player_shot(Vector2(20.0, -8.0), Vector2.RIGHT, speed + 8.0, damage, size, core_size, trail_length))
			shots.append(_player_shot(Vector2(20.0, 0.0), Vector2.RIGHT, speed + 8.0, damage, size, core_size, trail_length))
			shots.append(_player_shot(Vector2(20.0, 8.0), Vector2.RIGHT, speed + 8.0, damage, size, core_size, trail_length))
		_:
			shots.append(_player_shot(Vector2(20.0, -8.0), Vector2.RIGHT, speed + 14.0, damage, size, core_size, trail_length))
			shots.append(_player_shot(Vector2(20.0, 0.0), Vector2.RIGHT, speed + 14.0, damage, size, core_size, trail_length))
			shots.append(_player_shot(Vector2(20.0, 8.0), Vector2.RIGHT, speed + 14.0, damage, size, core_size, trail_length))
			shots.append(_player_shot(Vector2(18.0, -14.0), Vector2(1.0, -0.22), speed + 10.0, damage, size, core_size, trail_length))
			shots.append(_player_shot(Vector2(18.0, 14.0), Vector2(1.0, 0.22), speed + 10.0, damage, size, core_size, trail_length))
	return shots


func _beam_shot(level: int, tick_interval: float) -> Dictionary:
	var beam_stage: int = clampi(level - 9, 0, 4)
	var beam_height: float
	var beam_damage: int
	match beam_stage:
		0:
			beam_height = 8.0
			beam_damage = 2
		1:
			beam_height = 14.0
			beam_damage = 2
		2:
			beam_height = 24.0
			beam_damage = 3
		3:
			beam_height = 40.0
			beam_damage = 3
		_:
			beam_height = 68.0
			beam_damage = 4
	var beam_start_x := global_position.x + 24.0
	var beam_end_x := GameSession.VIEW_SIZE.x - 10.0
	if beam_start_x > beam_end_x - 12.0:
		beam_start_x = beam_end_x - 12.0
	var beam_length: float = max(beam_end_x - beam_start_x, 12.0)
	var core_height: float = max(beam_height * 0.55, 4.0)
	return {
		"position": Vector2(beam_start_x + beam_length * 0.5, global_position.y),
		"direction": Vector2.ZERO,
		"speed": 0.0,
		"damage": beam_damage,
		"visual_size": Vector2(beam_length, beam_height),
		"core_size": Vector2(beam_length, core_height),
		"trail_length": 0.0,
		"beam_mode": true,
		"life_time": -1.0,
		"tick_interval": max(tick_interval, 0.05),
	}


func _player_shot(offset: Vector2, shot_direction: Vector2, shot_speed: float, shot_damage: int, visual_size: Vector2, core_size: Vector2, trail_length: float, beam_mode: bool = false, shot_life_time: float = -1.0) -> Dictionary:
	return {
		"position": global_position + offset,
		"direction": shot_direction,
		"speed": shot_speed,
		"damage": shot_damage,
		"visual_size": visual_size,
		"core_size": core_size,
		"trail_length": trail_length,
		"beam_mode": beam_mode,
		"life_time": shot_life_time,
	}


func _apply_powerup(kind: String = "weapon") -> void:
	match kind:
		"repair":
			hull = min(hull + 1, MAX_HULL)
		"shield":
			shield_hits = 1
		"overdrive":
			overdrive_time = 8.0
		_:
			if weapon_level < MAX_WEAPON_LEVEL:
				weapon_level += 1
			else:
				hull = min(hull + 1, MAX_HULL)
	_emit_state_changed()


func _apply_damage(amount: int) -> void:
	if _invulnerable_time > 0.0:
		return
	if shield_hits > 0:
		shield_hits = max(shield_hits - 1, 0)
		_invulnerable_time = 0.25
		feedback_requested.emit("shield_break", global_position)
		_emit_state_changed()
		return
	_invulnerable_time = HIT_INVULNERABLE_TIME
	if weapon_level > 1:
		var lost_weapon_level := weapon_level
		weapon_level = max(weapon_level - amount, 1)
		if weapon_level < lost_weapon_level:
			feedback_requested.emit("weapon_down", global_position)
		_emit_state_changed()
		return
	hull -= amount
	if hull > 0:
		feedback_requested.emit("hit", global_position)
		_emit_state_changed()
		return
	lives = 0
	_defeated = true
	_release_beam()
	feedback_requested.emit("destroyed", global_position)
	_emit_state_changed()
	visible = false
	set_deferred("monitoring", false)
	call_deferred("_emit_defeated")
	return


func _emit_state_changed() -> void:
	state_changed.emit(hull, MAX_HULL, lives, weapon_level, get_status_text())


func _emit_defeated() -> void:
	defeated.emit()


func set_start_loadout(start_weapon_level: int) -> void:
	weapon_level = clampi(start_weapon_level, 1, MAX_WEAPON_LEVEL)
	_emit_state_changed()


func _emit_beam(tick_interval: float) -> void:
	_beam_active = true
	beam_updated.emit(_beam_shot(weapon_level, tick_interval))


func _release_beam() -> void:
	if not _beam_active:
		return
	_beam_active = false
	beam_released.emit()


func get_status_text() -> String:
	var status_parts: Array[String] = []
	if shield_hits > 0:
		status_parts.append(GameSession.loc("status_shield"))
	if overdrive_time > 0.0:
		status_parts.append(GameSession.loc("status_boost"))
	return " ".join(status_parts)


func _draw() -> void:
	var ship_color := GameSession.COLOR_FG
	if _invulnerable_time > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0:
		ship_color = GameSession.COLOR_HIT
	if shield_hits > 0:
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 28, GameSession.COLOR_ALERT, 2.0)
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, GameSession.COLOR_FG, 1.0)
	var body := PackedVector2Array([
		Vector2(-14.0, -6.0),
		Vector2(8.0, -6.0),
		Vector2(18.0, 0.0),
		Vector2(8.0, 6.0),
		Vector2(-14.0, 6.0),
	])
	draw_polygon(body, PackedColorArray([ship_color, ship_color, ship_color, ship_color, ship_color]))
	draw_rect(Rect2(Vector2(-18.0, -2.0), Vector2(6.0, 4.0)), ship_color, true)
