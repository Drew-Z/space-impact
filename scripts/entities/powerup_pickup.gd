extends Area2D

var kind := "weapon"
var speed := 160.0
var _age := 0.0


func setup(config: Dictionary) -> void:
	kind = String(config.get("kind", kind))
	speed = float(config.get("speed", speed))


func _ready() -> void:
	add_to_group("powerup")
	collision_layer = 16
	collision_mask = 1
	call_deferred("_install_collision_shape")


func _install_collision_shape() -> void:
	if get_child_count() > 0:
		return
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_age += delta
	position.x -= speed * delta
	position.y += sin(_age * 4.0) * 12.0 * delta
	if global_position.x < -40.0:
		queue_free()
	queue_redraw()


func collect() -> String:
	var picked_kind := kind
	queue_free()
	return picked_kind


func _draw() -> void:
	match kind:
		"repair":
			draw_rect(Rect2(Vector2(-12.0, -12.0), Vector2(24.0, 24.0)), GameSession.COLOR_FG, true)
			draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), GameSession.COLOR_BG, 2.0)
			draw_line(Vector2(0.0, -6.0), Vector2(0.0, 6.0), GameSession.COLOR_BG, 2.0)
		"shield":
			draw_circle(Vector2.ZERO, 13.0, GameSession.COLOR_GRID)
			draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 28, GameSession.COLOR_ALERT, 2.0)
			draw_circle(Vector2.ZERO, 6.0, GameSession.COLOR_FG)
		"overdrive":
			var overdrive_points := PackedVector2Array([
				Vector2(-8.0, -14.0),
				Vector2(2.0, -2.0),
				Vector2(-2.0, -2.0),
				Vector2(8.0, 14.0),
				Vector2(-4.0, 2.0),
				Vector2(0.0, 2.0),
			])
			draw_polygon(overdrive_points, PackedColorArray([
				GameSession.COLOR_ALERT,
				GameSession.COLOR_ALERT,
				GameSession.COLOR_ALERT,
				GameSession.COLOR_ALERT,
				GameSession.COLOR_ALERT,
				GameSession.COLOR_ALERT,
			]))
		_:
			var points := PackedVector2Array([
				Vector2(0.0, -14.0),
				Vector2(14.0, 0.0),
				Vector2(0.0, 14.0),
				Vector2(-14.0, 0.0),
			])
			draw_polygon(points, PackedColorArray([GameSession.COLOR_ALERT, GameSession.COLOR_ALERT, GameSession.COLOR_ALERT, GameSession.COLOR_ALERT]))
			draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), GameSession.COLOR_BG, 2.0)
			draw_line(Vector2(0.0, -6.0), Vector2(0.0, 6.0), GameSession.COLOR_BG, 2.0)
