extends Area2D

var direction := Vector2.RIGHT
var speed := 620.0
var damage := 1
var from_player := true
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
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16.0, 4.0) if from_player else Vector2(10.0, 4.0)
	shape.shape = rectangle
	add_child(shape)


func _process(delta: float) -> void:
	position += direction * speed * delta
	if global_position.x < -60.0 or global_position.x > GameSession.VIEW_SIZE.x + 60.0:
		queue_free()
	elif global_position.y < -40.0 or global_position.y > GameSession.VIEW_SIZE.y + 40.0:
		queue_free()
	queue_redraw()


func consume() -> void:
	if _consumed:
		return
	_consumed = true
	queue_free()


func _draw() -> void:
	var color := GameSession.COLOR_ALERT if from_player else GameSession.COLOR_DIM
	var size := Vector2(16.0, 4.0) if from_player else Vector2(10.0, 4.0)
	draw_rect(Rect2(-size * 0.5, size), color, true)

