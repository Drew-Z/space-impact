extends Node2D

var lifetime := 0.35
var color := GameSession.COLOR_ALERT
var radius := 28.0
var ring_width := 4.0
var mode := "ring"
var _age := 0.0


func setup(config: Dictionary) -> void:
	lifetime = float(config.get("lifetime", lifetime))
	color = config.get("color", color)
	radius = float(config.get("radius", radius))
	ring_width = float(config.get("ring_width", ring_width))
	mode = String(config.get("mode", mode))


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = _age / lifetime
	var draw_color: Color = color
	draw_color.a = 1.0 - t
	var current_radius: float = lerp(radius * 0.35, radius, t)
	if mode == "cross":
		draw_line(Vector2(-current_radius, 0.0), Vector2(current_radius, 0.0), draw_color, ring_width)
		draw_line(Vector2(0.0, -current_radius), Vector2(0.0, current_radius), draw_color, ring_width)
	else:
		draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 24, draw_color, ring_width)
