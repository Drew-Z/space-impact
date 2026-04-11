extends Control

var _start_button: Button
var _continue_button: Button
var _settings_button: Button
var _quit_button: Button
var _settings_overlay: Control
var _settings_panel: PanelContainer
var _settings_back_button: Button
var _chinese_button: Button
var _english_button: Button
var _language_buttons: Array[Button] = []


func _ready() -> void:
	AudioDirector.set_music_mode("menu")
	_rebuild_ui()


func _rebuild_ui() -> void:
	_language_buttons.clear()
	for child in get_children():
		child.queue_free()
	_build_ui()
	_wire_settings_navigation()
	_refresh_language_button_state()
	if _settings_overlay != null and _settings_overlay.visible:
		_settings_back_button.grab_focus()
	elif _start_button != null:
		_start_button.grab_focus()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = GameSession.COLOR_BG
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(620.0, 420.0)
	frame.add_theme_stylebox_override("panel", _panel_box())
	center.add_child(frame)

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
	subtitle.text = GameSession.loc("menu_subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	content.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	content.add_child(spacer)

	var summary := Label.new()
	summary.text = GameSession.loc("menu_summary")
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	summary.add_theme_color_override("font_color", GameSession.COLOR_FG)
	content.add_child(summary)

	var best_score := Label.new()
	best_score.text = GameSession.loc("menu_best", [GameSession.high_score, GameSession.total_runs])
	best_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_score.add_theme_font_size_override("font_size", 16)
	best_score.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	content.add_child(best_score)

	var last_run := Label.new()
	if GameSession.total_runs > 0:
		var run_status := GameSession.loc("menu_clear") if GameSession.last_result["victory"] else GameSession.loc("menu_fail")
		last_run.text = GameSession.loc("menu_last_run", [
			run_status,
			int(GameSession.last_result["score"]),
			int(GameSession.last_result["stages_cleared"]),
			int(GameSession.last_result.get("total_stages", 6)),
		])
	else:
		last_run.text = GameSession.loc("menu_no_continue")
	last_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	last_run.add_theme_font_size_override("font_size", 14)
	last_run.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	content.add_child(last_run)

	_start_button = _menu_button(GameSession.loc("menu_start"))
	_start_button.pressed.connect(_start_game)
	content.add_child(_start_button)

	_continue_button = _menu_button(GameSession.loc("menu_continue"))
	_continue_button.disabled = GameSession.max_unlocked_phase <= 1
	_continue_button.pressed.connect(_continue_game)
	content.add_child(_continue_button)

	var continue_hint := Label.new()
	continue_hint.text = GameSession.loc("menu_continue_hint")
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_hint.add_theme_font_size_override("font_size", 12)
	continue_hint.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	continue_hint.visible = not _continue_button.disabled
	content.add_child(continue_hint)

	_settings_button = _menu_button(GameSession.loc("menu_settings"))
	_settings_button.pressed.connect(_open_settings)
	content.add_child(_settings_button)

	_quit_button = _menu_button(GameSession.loc("menu_quit"))
	_quit_button.pressed.connect(_quit_game)
	content.add_child(_quit_button)

	var controls := Label.new()
	controls.text = GameSession.loc("menu_controls")
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	content.add_child(controls)

	_settings_overlay = Control.new()
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.visible = false
	add_child(_settings_overlay)

	var overlay_bg := ColorRect.new()
	overlay_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_bg.color = Color(0.01, 0.02, 0.01, 0.74)
	_settings_overlay.add_child(overlay_bg)

	_settings_panel = _build_settings_panel()
	_settings_overlay.add_child(_settings_panel)


func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(444.0, 260.0)
	panel.add_theme_stylebox_override("panel", _panel_box())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-222.0, -130.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = GameSession.loc("settings_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	layout.add_child(title)

	var language_label := Label.new()
	language_label.text = GameSession.loc("settings_language")
	language_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	language_label.add_theme_font_size_override("font_size", 16)
	language_label.add_theme_color_override("font_color", GameSession.COLOR_FG)
	layout.add_child(language_label)

	var language_row := HBoxContainer.new()
	language_row.alignment = BoxContainer.ALIGNMENT_CENTER
	language_row.add_theme_constant_override("separation", 12)
	layout.add_child(language_row)

	_chinese_button = _menu_button(GameSession.loc("lang_zh"))
	_chinese_button.custom_minimum_size = Vector2(140.0, 42.0)
	_chinese_button.pressed.connect(func() -> void:
		if GameSession.language == "zh":
			return
		GameSession.set_language("zh")
		_rebuild_ui()
		_open_settings()
	)
	language_row.add_child(_chinese_button)
	_language_buttons.append(_chinese_button)

	_english_button = _menu_button(GameSession.loc("lang_en"))
	_english_button.custom_minimum_size = Vector2(140.0, 42.0)
	_english_button.pressed.connect(func() -> void:
		if GameSession.language == "en":
			return
		GameSession.set_language("en")
		_rebuild_ui()
		_open_settings()
	)
	language_row.add_child(_english_button)
	_language_buttons.append(_english_button)

	_settings_back_button = _menu_button(GameSession.loc("menu_back"))
	_settings_back_button.pressed.connect(_close_settings)
	layout.add_child(_settings_back_button)

	var settings_hint := Label.new()
	settings_hint.text = GameSession.loc("settings_hint")
	settings_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_hint.add_theme_font_size_override("font_size", 13)
	settings_hint.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	layout.add_child(settings_hint)

	return panel


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back") and _settings_overlay != null and _settings_overlay.visible:
		_close_settings()


func _start_game() -> void:
	GameSession.begin_new_run()
	AudioDirector.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/game/game_root.tscn")


func _continue_game() -> void:
	if GameSession.max_unlocked_phase <= 1:
		return
	GameSession.begin_continue_run()
	AudioDirector.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/game/game_root.tscn")


func _open_settings() -> void:
	if _settings_overlay == null:
		return
	_settings_overlay.visible = true
	_set_main_menu_enabled(false)
	if GameSession.language == "zh" and _english_button != null:
		_english_button.grab_focus()
		return
	if GameSession.language == "en" and _chinese_button != null:
		_chinese_button.grab_focus()
		return
	_settings_back_button.grab_focus()


func _close_settings() -> void:
	if _settings_overlay == null:
		return
	_settings_overlay.visible = false
	_set_main_menu_enabled(true)
	_settings_button.grab_focus()


func _quit_game() -> void:
	AudioDirector.play_sfx("confirm")
	get_tree().quit()


func _set_main_menu_enabled(enabled: bool) -> void:
	if _start_button != null:
		_start_button.disabled = not enabled
		_start_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if _continue_button != null:
		_continue_button.disabled = not enabled or GameSession.max_unlocked_phase <= 1
		_continue_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if _settings_button != null:
		_settings_button.disabled = not enabled
		_settings_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if _quit_button != null:
		_quit_button.disabled = not enabled
		_quit_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _wire_settings_navigation() -> void:
	if _chinese_button == null or _english_button == null or _settings_back_button == null:
		return
	var chinese_path := _chinese_button.get_path()
	var english_path := _english_button.get_path()
	var back_path := _settings_back_button.get_path()
	_chinese_button.focus_neighbor_right = english_path
	_chinese_button.focus_neighbor_left = english_path
	_chinese_button.focus_neighbor_bottom = back_path
	_english_button.focus_neighbor_left = chinese_path
	_english_button.focus_neighbor_right = chinese_path
	_english_button.focus_neighbor_bottom = back_path
	_settings_back_button.focus_neighbor_top = english_path if GameSession.language == "zh" else chinese_path


func _refresh_language_button_state() -> void:
	if _chinese_button == null or _english_button == null:
		return
	if GameSession.language == "zh":
		_chinese_button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_DIM))
		_chinese_button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_ALERT))
		_chinese_button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_ALERT))
		_english_button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_GRID))
		_english_button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_DIM))
		_english_button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_DIM))
	else:
		_english_button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_DIM))
		_english_button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_ALERT))
		_english_button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_ALERT))
		_chinese_button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_GRID))
		_chinese_button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_DIM))
		_chinese_button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_DIM))


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(240.0, 46.0)
	button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_GRID))
	button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_DIM))
	button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_DIM))
	button.add_theme_stylebox_override("pressed", _button_box(GameSession.COLOR_ALERT))
	button.add_theme_color_override("font_color", GameSession.COLOR_FG)
	button.add_theme_color_override("font_hover_color", GameSession.COLOR_FG)
	button.add_theme_color_override("font_focus_color", GameSession.COLOR_FG)
	button.add_theme_color_override("font_pressed_color", GameSession.COLOR_BG)
	button.add_theme_color_override("font_disabled_color", GameSession.COLOR_DIM)
	return button


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
