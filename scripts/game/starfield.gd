extends Node2D

var _stars: Array = []
var _rng := RandomNumberGenerator.new()
var _theme := {
	"background": GameSession.COLOR_BG,
	"frame": Color(0.02, 0.05, 0.02, 0.35),
	"grid": GameSession.COLOR_GRID,
	"border_top": GameSession.COLOR_FG,
	"border_bottom": GameSession.COLOR_GRID,
	"column": Color(0.07, 0.13, 0.07, 0.35),
	"star": GameSession.COLOR_FG,
	"stars": 42,
	"scanline_step": 18,
	"column_step": 90,
	"band_color": Color(0.08, 0.14, 0.08, 0.0),
	"band_height": 0.0,
	"band_y": 0.0,
}


func _ready() -> void:
	_rng.seed = 3310
	_rebuild_stars()


func setup_theme(theme: Dictionary) -> void:
	for key in theme.keys():
		_theme[key] = theme[key]
	_rebuild_stars()
	queue_redraw()


func _rebuild_stars() -> void:
	_stars.clear()
	var star_count := int(_theme.get("stars", 42))
	for index in range(star_count):
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
	draw_rect(Rect2(Vector2.ZERO, GameSession.VIEW_SIZE), _theme["background"], true)
	var band_height := float(_theme.get("band_height", 0.0))
	if band_height > 0.0:
		draw_rect(
			Rect2(
				Vector2(0.0, float(_theme.get("band_y", 180.0))),
				Vector2(GameSession.VIEW_SIZE.x, band_height)
			),
			_theme["band_color"],
			true
		)
	draw_rect(Rect2(Vector2(8.0, 60.0), Vector2(GameSession.VIEW_SIZE.x - 16.0, GameSession.VIEW_SIZE.y - 104.0)), _theme["frame"], false, 2.0)
	for scanline in range(40, int(GameSession.VIEW_SIZE.y), int(_theme.get("scanline_step", 18))):
		draw_line(Vector2(0.0, scanline), Vector2(GameSession.VIEW_SIZE.x, scanline), _theme["grid"], 1.0)
	draw_line(Vector2(0.0, 52.0), Vector2(GameSession.VIEW_SIZE.x, 52.0), _theme["border_top"], 1.0)
	draw_line(Vector2(0.0, GameSession.VIEW_SIZE.y - 34.0), Vector2(GameSession.VIEW_SIZE.x, GameSession.VIEW_SIZE.y - 34.0), _theme["border_bottom"], 1.0)
	for column in range(60, int(GameSession.VIEW_SIZE.x), int(_theme.get("column_step", 90))):
		draw_line(Vector2(column, 58.0), Vector2(column, GameSession.VIEW_SIZE.y - 38.0), _theme["column"], 1.0)
	for star in _stars:
		draw_rect(Rect2(Vector2(float(star["x"]), float(star["y"])), Vector2(int(star["size"]), int(star["size"]))), _theme["star"], true)
