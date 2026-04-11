extends Control

var _restart_button: Button
var _menu_button: Button


func _ready() -> void:
	AudioDirector.set_music_mode("victory" if GameSession.last_result["victory"] else "defeat")
	_build_ui()
	_restart_button.grab_focus()


func _build_ui() -> void:
	var result: Dictionary = GameSession.last_result

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = GameSession.COLOR_BG
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(560.0, 360.0)
	frame.add_theme_stylebox_override("panel", _panel_box())
	center.add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	frame.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var headline := Label.new()
	headline.text = GameSession.loc("result_clear") if result["victory"] else GameSession.loc("result_failed")
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 32)
	headline.add_theme_color_override("font_color", GameSession.COLOR_ALERT if result["victory"] else GameSession.COLOR_HIT)
	content.add_child(headline)

	var score_label := Label.new()
	score_label.text = GameSession.loc("result_score", [int(result["score"])])
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", GameSession.COLOR_FG)
	content.add_child(score_label)

	var detail_label := Label.new()
	detail_label.text = GameSession.loc("result_detail", [
		float(result["time"]),
		GameSession.weapon_label(int(result["weapon_level"])),
		int(result["lives_left"]),
	])
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 16)
	detail_label.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	content.add_child(detail_label)

	var note := Label.new()
	note.text = GameSession.loc("result_note", [
		int(result["stage_reached"]),
		int(result["stages_cleared"]),
		int(result.get("total_stages", 6)),
	])
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", GameSession.COLOR_FG)
	content.add_child(note)

	var best_label := Label.new()
	best_label.text = GameSession.loc("result_best", [
		int(result["best_score"]),
		GameSession.loc("result_new_record") if result["new_record"] else "",
	])
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 16)
	best_label.add_theme_color_override("font_color", GameSession.COLOR_ALERT if result["new_record"] else GameSession.COLOR_DIM)
	content.add_child(best_label)

	_restart_button = Button.new()
	_restart_button.text = GameSession.loc("result_again")
	_restart_button.focus_mode = Control.FOCUS_ALL
	_restart_button.custom_minimum_size = Vector2(220.0, 44.0)
	_restart_button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_GRID))
	_restart_button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_DIM))
	_restart_button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_DIM))
	_restart_button.add_theme_stylebox_override("pressed", _button_box(GameSession.COLOR_ALERT))
	_restart_button.add_theme_color_override("font_color", GameSession.COLOR_FG)
	_restart_button.add_theme_color_override("font_pressed_color", GameSession.COLOR_BG)
	_restart_button.pressed.connect(_restart)
	content.add_child(_restart_button)

	_menu_button = Button.new()
	_menu_button.text = GameSession.loc("result_menu")
	_menu_button.focus_mode = Control.FOCUS_ALL
	_menu_button.custom_minimum_size = Vector2(220.0, 44.0)
	_menu_button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_GRID))
	_menu_button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_DIM))
	_menu_button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_DIM))
	_menu_button.add_theme_stylebox_override("pressed", _button_box(GameSession.COLOR_ALERT))
	_menu_button.add_theme_color_override("font_color", GameSession.COLOR_FG)
	_menu_button.add_theme_color_override("font_pressed_color", GameSession.COLOR_BG)
	_menu_button.pressed.connect(_return_to_menu)
	content.add_child(_menu_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		_return_to_menu()
	elif event.is_action_pressed("confirm") and _menu_button.has_focus():
		_return_to_menu()
	elif event.is_action_pressed("confirm"):
		_restart()


func _restart() -> void:
	AudioDirector.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/game/game_root.tscn")


func _return_to_menu() -> void:
	AudioDirector.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _panel_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.09, 0.05, 0.96)
	style.border_color = GameSession.COLOR_FG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	return style


func _button_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = GameSession.COLOR_FG
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	return style
