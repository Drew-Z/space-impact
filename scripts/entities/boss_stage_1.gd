extends Area2D

signal destroyed(score_value: int, burst_position: Vector2)
signal fire_requested(shots: Array)
signal hull_changed(current_hull: int, max_hull: int)
signal damaged(hit_position: Vector2, current_hull: int, max_hull: int)

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
var _enrage_ratio := 0.33
var _enrage_fire_multiplier := 0.76
var _enrage_move_bonus := 0.28
var _critical_ratio := 0.18
var _critical_fire_multiplier := 0.62
var _critical_move_bonus := 0.48
var _critical_amplitude_bonus := 20.0


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
	_enrage_ratio = float(config.get("enrage_ratio", _enrage_ratio))
	_enrage_fire_multiplier = float(config.get("enrage_fire_multiplier", _enrage_fire_multiplier))
	_enrage_move_bonus = float(config.get("enrage_move_bonus", _enrage_move_bonus))
	_critical_ratio = float(config.get("critical_ratio", _critical_ratio))
	_critical_fire_multiplier = float(config.get("critical_fire_multiplier", _critical_fire_multiplier))
	_critical_move_bonus = float(config.get("critical_move_bonus", _critical_move_bonus))
	_critical_amplitude_bonus = float(config.get("critical_amplitude_bonus", _critical_amplitude_bonus))
	_fire_timer = fire_cooldown


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	collision_layer = 2
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	match profile:
		"carrier":
			rectangle.size = Vector2(116.0, 72.0)
		"fortress":
			rectangle.size = Vector2(128.0, 94.0)
		"reaper":
			rectangle.size = Vector2(94.0, 98.0)
		"bastion":
			rectangle.size = Vector2(104.0, 104.0)
		"overlord":
			rectangle.size = Vector2(156.0, 116.0)
		_:
			rectangle.size = Vector2(94.0, 64.0)
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
		var current_move_speed := move_speed
		if _is_critical():
			current_move_speed += _critical_move_bonus
		elif _is_enraged():
			current_move_speed += _enrage_move_bonus
		var current_amplitude := move_amplitude + (_critical_amplitude_bonus if _is_critical() else 0.0)
		position.y = GameSession.VIEW_SIZE.y * 0.5 + sin(_age * current_move_speed) * current_amplitude
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = _current_fire_cooldown()
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
	damaged.emit(global_position, hull, max_hull)
	if hull <= 0:
		_dead = true
		destroyed.emit(boss_score, global_position)
		queue_free()


func collide_with_player() -> void:
	pass


func apply_beam_damage(amount: int) -> void:
	if _dead:
		return
	_apply_damage(amount)


