extends Area2D

signal destroyed(score_value: int, burst_position: Vector2)
signal fire_requested(shots: Array)
signal hull_changed(current_hull: int, max_hull: int)

var max_hull := 34
var hull := 34
var profile := "striker"
var move_amplitude := 110.0
var move_speed := 1.6
var entry_speed := 120.0
var fire_cooldown := 1.1
var boss_score := 2000
var _age := 0.0
var _target_x := 760.0
var _fire_timer := 1.2
var _pattern_step := 0
var _dead := false
var _hit_flash_time := 0.0


func setup(config: Dictionary) -> void:
	profile = String(config.get("profile", profile))
	max_hull = int(config.get("max_hull", max_hull))
	hull = max_hull
	move_amplitude = float(config.get("move_amplitude", move_amplitude))
	move_speed = float(config.get("move_speed", move_speed))
	entry_speed = float(config.get("entry_speed", entry_speed))
	fire_cooldown = float(config.get("fire_cooldown", fire_cooldown))
	boss_score = int(config.get("score_value", boss_score))
	_target_x = float(config.get("target_x", _target_x))
	_fire_timer = fire_cooldown


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	collision_layer = 2
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(92.0, 64.0) if profile == "striker" else Vector2(112.0, 76.0)
	shape.shape = rectangle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	hull_changed.emit(hull, max_hull)


func _process(delta: float) -> void:
	if _dead:
		return
	_hit_flash_time = max(_hit_flash_time - delta, 0.0)
	if position.x > _target_x:
		position.x -= entry_speed * delta
	else:
		_age += delta
		position.y = GameSession.VIEW_SIZE.y * 0.5 + sin(_age * move_speed) * move_amplitude
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = fire_cooldown
			fire_requested.emit(_build_attack_pattern())
			_pattern_step += 1
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("player_bullet"):
		if area.has_method("consume"):
			area.consume()
		_apply_damage(area.damage)


func _apply_damage(amount: int) -> void:
	hull = max(hull - amount, 0)
	_hit_flash_time = 0.12
	hull_changed.emit(hull, max_hull)
	if hull <= 0:
		_dead = true
		destroyed.emit(boss_score, global_position)
		queue_free()


func collide_with_player() -> void:
	pass


func _build_attack_pattern() -> Array:
	if profile == "carrier":
		if _pattern_step % 2 == 0:
			return [
				{
					"position": global_position + Vector2(-60.0, -24.0),
					"direction": Vector2(-1.0, -0.28),
					"speed": 330.0,
					"damage": 1,
				},
				{
					"position": global_position + Vector2(-66.0, -8.0),
					"direction": Vector2(-1.0, -0.12),
					"speed": 330.0,
					"damage": 1,
				},
				{
					"position": global_position + Vector2(-70.0, 8.0),
					"direction": Vector2.LEFT,
					"speed": 330.0,
					"damage": 1,
				},
				{
					"position": global_position + Vector2(-66.0, 24.0),
					"direction": Vector2(-1.0, 0.12),
					"speed": 330.0,
					"damage": 1,
				},
				{
					"position": global_position + Vector2(-60.0, 40.0),
					"direction": Vector2(-1.0, 0.28),
					"speed": 330.0,
					"damage": 1,
				},
			]
		return [
			{
				"position": global_position + Vector2(-64.0, -18.0),
				"direction": Vector2(-1.0, -0.08),
				"speed": 380.0,
				"damage": 1,
			},
			{
				"position": global_position + Vector2(-64.0, 18.0),
				"direction": Vector2(-1.0, 0.08),
				"speed": 380.0,
				"damage": 1,
			},
			{
				"position": global_position + Vector2(-36.0, -36.0),
				"direction": Vector2(-0.96, -0.26),
				"speed": 350.0,
				"damage": 1,
			},
			{
				"position": global_position + Vector2(-36.0, 36.0),
				"direction": Vector2(-0.96, 0.26),
				"speed": 350.0,
				"damage": 1,
			},
		]
	return [
		{
			"position": global_position + Vector2(-52.0, -18.0),
			"direction": Vector2(-1.0, -0.18),
			"speed": 320.0,
			"damage": 1,
		},
		{
			"position": global_position + Vector2(-58.0, 0.0),
			"direction": Vector2.LEFT,
			"speed": 320.0,
			"damage": 1,
		},
		{
			"position": global_position + Vector2(-52.0, 18.0),
			"direction": Vector2(-1.0, 0.18),
			"speed": 320.0,
			"damage": 1,
		},
	]


func _draw() -> void:
	var body_color := GameSession.COLOR_HIT if _hit_flash_time > 0.0 else GameSession.COLOR_DIM
	var accent_color := GameSession.COLOR_HIT if _hit_flash_time > 0.0 else GameSession.COLOR_ALERT
	if profile == "carrier":
		draw_rect(Rect2(Vector2(-52.0, -32.0), Vector2(104.0, 64.0)), body_color, true)
		draw_rect(Rect2(Vector2(-64.0, -20.0), Vector2(18.0, 40.0)), body_color, true)
		draw_rect(Rect2(Vector2(-18.0, -42.0), Vector2(34.0, 18.0)), GameSession.COLOR_FG, true)
		draw_rect(Rect2(Vector2(-18.0, 24.0), Vector2(34.0, 18.0)), GameSession.COLOR_FG, true)
		draw_rect(Rect2(Vector2(30.0, -10.0), Vector2(18.0, 20.0)), accent_color, true)
	else:
		draw_rect(Rect2(Vector2(-44.0, -28.0), Vector2(88.0, 56.0)), body_color, true)
		draw_rect(Rect2(Vector2(-56.0, -12.0), Vector2(18.0, 24.0)), body_color, true)
		draw_rect(Rect2(Vector2(20.0, -16.0), Vector2(24.0, 12.0)), GameSession.COLOR_FG, true)
		draw_rect(Rect2(Vector2(20.0, 4.0), Vector2(24.0, 12.0)), GameSession.COLOR_FG, true)
