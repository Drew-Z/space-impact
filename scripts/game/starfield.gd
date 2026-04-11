extends Node2D

var _stars: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 3310
	for index in range(42):
		_stars.append({
			"x": _rng.randf_range(0.0, GameSession.VIEW_SIZE.x),
			"y": _rng.randf_range(38.0, GameSession.VIEW_SIZE.y - 38.0),
			"speed": _rng.randf_range(40.0, 180.0),
			"size": 1 + (index % 2),
		})


func _process(delta: float) -> void:
	for index in range(_stars.size()):
		var star: Dictionary = _stars[index]
		star["x"] = float(star["x"]) - float(star["speed"]) * delta
		if float(star["x"]) < -4.0:
			star["x"] = GameSession.VIEW_SIZE.x + _rng.randf_range(10.0, 120.0)
			star["y"] = _rng.randf_range(42.0, GameSession.VIEW_SIZE.y - 42.0)
			star["speed"] = _rng.randf_range(40.0, 180.0)
		_stars[index] = star
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, GameSession.VIEW_SIZE), GameSession.COLOR_BG, true)
	draw_rect(Rect2(Vector2(8.0, 60.0), Vector2(GameSession.VIEW_SIZE.x - 16.0, GameSession.VIEW_SIZE.y - 104.0)), Color(0.02, 0.05, 0.02, 0.35), false, 2.0)
	for scanline in range(40, int(GameSession.VIEW_SIZE.y), 18):
		draw_line(Vector2(0.0, scanline), Vector2(GameSession.VIEW_SIZE.x, scanline), GameSession.COLOR_GRID, 1.0)
	draw_line(Vector2(0.0, 52.0), Vector2(GameSession.VIEW_SIZE.x, 52.0), GameSession.COLOR_FG, 1.0)
	draw_line(Vector2(0.0, GameSession.VIEW_SIZE.y - 34.0), Vector2(GameSession.VIEW_SIZE.x, GameSession.VIEW_SIZE.y - 34.0), GameSession.COLOR_GRID, 1.0)
	for column in range(60, int(GameSession.VIEW_SIZE.x), 90):
		draw_line(Vector2(column, 58.0), Vector2(column, GameSession.VIEW_SIZE.y - 38.0), Color(0.07, 0.13, 0.07, 0.35), 1.0)
	for star in _stars:
		draw_rect(Rect2(Vector2(float(star["x"]), float(star["y"])), Vector2(int(star["size"]), int(star["size"]))), GameSession.COLOR_FG, true)
