extends Area2D

var direction := Vector2.RIGHT
var speed := 620.0
var damage := 1
var from_player := true
var player_visual_size := Vector2(18.0, 4.0)
var player_core_size := Vector2(7.0, 6.0)
var player_trail_length := 8.0
var player_beam := false
var life_time := -1.0
var beam_tick_interval := 0.12
var _beam_tick_timer := 0.0
var _collision_shape: CollisionShape2D
var _rectangle: RectangleShape2D
var _consumed := false


func setup(start_position: Vector2, move_direction: Vector2, bullet_speed: float, bullet_damage: int, is_from_player: bool) -> void:
	global_position = start_position
	direction = move_direction.normalized()
	speed = bullet_speed
	damage = bullet_damage
	from_player = is_from_player


func _ready() -> void:
	if from_player:
		add_to_group("player_bullet")
		collision_layer = 4
		collision_mask = 2
	else:
		add_to_group("enemy_bullet")
		collision_layer = 8
		collision_mask = 1
	_collision_shape = CollisionShape2D.new()
	_rectangle = RectangleShape2D.new()
	_rectangle.size = player_visual_size if from_player else Vector2(12.0, 8.0)
	_collision_shape.shape = _rectangle
	add_child(_collision_shape)


func _process(delta: float) -> void:
	if life_time > 0.0:
		life_time = max(life_time - delta, 0.0)
		if life_time == 0.0:
			queue_free()
			return
	if player_beam:
		_refresh_collision_shape()
		_beam_tick_timer = max(_beam_tick_timer - delta, 0.0)
		if _beam_tick_timer == 0.0:
			_beam_tick_timer = beam_tick_interval
			_apply_beam_damage()
	position += direction * speed * delta
	if global_position.x < -60.0 or global_position.x > GameSession.VIEW_SIZE.x + 60.0:
		queue_free()
	elif global_position.y < -40.0 or global_position.y > GameSession.VIEW_SIZE.y + 40.0:
		queue_free()
	queue_redraw()


func consume() -> void:
	if _consumed:
		return
	if player_beam:
		return
	_consumed = true
	queue_free()


func refresh_player_visual(visual_size: Vector2, core_size: Vector2, trail_length: float, is_beam: bool, tick_interval: float = 0.12) -> void:
	player_visual_size = visual_size
	player_core_size = core_size
	player_trail_length = trail_length
	player_beam = is_beam
	beam_tick_interval = tick_interval
	_refresh_collision_shape()


func _refresh_collision_shape() -> void:
	if _rectangle == null:
		return
	_rectangle.size = player_visual_size if from_player else Vector2(12.0, 8.0)


func _apply_beam_damage() -> void:
	for area in get_overlapping_areas():
		if area == null:
			continue
		if area.has_method("apply_beam_damage"):
			area.apply_beam_damage(damage)


func _draw() -> void:
	if from_player:
		if player_beam:
			var half_size := player_visual_size * 0.5
			var shell_color := Color(GameSession.COLOR_DIM.r, GameSession.COLOR_DIM.g, GameSession.COLOR_DIM.b, 0.72)
			var beam_color := Color(GameSession.COLOR_ALERT.r, GameSession.COLOR_ALERT.g, GameSession.COLOR_ALERT.b, 0.96)
			draw_rect(Rect2(-half_size, player_visual_size), shell_color, true)
			draw_rect(
				Rect2(
					Vector2(-half_size.x, -player_visual_size.y * 0.34),
					Vector2(player_visual_size.x, player_visual_size.y * 0.68)
				),
				beam_color,
				true
			)
			var core_rect := Rect2(
				Vector2(-player_visual_size.x * 0.48, -player_core_size.y * 0.5),
				Vector2(player_visual_size.x * 0.96, player_core_size.y)
			)
			draw_rect(core_rect, GameSession.COLOR_HIT, true)
			draw_circle(Vector2(-half_size.x + 6.0, 0.0), max(player_visual_size.y * 0.42, 3.0), GameSession.COLOR_HIT)
			draw_line(
				Vector2(-half_size.x, -player_visual_size.y * 0.5),
				Vector2(half_size.x, -player_visual_size.y * 0.5),
				GameSession.COLOR_HIT,
				1.2
			)
			draw_line(
				Vector2(-half_size.x, player_visual_size.y * 0.5),
				Vector2(half_size.x, player_visual_size.y * 0.5),
				GameSession.COLOR_HIT,
				1.2
			)
			return
		var size := player_visual_size
		draw_rect(Rect2(-size * 0.5, size), GameSession.COLOR_ALERT, true)
		var core_offset := Vector2(
			max(size.x * 0.16, 2.0),
			-player_core_size.y * 0.5
		)
		draw_rect(Rect2(core_offset, player_core_size), GameSession.COLOR_HIT, true)
		draw_line(
			Vector2(-size.x * 0.5 - player_trail_length, 0.0),
			Vector2(-size.x * 0.5 + 2.0, 0.0),
			GameSession.COLOR_DIM,
			max(size.y * 0.3, 1.5)
		)
		return

	var pulse_color := GameSession.COLOR_HIT if int(Time.get_ticks_msec() / 90) % 2 == 0 else GameSession.COLOR_ALERT
	var outer_diamond := PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(8.0, 0.0),
		Vector2(0.0, 7.0),
		Vector2(-8.0, 0.0),
	])
	var inner_diamond := PackedVector2Array([
		Vector2(0.0, -4.0),
		Vector2(4.5, 0.0),
		Vector2(0.0, 4.0),
		Vector2(-4.5, 0.0),
	])
	draw_polygon(outer_diamond, PackedColorArray([
		pulse_color,
		pulse_color,
		pulse_color,
		pulse_color,
	]))
	draw_polygon(inner_diamond, PackedColorArray([
		GameSession.COLOR_DIM,
		GameSession.COLOR_DIM,
		GameSession.COLOR_DIM,
		GameSession.COLOR_DIM,
	]))
	draw_circle(Vector2.ZERO, 1.8, GameSession.COLOR_HIT)
