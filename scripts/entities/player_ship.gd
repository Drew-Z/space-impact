extends Area2D

signal shoot_requested(shots: Array)
signal state_changed(hull: int, max_hull: int, lives: int, weapon_level: int, status_text: String)
signal defeated
signal feedback_requested(event_name: String, event_position: Vector2)

const MAX_HULL := 4
const STARTING_LIVES := 3

var move_speed := 336.0
var fire_cooldown := 0.165
var _fire_timer := 0.0
var _invulnerable_time := 0.0
var hull := MAX_HULL
var lives := STARTING_LIVES
var weapon_level := 1
var overdrive_time := 0.0
var _defeated := false


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
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_fire_timer = current_cooldown
		emit_signal("shoot_requested", _build_shots())
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
	match weapon_level:
		1:
			shots.append({
				"position": global_position + Vector2(22.0, 0.0),
				"direction": Vector2.RIGHT,
				"speed": 680.0,
				"damage": 1,
			})
		2:
			shots.append({
				"position": global_position + Vector2(20.0, -4.0),
				"direction": Vector2.RIGHT,
				"speed": 680.0,
				"damage": 1,
			})
			shots.append({
				"position": global_position + Vector2(20.0, 4.0),
				"direction": Vector2.RIGHT,
				"speed": 680.0,
				"damage": 1,
			})
		_:
			shots.append({
				"position": global_position + Vector2(20.0, 0.0),
				"direction": Vector2.RIGHT,
				"speed": 700.0,
				"damage": 1,
			})
			shots.append({
				"position": global_position + Vector2(18.0, -6.0),
				"direction": Vector2(1.0, -0.16),
				"speed": 700.0,
				"damage": 1,
			})
			shots.append({
				"position": global_position + Vector2(18.0, 6.0),
				"direction": Vector2(1.0, 0.16),
				"speed": 700.0,
				"damage": 1,
			})
	if overdrive_time > 0.0:
		shots.append({
			"position": global_position + Vector2(24.0, 0.0),
			"direction": Vector2.RIGHT,
			"speed": 780.0,
			"damage": 2,
		})
	return shots


func _apply_powerup(kind: String = "weapon") -> void:
	match kind:
		"repair":
			hull = min(hull + 1, MAX_HULL)
		"overdrive":
			overdrive_time = 8.0
		_:
			if weapon_level < 3:
				weapon_level += 1
			else:
				hull = min(hull + 1, MAX_HULL)
	_emit_state_changed()


func _apply_damage(amount: int) -> void:
	if _invulnerable_time > 0.0:
		return
	hull -= amount
	_invulnerable_time = 0.95
	if hull > 0:
		feedback_requested.emit("hit", global_position)
		_emit_state_changed()
		return
	lives -= 1
	if lives <= 0:
		_defeated = true
		feedback_requested.emit("destroyed", global_position)
		_emit_state_changed()
		visible = false
		monitoring = false
		emit_signal("defeated")
		return
	hull = MAX_HULL
	position = Vector2(120.0, GameSession.VIEW_SIZE.y * 0.5)
	_invulnerable_time = 2.0
	feedback_requested.emit("respawn", global_position)
	_emit_state_changed()


func _emit_state_changed() -> void:
	state_changed.emit(hull, MAX_HULL, lives, weapon_level, get_status_text())


func get_status_text() -> String:
	if overdrive_time > 0.0:
		return "BOOST"
	return ""


func _draw() -> void:
	var ship_color := GameSession.COLOR_FG
	if _invulnerable_time > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0:
		ship_color = GameSession.COLOR_HIT
	var body := PackedVector2Array([
		Vector2(-14.0, -6.0),
		Vector2(8.0, -6.0),
		Vector2(18.0, 0.0),
		Vector2(8.0, 6.0),
		Vector2(-14.0, 6.0),
	])
	draw_polygon(body, PackedColorArray([ship_color, ship_color, ship_color, ship_color, ship_color]))
	draw_rect(Rect2(Vector2(-18.0, -2.0), Vector2(6.0, 4.0)), ship_color, true)
