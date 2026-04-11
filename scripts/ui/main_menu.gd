extends Control

var _start_button: Button


func _ready() -> void:
	AudioDirector.set_music_mode("menu")
	_build_ui()
	_start_button.grab_focus()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = GameSession.COLOR_BG
	add_child(background)

	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.custom_minimum_size = Vector2(560.0, 360.0)
	frame.position = Vector2(200.0, 90.0)
	frame.add_theme_stylebox_override("panel", _panel_box())
	add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	frame.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title := Label.new()
	title.text = "SPACE WAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GameSession.COLOR_FG)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Nokia 3310 Space Impact inspired remake prototype"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	content.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 12.0)
	content.add_child(spacer)

	var summary := Label.new()
	summary.text = "Two-sector arcade run\\nPush through enemy formations, collect upgrades, defeat two bosses."
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	summary.add_theme_color_override("font_color", GameSession.COLOR_FG)
	content.add_child(summary)

	var best_score := Label.new()
	best_score.text = "BEST SCORE %06d   RUNS %d" % [GameSession.high_score, GameSession.total_runs]
	best_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_score.add_theme_font_size_override("font_size", 16)
	best_score.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	content.add_child(best_score)

	if GameSession.total_runs > 0:
		var last_run := Label.new()
		last_run.text = "Last Run: %s   Score %06d   Cleared %d/2" % [
			"Clear" if GameSession.last_result["victory"] else "Fail",
			int(GameSession.last_result["score"]),
			int(GameSession.last_result["stages_cleared"]),
		]
		last_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		last_run.add_theme_font_size_override("font_size", 14)
		last_run.add_theme_color_override("font_color", GameSession.COLOR_DIM)
		content.add_child(last_run)

	_start_button = Button.new()
	_start_button.text = "START MISSION"
	_start_button.focus_mode = Control.FOCUS_ALL
	_start_button.custom_minimum_size = Vector2(220.0, 46.0)
	_start_button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_GRID))
	_start_button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_DIM))
	_start_button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_DIM))
	_start_button.add_theme_stylebox_override("pressed", _button_box(GameSession.COLOR_ALERT))
	_start_button.add_theme_color_override("font_color", GameSession.COLOR_FG)
	_start_button.add_theme_color_override("font_hover_color", GameSession.COLOR_FG)
	_start_button.add_theme_color_override("font_focus_color", GameSession.COLOR_FG)
	_start_button.add_theme_color_override("font_pressed_color", GameSession.COLOR_BG)
	_start_button.pressed.connect(_start_game)
	content.add_child(_start_button)

	var controls := Label.new()
	controls.text = "Move: WASD / Arrow Keys\\nFire / Confirm: Space or Z\\nPause: Esc / P"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	content.add_child(controls)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") or event.is_action_pressed("fire"):
		_start_game()


func _start_game() -> void:
	AudioDirector.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/game/game_root.tscn")


func _panel_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.09, 0.05, 0.96)
	style.border_color = GameSession.COLOR_FG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.expand_margin_left = 2.0
	style.expand_margin_top = 2.0
	style.expand_margin_right = 2.0
	style.expand_margin_bottom = 2.0
	return style


func _button_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = GameSession.COLOR_FG
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	return style
