extends Area2D

signal destroyed(score_value: int, burst_position: Vector2)
signal fire_requested(shots: Array)
signal damaged(hit_position: Vector2, enemy_type: String, remaining_hull: int)

var enemy_type := "straight"
var speed := 220.0
var health := 2
var amplitude := 28.0
var frequency := 3.2
var base_y := 0.0
var age := 0.0
var score_value := 100
var shoot_interval := 0.0
var shoot_timer := 0.0
var shot_mode := "single"
var tint := GameSession.COLOR_DIM
var vertical_speed := 0.0
var drift_direction := 1.0
var _dead := false
var _hit_flash_time := 0.0


func setup(config: Dictionary) -> void:
	enemy_type = config.get("enemy_type", enemy_type)
	speed = config.get("speed", speed)
	health = config.get("health", health)
	amplitude = config.get("amplitude", amplitude)
	frequency = config.get("frequency", frequency)
	base_y = config.get("base_y", global_position.y)
	score_value = config.get("score_value", score_value)
	shoot_interval = config.get("shoot_interval", shoot_interval)
	shot_mode = String(config.get("shot_mode", shot_mode))
	tint = config.get("tint", tint)
	vertical_speed = config.get("vertical_speed", vertical_speed)
	drift_direction = config.get("drift_direction", drift_direction)
	shoot_timer = shoot_interval * randf_range(0.3, 1.0)


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemy_ship")
	collision_layer = 2
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(26.0, 18.0)
	shape.shape = rectangle
	add_child(shape)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if _dead:
		return
	age += delta
	_hit_flash_time = max(_hit_flash_time - delta, 0.0)
	position.x -= speed * delta
	match enemy_type:
		"wave":
			position.y = base_y + sin(age * frequency) * amplitude
		"dart":
			position.y += vertical_speed * drift_direction * delta
			if position.y < 92.0 or position.y > GameSession.VIEW_SIZE.y - 84.0:
				drift_direction *= -1.0
		"tank":
			position.y = base_y + sin(age * frequency) * amplitude * 0.35
		"spinner":
			position.y = base_y + sin(age * frequency) * amplitude
		"sentinel":
			position.y = base_y + cos(age * frequency) * amplitude * 0.18
	if shoot_interval > 0.0 and global_position.x < GameSession.VIEW_SIZE.x - 60.0:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer += shoot_interval
			fire_requested.emit(_build_shots())
	if global_position.x < -40.0:
		queue_free()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("player_bullet"):
		if area.has_method("consume"):
			area.consume()
		_apply_damage(area.damage)


func _apply_damage(amount: int) -> void:
	health -= amount
	_hit_flash_time = 0.08
	if health > 0:
		damaged.emit(global_position, enemy_type, health)
	if health <= 0:
		_die(score_value)


func collide_with_player() -> void:
	if _dead:
		return
	_die(0)


func apply_beam_damage(amount: int) -> void:
	if _dead:
		return
	_apply_damage(amount)


func _build_shots() -> Array:
	match shot_mode:
		"aimed":
			return [_enemy_shot(_aim_at_player(), 328.0)]
		"spread":
			return [
				_enemy_shot(Vector2(-1.0, -0.2), 310.0),
				_enemy_shot(Vector2.LEFT, 326.0),
				_enemy_shot(Vector2(-1.0, 0.2), 310.0),
			]
		"cross":
			return [
				_enemy_shot(Vector2(-1.0, -0.26), 320.0),
				_enemy_shot(Vector2(-1.0, -0.08), 336.0),
				_enemy_shot(Vector2(-1.0, 0.08), 336.0),
				_enemy_shot(Vector2(-1.0, 0.26), 320.0),
			]
		"dart":
			return [_enemy_shot(Vector2(-1.0, 0.25 * drift_direction), 312.0)]
		_:
			return [_enemy_shot(Vector2.LEFT, 300.0)]


func _enemy_shot(shot_direction: Vector2, shot_speed: float) -> Dictionary:
	return {
		"position": global_position + Vector2(-18.0, 0.0),
		"direction": shot_direction,
		"speed": shot_speed,
		"damage": 1,
	}


func _aim_at_player() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.LEFT
	var direction := (player.global_position - global_position).normalized()
	if direction.x > -0.5:
		direction = Vector2(-0.5, direction.y).normalized()
	return direction


func _die(points: int) -> void:
	_dead = true
	destroyed.emit(points, global_position)
	queue_free()


func _draw() -> void:
	var draw_tint := GameSession.COLOR_HIT if _hit_flash_time > 0.0 else tint
	match enemy_type:
		"wave":
			var wave_points := PackedVector2Array([
				Vector2(12.0, -9.0),
				Vector2(-4.0, -6.0),
				Vector2(-14.0, 0.0),
				Vector2(-4.0, 6.0),
				Vector2(12.0, 9.0),
				Vector2(2.0, 0.0),
			])
			draw_polygon(wave_points, PackedColorArray([draw_tint, draw_tint, draw_tint, draw_tint, draw_tint, draw_tint]))
		"dart":
			var dart_points := PackedVector2Array([
				Vector2(14.0, 0.0),
				Vector2(-2.0, -8.0),
				Vector2(-14.0, -4.0),
				Vector2(-8.0, 0.0),
				Vector2(-14.0, 4.0),
				Vector2(-2.0, 8.0),
			])
			draw_polygon(dart_points, PackedColorArray([draw_tint, draw_tint, draw_tint, draw_tint, draw_tint, draw_tint]))
		"tank":
			draw_rect(Rect2(Vector2(-14.0, -10.0), Vector2(28.0, 20.0)), draw_tint, true)
			draw_rect(Rect2(Vector2(-20.0, -4.0), Vector2(8.0, 8.0)), draw_tint, true)
		"spinner":
			var spinner_points := PackedVector2Array([
				Vector2(0.0, -12.0),
				Vector2(6.0, -4.0),
				Vector2(14.0, 0.0),
				Vector2(6.0, 4.0),
				Vector2(0.0, 12.0),
				Vector2(-6.0, 4.0),
				Vector2(-14.0, 0.0),
				Vector2(-6.0, -4.0),
			])
			draw_polygon(spinner_points, PackedColorArray([draw_tint, draw_tint, draw_tint, draw_tint, draw_tint, draw_tint, draw_tint, draw_tint]))
			draw_circle(Vector2.ZERO, 3.0, GameSession.COLOR_BG)
		"sentinel":
			draw_rect(Rect2(Vector2(-15.0, -12.0), Vector2(30.0, 24.0)), draw_tint, true)
			draw_rect(Rect2(Vector2(-20.0, -4.0), Vector2(10.0, 8.0)), draw_tint, true)
			draw_rect(Rect2(Vector2(-2.0, -4.0), Vector2(10.0, 8.0)), GameSession.COLOR_BG, true)
			draw_rect(Rect2(Vector2(8.0, -2.0), Vector2(4.0, 4.0)), GameSession.COLOR_HIT, true)
		_:
			var body := PackedVector2Array([
				Vector2(12.0, -7.0),
				Vector2(-4.0, -6.0),
				Vector2(-14.0, 0.0),
				Vector2(-4.0, 6.0),
				Vector2(12.0, 7.0),
			])
			draw_polygon(body, PackedColorArray([draw_tint, draw_tint, draw_tint, draw_tint, draw_tint]))