func _build_attack_pattern() -> Array:
	var enraged := _is_enraged()
	var critical := _is_critical()
	match profile:
		"carrier":
			match _pattern_step % 3:
				0:
					return [
						_shot(Vector2(-62.0, -28.0), Vector2(-1.0, -0.28), 330.0 if not enraged else 360.0),
						_shot(Vector2(-70.0, -10.0), Vector2(-1.0, -0.12), 338.0 if not enraged else 370.0),
						_shot(Vector2(-76.0, 8.0), Vector2.LEFT, 350.0 if not enraged else 382.0),
						_shot(Vector2(-70.0, 26.0), Vector2(-1.0, 0.12), 338.0 if not enraged else 370.0),
						_shot(Vector2(-62.0, 44.0), Vector2(-1.0, 0.28), 330.0 if not enraged else 360.0),
					]
				1:
					return [
						_shot(Vector2(-68.0, -18.0), Vector2(-1.0, -0.04), 382.0 if not enraged else 414.0),
						_shot(Vector2(-68.0, 18.0), Vector2(-1.0, 0.04), 382.0 if not enraged else 414.0),
						_shot(Vector2(-42.0, -36.0), Vector2(-0.94, -0.24), 352.0 if not enraged else 384.0),
						_shot(Vector2(-42.0, 36.0), Vector2(-0.94, 0.24), 352.0 if not enraged else 384.0),
					]
				_:
					var barrage := [
						_shot(Vector2(-74.0, -22.0), _aim_at_player(-12.0), 366.0 if not enraged else 398.0),
						_shot(Vector2(-74.0, 22.0), _aim_at_player(12.0), 366.0 if not enraged else 398.0),
						_shot(Vector2(-84.0, 0.0), Vector2.LEFT, 384.0 if not enraged else 420.0),
					]
					if enraged:
						barrage.append(_shot(Vector2(-54.0, -46.0), Vector2(-0.9, -0.3), 380.0))
						barrage.append(_shot(Vector2(-54.0, 46.0), Vector2(-0.9, 0.3), 380.0))
					return barrage
		"fortress":
			match _pattern_step % 3:
				0:
					return [
						_shot(Vector2(-82.0, -30.0), Vector2.LEFT, 326.0 if not enraged else 356.0),
						_shot(Vector2(-82.0, 0.0), Vector2.LEFT, 340.0 if not enraged else 370.0),
						_shot(Vector2(-82.0, 30.0), Vector2.LEFT, 326.0 if not enraged else 356.0),
						_shot(Vector2(-54.0, -48.0), Vector2(-0.96, -0.18), 314.0 if not enraged else 346.0),
						_shot(Vector2(-54.0, 48.0), Vector2(-0.96, 0.18), 314.0 if not enraged else 346.0),
					]
				1:
					return [
						_shot(Vector2(-86.0, -34.0), Vector2(-1.0, -0.22), 338.0 if not enraged else 372.0),
						_shot(Vector2(-86.0, -12.0), Vector2(-1.0, -0.1), 350.0 if not enraged else 384.0),
						_shot(Vector2(-86.0, 12.0), Vector2(-1.0, 0.1), 350.0 if not enraged else 384.0),
						_shot(Vector2(-86.0, 34.0), Vector2(-1.0, 0.22), 338.0 if not enraged else 372.0),
					]
				_:
					var wall := [
						_shot(Vector2(-88.0, -42.0), _aim_at_player(-20.0), 360.0 if not enraged else 394.0),
						_shot(Vector2(-88.0, 42.0), _aim_at_player(20.0), 360.0 if not enraged else 394.0),
						_shot(Vector2(-60.0, 0.0), Vector2.LEFT, 392.0 if not enraged else 426.0),
					]
					if enraged:
						wall.append(_shot(Vector2(-102.0, 0.0), Vector2.LEFT, 452.0))
					return wall
		"reaper":
			match _pattern_step % 3:
				0:
					return [
						_shot(Vector2(-44.0, -44.0), Vector2(-0.88, -0.36), 364.0 if not enraged else 398.0),
						_shot(Vector2(-54.0, -14.0), Vector2(-1.0, -0.08), 378.0 if not enraged else 412.0),
						_shot(Vector2(-58.0, 14.0), Vector2(-1.0, 0.08), 378.0 if not enraged else 412.0),
						_shot(Vector2(-44.0, 44.0), Vector2(-0.88, 0.36), 364.0 if not enraged else 398.0),
					]
				1:
					var scythes := [
						_shot(Vector2(-68.0, -24.0), _aim_at_player(-18.0), 382.0 if not enraged else 418.0),
						_shot(Vector2(-68.0, 0.0), _aim_at_player(), 392.0 if not enraged else 428.0),
						_shot(Vector2(-68.0, 24.0), _aim_at_player(18.0), 382.0 if not enraged else 418.0),
					]
					if enraged:
						scythes.append(_shot(Vector2(-30.0, -52.0), Vector2(-0.82, -0.42), 406.0))
						scythes.append(_shot(Vector2(-30.0, 52.0), Vector2(-0.82, 0.42), 406.0))
					return scythes
				_:
					return [
						_shot(Vector2(-72.0, -24.0), Vector2.LEFT, 426.0 if not enraged else 462.0),
						_shot(Vector2(-72.0, 0.0), Vector2.LEFT, 438.0 if not enraged else 474.0),
						_shot(Vector2(-72.0, 24.0), Vector2.LEFT, 426.0 if not enraged else 462.0),
						_shot(Vector2(-40.0, -58.0), Vector2(-0.88, -0.28), 380.0 if not enraged else 414.0),
						_shot(Vector2(-40.0, 58.0), Vector2(-0.88, 0.28), 380.0 if not enraged else 414.0),
					]
		"bastion":
			match _pattern_step % 3:
				0:
					return [
						_shot(Vector2(-58.0, -48.0), Vector2(-0.92, -0.3), 340.0 if not enraged else 372.0),
						_shot(Vector2(-72.0, -24.0), Vector2(-1.0, -0.16), 356.0 if not enraged else 388.0),
						_shot(Vector2(-80.0, 0.0), Vector2.LEFT, 372.0 if not enraged else 404.0),
						_shot(Vector2(-72.0, 24.0), Vector2(-1.0, 0.16), 356.0 if not enraged else 388.0),
						_shot(Vector2(-58.0, 48.0), Vector2(-0.92, 0.3), 340.0 if not enraged else 372.0),
					]
				1:
					return [
						_shot(Vector2(-84.0, -36.0), Vector2(-1.0, -0.04), 388.0 if not enraged else 420.0),
						_shot(Vector2(-84.0, -12.0), Vector2(-1.0, -0.12), 368.0 if not enraged else 400.0),
						_shot(Vector2(-84.0, 12.0), Vector2(-1.0, 0.12), 368.0 if not enraged else 400.0),
						_shot(Vector2(-84.0, 36.0), Vector2(-1.0, 0.04), 388.0 if not enraged else 420.0),
					]
				_:
					var core_burst := [
						_shot(Vector2(-62.0, -26.0), _aim_at_player(-18.0), 382.0 if not enraged else 416.0),
						_shot(Vector2(-62.0, 26.0), _aim_at_player(18.0), 382.0 if not enraged else 416.0),
						_shot(Vector2(-92.0, 0.0), Vector2.LEFT, 420.0 if not enraged else 456.0),
					]
					if enraged:
						core_burst.append(_shot(Vector2(-24.0, -60.0), Vector2(-0.84, -0.34), 404.0))
						core_burst.append(_shot(Vector2(-24.0, 60.0), Vector2(-0.84, 0.34), 404.0))
					return core_burst
		"overlord":
			match _pattern_step % (4 if critical else 3):
				0:
					var opening := [
						_shot(Vector2(-92.0, -52.0), Vector2(-0.96, -0.28), 362.0 if not enraged else 398.0),
						_shot(Vector2(-106.0, -30.0), Vector2(-1.0, -0.18), 380.0 if not enraged else 416.0),
						_shot(Vector2(-116.0, -10.0), Vector2(-1.0, -0.08), 396.0 if not enraged else 432.0),
						_shot(Vector2(-122.0, 10.0), Vector2.LEFT, 410.0 if not enraged else 448.0),
						_shot(Vector2(-116.0, 30.0), Vector2(-1.0, 0.08), 396.0 if not enraged else 432.0),
						_shot(Vector2(-106.0, 50.0), Vector2(-1.0, 0.18), 380.0 if not enraged else 416.0),
						_shot(Vector2(-92.0, 72.0), Vector2(-0.96, 0.28), 362.0 if not enraged else 398.0),
					]
					if critical:
						opening.append(_shot(Vector2(-134.0, -2.0), Vector2.LEFT, 500.0, 2))
					return opening
				1:
					var hunt := [
						_shot(Vector2(-86.0, -42.0), _aim_at_player(-26.0), 396.0 if not enraged else 434.0),
						_shot(Vector2(-102.0, 0.0), _aim_at_player(), 424.0 if not enraged else 462.0),
						_shot(Vector2(-86.0, 42.0), _aim_at_player(26.0), 396.0 if not enraged else 434.0),
						_shot(Vector2(-46.0, -70.0), Vector2(-0.82, -0.42), 392.0 if not enraged else 428.0),
						_shot(Vector2(-46.0, 70.0), Vector2(-0.82, 0.42), 392.0 if not enraged else 428.0),
					]
					if enraged:
						hunt.append(_shot(Vector2(-128.0, -14.0), Vector2.LEFT, 488.0))
						hunt.append(_shot(Vector2(-128.0, 14.0), Vector2.LEFT, 488.0))
					if critical:
						hunt.append(_shot(Vector2(-70.0, -78.0), _aim_at_player(-42.0), 448.0))
						hunt.append(_shot(Vector2(-70.0, 78.0), _aim_at_player(42.0), 448.0))
					return hunt
				2:
					var wall := [
						_shot(Vector2(-124.0, -46.0), Vector2(-1.0, -0.14), 426.0 if not enraged else 466.0),
						_shot(Vector2(-124.0, -20.0), Vector2(-1.0, -0.06), 442.0 if not enraged else 482.0),
						_shot(Vector2(-124.0, 0.0), Vector2.LEFT, 458.0 if not enraged else 500.0),
						_shot(Vector2(-124.0, 20.0), Vector2(-1.0, 0.06), 442.0 if not enraged else 482.0),
						_shot(Vector2(-124.0, 46.0), Vector2(-1.0, 0.14), 426.0 if not enraged else 466.0),
						_shot(Vector2(-74.0, -84.0), Vector2(-0.82, -0.34), 382.0 if not enraged else 420.0),
						_shot(Vector2(-74.0, 84.0), Vector2(-0.82, 0.34), 382.0 if not enraged else 420.0),
					]
					if critical:
						wall.append(_shot(Vector2(-148.0, -32.0), Vector2.LEFT, 518.0, 2))
						wall.append(_shot(Vector2(-148.0, 32.0), Vector2.LEFT, 518.0, 2))
					return wall
				_:
					return [
						_shot(Vector2(-118.0, -64.0), Vector2(-0.94, -0.24), 436.0),
						_shot(Vector2(-136.0, -36.0), Vector2(-1.0, -0.12), 468.0),
						_shot(Vector2(-150.0, 0.0), Vector2.LEFT, 532.0, 2),
						_shot(Vector2(-136.0, 36.0), Vector2(-1.0, 0.12), 468.0),
						_shot(Vector2(-118.0, 64.0), Vector2(-0.94, 0.24), 436.0),
						_shot(Vector2(-84.0, -92.0), _aim_at_player(-30.0), 422.0),
						_shot(Vector2(-84.0, 92.0), _aim_at_player(30.0), 422.0),
					]
		_:
			match _pattern_step % 3:
				0:
					return [
						_shot(Vector2(-48.0, -22.0), Vector2(-1.0, -0.18), 326.0 if not enraged else 356.0),
						_shot(Vector2(-58.0, 0.0), Vector2.LEFT, 342.0 if not enraged else 372.0),
						_shot(Vector2(-48.0, 22.0), Vector2(-1.0, 0.18), 326.0 if not enraged else 356.0),
						_shot(Vector2(-38.0, -38.0), Vector2(-0.96, -0.28), 312.0 if not enraged else 340.0),
						_shot(Vector2(-38.0, 38.0), Vector2(-0.96, 0.28), 312.0 if not enraged else 340.0),
					]
				1:
					var aimed := [
						_shot(Vector2(-58.0, -18.0), _aim_at_player(-10.0), 344.0 if not enraged else 374.0),
						_shot(Vector2(-58.0, 18.0), _aim_at_player(10.0), 344.0 if not enraged else 374.0),
						_shot(Vector2(-70.0, 0.0), Vector2.LEFT, 366.0 if not enraged else 398.0),
					]
					if enraged:
						aimed.append(_shot(Vector2(-46.0, 0.0), _aim_at_player(), 412.0))
					return aimed
				_:
					return [
						_shot(Vector2(-60.0, -30.0), Vector2(-1.0, -0.04), 348.0 if not enraged else 380.0),
						_shot(Vector2(-60.0, 30.0), Vector2(-1.0, 0.04), 348.0 if not enraged else 380.0),
						_shot(Vector2(-74.0, 0.0), Vector2.LEFT, 382.0 if not enraged else 416.0),
					]


func _is_enraged() -> bool:
	return max_hull > 0 and float(hull) / float(max_hull) <= _enrage_ratio


func _is_critical() -> bool:
	return max_hull > 0 and float(hull) / float(max_hull) <= _critical_ratio


func _current_fire_cooldown() -> float:
	if _is_critical():
		return fire_cooldown * _critical_fire_multiplier
	if _is_enraged():
		return fire_cooldown * _enrage_fire_multiplier
	return fire_cooldown


func _shot(offset: Vector2, direction: Vector2, speed: float, damage: int = 1) -> Dictionary:
	return {
		"position": global_position + offset,
		"direction": direction.normalized(),
		"speed": speed,
		"damage": damage,
	}


func _aim_at_player(vertical_bias: float = 0.0) -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.LEFT
	var target := player.global_position + Vector2(0.0, vertical_bias)
	var direction := (target - global_position).normalized()
	if direction.x > -0.45:
		direction = Vector2(-0.45, direction.y).normalized()
	return direction


func _draw() -> void:
	var body_color := GameSession.COLOR_HIT if _hit_flash_time > 0.0 else GameSession.COLOR_DIM
	var accent_color := GameSession.COLOR_HIT if _hit_flash_time > 0.0 else GameSession.COLOR_ALERT
	var outline_color := GameSession.COLOR_ALERT if _is_enraged() else body_color
	match profile:
		"carrier":
			draw_rect(Rect2(Vector2(-56.0, -34.0), Vector2(112.0, 68.0)), outline_color, false, 2.0)
			draw_rect(Rect2(Vector2(-54.0, -32.0), Vector2(108.0, 64.0)), body_color, true)
			draw_rect(Rect2(Vector2(-72.0, -18.0), Vector2(20.0, 36.0)), body_color, true)
			draw_rect(Rect2(Vector2(-18.0, -44.0), Vector2(38.0, 18.0)), GameSession.COLOR_FG, true)
			draw_rect(Rect2(Vector2(-18.0, 26.0), Vector2(38.0, 18.0)), GameSession.COLOR_FG, true)
			draw_rect(Rect2(Vector2(28.0, -10.0), Vector2(20.0, 20.0)), accent_color, true)
		"fortress":
			draw_rect(Rect2(Vector2(-64.0, -44.0), Vector2(128.0, 88.0)), outline_color, false, 2.0)
			draw_rect(Rect2(Vector2(-62.0, -42.0), Vector2(124.0, 84.0)), body_color, true)
			draw_rect(Rect2(Vector2(-78.0, -18.0), Vector2(18.0, 36.0)), body_color, true)
			draw_rect(Rect2(Vector2(-8.0, -54.0), Vector2(18.0, 18.0)), GameSession.COLOR_FG, true)
			draw_rect(Rect2(Vector2(14.0, -26.0), Vector2(40.0, 16.0)), GameSession.COLOR_FG, true)
			draw_rect(Rect2(Vector2(10.0, -4.0), Vector2(48.0, 18.0)), accent_color, true)
			draw_rect(Rect2(Vector2(14.0, 22.0), Vector2(40.0, 16.0)), GameSession.COLOR_FG, true)
		"reaper":
			var blade := PackedVector2Array([
				Vector2(26.0, -48.0),
				Vector2(-8.0, -28.0),
				Vector2(-38.0, -8.0),
				Vector2(-58.0, 0.0),
				Vector2(-38.0, 8.0),
				Vector2(-8.0, 28.0),
				Vector2(26.0, 48.0),
				Vector2(8.0, 0.0),
			])
			var blade_outline := blade.duplicate()
			blade_outline.append(blade[0])
			draw_polyline(blade_outline, outline_color, 2.0)
			draw_polygon(blade, PackedColorArray([body_color, body_color, body_color, body_color, body_color, body_color, body_color, body_color]))
			draw_rect(Rect2(Vector2(6.0, -20.0), Vector2(18.0, 12.0)), accent_color, true)
			draw_rect(Rect2(Vector2(6.0, 8.0), Vector2(18.0, 12.0)), accent_color, true)
		"bastion":
			var hull_points := PackedVector2Array([
				Vector2(0.0, -52.0),
				Vector2(40.0, -32.0),
				Vector2(54.0, 0.0),
				Vector2(40.0, 32.0),
				Vector2(0.0, 52.0),
				Vector2(-40.0, 32.0),
				Vector2(-54.0, 0.0),
				Vector2(-40.0, -32.0),
			])
			draw_polygon(hull_points, PackedColorArray([body_color, body_color, body_color, body_color, body_color, body_color, body_color, body_color]))
			var outline := hull_points.duplicate()
			outline.append(hull_points[0])
			draw_polyline(outline, outline_color, 2.0)
			draw_circle(Vector2.ZERO, 24.0, GameSession.COLOR_FG)
			draw_circle(Vector2.ZERO, 10.0, accent_color)
			draw_rect(Rect2(Vector2(-66.0, -8.0), Vector2(20.0, 16.0)), body_color, true)
		"overlord":
			var wing := PackedVector2Array([
				Vector2(62.0, -56.0),
				Vector2(12.0, -72.0),
				Vector2(-78.0, -42.0),
				Vector2(-118.0, -10.0),
				Vector2(-78.0, 42.0),
				Vector2(12.0, 72.0),
				Vector2(62.0, 56.0),
				Vector2(40.0, 0.0),
			])
			draw_polygon(wing, PackedColorArray([body_color, body_color, body_color, body_color, body_color, body_color, body_color, body_color]))
			var wing_outline := wing.duplicate()
			wing_outline.append(wing[0])
			draw_polyline(wing_outline, outline_color, 2.0)
			draw_circle(Vector2.ZERO, 34.0, GameSession.COLOR_FG)
			draw_circle(Vector2.ZERO, 22.0, accent_color)
			draw_circle(Vector2.ZERO, 10.0, GameSession.COLOR_BG)
			draw_rect(Rect2(Vector2(-134.0, -12.0), Vector2(20.0, 24.0)), outline_color, true)
			if _is_critical():
				draw_arc(Vector2.ZERO, 48.0, 0.0, TAU, 48, GameSession.COLOR_HIT, 2.0)
				draw_line(Vector2(-152.0, -18.0), Vector2(72.0, -18.0), GameSession.COLOR_HIT, 1.4)
				draw_line(Vector2(-152.0, 18.0), Vector2(72.0, 18.0), GameSession.COLOR_HIT, 1.4)
			elif _is_enraged():
				draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 40, GameSession.COLOR_ALERT, 2.0)
		_:
			var nose := PackedVector2Array([
				Vector2(-42.0, -20.0),
				Vector2(12.0, -28.0),
				Vector2(42.0, 0.0),
				Vector2(12.0, 28.0),
				Vector2(-42.0, 20.0),
				Vector2(-16.0, 0.0),
			])
			draw_polygon(nose, PackedColorArray([body_color, body_color, body_color, body_color, body_color, body_color]))
			var nose_outline := nose.duplicate()
			nose_outline.append(nose[0])
			draw_polyline(nose_outline, outline_color, 2.0)
			draw_rect(Rect2(Vector2(-56.0, -10.0), Vector2(16.0, 20.0)), body_color, true)
			draw_rect(Rect2(Vector2(14.0, -12.0), Vector2(20.0, 10.0)), GameSession.COLOR_FG, true)
			draw_rect(Rect2(Vector2(14.0, 2.0), Vector2(20.0, 10.0)), accent_color, true)
