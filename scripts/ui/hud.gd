extends CanvasLayer

signal resume_requested
signal restart_requested
signal menu_requested

var _stats_label: Label
var _phase_label: Label
var _boss_label: Label
var _stage_label: Label
var _notice_label: Label
var _center_label: Label
var _danger_label: Label
var _danger_sub_label: Label
var _footer_label: Label
var _progress_fill: ColorRect
var _flash_rect: ColorRect
var _pause_panel: PanelContainer
var _pause_info: Label
var _pause_resume_button: Button

var _center_timer := 0.0
var _notice_timer := 0.0
var _flash_timer := 0.0
var _danger_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _process(delta: float) -> void:
	if _center_timer > 0.0:
		_center_timer = max(_center_timer - delta, 0.0)
		if _center_timer == 0.0:
			_center_label.visible = false
	if _notice_timer > 0.0:
		_notice_timer = max(_notice_timer - delta, 0.0)
		if _notice_timer == 0.0:
			_notice_label.visible = false
	if _flash_timer > 0.0:
		_flash_timer = max(_flash_timer - delta, 0.0)
		_flash_rect.modulate.a = _flash_timer / 0.18
		if _flash_timer == 0.0:
			_flash_rect.visible = false
	if _danger_timer > 0.0:
		_danger_timer = max(_danger_timer - delta, 0.0)
		var pulse_alpha: float = 0.26 + 0.24 * abs(sin(Time.get_ticks_msec() / 120.0))
		_flash_rect.modulate.a = pulse_alpha
		if _danger_label != null:
			_danger_label.modulate.a = 0.66 + 0.34 * abs(sin(Time.get_ticks_msec() / 130.0))
		if _danger_sub_label != null:
			_danger_sub_label.modulate.a = 0.44 + 0.28 * abs(sin(Time.get_ticks_msec() / 140.0))
		if _danger_timer == 0.0:
			_flash_rect.visible = false
			_danger_label.visible = false
			_danger_sub_label.visible = false


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var top_bar := ColorRect.new()
	top_bar.color = Color(0.02, 0.04, 0.02, 0.9)
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(GameSession.VIEW_SIZE.x, 64.0)
	root.add_child(top_bar)

	var bottom_bar := ColorRect.new()
	bottom_bar.color = Color(0.02, 0.04, 0.02, 0.82)
	bottom_bar.position = Vector2(0.0, GameSession.VIEW_SIZE.y - 38.0)
	bottom_bar.size = Vector2(GameSession.VIEW_SIZE.x, 38.0)
	root.add_child(bottom_bar)

	_stats_label = Label.new()
	_stats_label.position = Vector2(22.0, 12.0)
	_stats_label.size = Vector2(620.0, 22.0)
	_stats_label.add_theme_font_size_override("font_size", 18)
	_stats_label.add_theme_color_override("font_color", GameSession.COLOR_FG)
	root.add_child(_stats_label)

	_phase_label = Label.new()
	_phase_label.position = Vector2(652.0, 12.0)
	_phase_label.size = Vector2(286.0, 22.0)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase_label.add_theme_font_size_override("font_size", 18)
	_phase_label.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	root.add_child(_phase_label)

	var progress_track := ColorRect.new()
	progress_track.position = Vector2(22.0, 42.0)
	progress_track.size = Vector2(260.0, 8.0)
	progress_track.color = GameSession.COLOR_GRID
	root.add_child(progress_track)

	_progress_fill = ColorRect.new()
	_progress_fill.position = Vector2(22.0, 42.0)
	_progress_fill.size = Vector2(0.0, 8.0)
	_progress_fill.color = GameSession.COLOR_ALERT
	root.add_child(_progress_fill)

	_stage_label = Label.new()
	_stage_label.position = Vector2(294.0, 33.0)
	_stage_label.size = Vector2(340.0, 22.0)
	_stage_label.add_theme_font_size_override("font_size", 14)
	_stage_label.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	root.add_child(_stage_label)

	_boss_label = Label.new()
	_boss_label.position = Vector2(240.0, 72.0)
	_boss_label.size = Vector2(480.0, 24.0)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.visible = false
	_boss_label.add_theme_font_size_override("font_size", 16)
	_boss_label.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	root.add_child(_boss_label)

	_center_label = Label.new()
	_center_label.position = Vector2(160.0, 124.0)
	_center_label.size = Vector2(640.0, 36.0)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.visible = false
	_center_label.add_theme_font_size_override("font_size", 26)
	_center_label.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	root.add_child(_center_label)

	_danger_label = Label.new()
	_danger_label.position = Vector2(80.0, 188.0)
	_danger_label.size = Vector2(800.0, 72.0)
	_danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_danger_label.visible = false
	_danger_label.text = GameSession.loc("dangerous")
	_danger_label.add_theme_font_size_override("font_size", 54)
	_danger_label.add_theme_color_override("font_color", GameSession.COLOR_HIT)
	root.add_child(_danger_label)

	_danger_sub_label = Label.new()
	_danger_sub_label.position = Vector2(200.0, 256.0)
	_danger_sub_label.size = Vector2(560.0, 28.0)
	_danger_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_danger_sub_label.visible = false
	_danger_sub_label.text = GameSession.loc("dangerous_sub")
	_danger_sub_label.add_theme_font_size_override("font_size", 18)
	_danger_sub_label.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	root.add_child(_danger_sub_label)

	_notice_label = Label.new()
	_notice_label.position = Vector2(270.0, GameSession.VIEW_SIZE.y - 72.0)
	_notice_label.size = Vector2(420.0, 22.0)
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_label.visible = false
	_notice_label.add_theme_font_size_override("font_size", 16)
	_notice_label.add_theme_color_override("font_color", GameSession.COLOR_FG)
	root.add_child(_notice_label)

	_footer_label = Label.new()
	_footer_label.position = Vector2(16.0, GameSession.VIEW_SIZE.y - 31.0)
	_footer_label.size = Vector2(920.0, 16.0)
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_label.text = GameSession.loc("hud_footer")
	_footer_label.add_theme_font_size_override("font_size", 13)
	_footer_label.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	root.add_child(_footer_label)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = GameSession.COLOR_HIT
	_flash_rect.visible = false
	root.add_child(_flash_rect)

	_pause_panel = PanelContainer.new()
	_pause_panel.visible = false
	_pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_panel.position = Vector2(300.0, 136.0)
	_pause_panel.custom_minimum_size = Vector2(360.0, 260.0)
	_pause_panel.add_theme_stylebox_override("panel", _panel_box())
	root.add_child(_pause_panel)

	var pause_margin := MarginContainer.new()
	pause_margin.add_theme_constant_override("margin_left", 28)
	pause_margin.add_theme_constant_override("margin_top", 24)
	pause_margin.add_theme_constant_override("margin_right", 28)
	pause_margin.add_theme_constant_override("margin_bottom", 24)
	_pause_panel.add_child(pause_margin)

	var pause_layout := VBoxContainer.new()
	pause_layout.add_theme_constant_override("separation", 12)
	pause_margin.add_child(pause_layout)

	var pause_title := Label.new()
	pause_title.text = GameSession.loc("hud_pause")
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 28)
	pause_title.add_theme_color_override("font_color", GameSession.COLOR_ALERT)
	pause_layout.add_child(pause_title)

	_pause_info = Label.new()
	_pause_info.text = ""
	_pause_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_info.add_theme_font_size_override("font_size", 15)
	_pause_info.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	pause_layout.add_child(_pause_info)

	_pause_resume_button = _pause_button(GameSession.loc("hud_resume"))
	_pause_resume_button.pressed.connect(_on_resume_pressed)
	pause_layout.add_child(_pause_resume_button)

	var restart_button := _pause_button(GameSession.loc("hud_restart"))
	restart_button.pressed.connect(_on_restart_pressed)
	pause_layout.add_child(restart_button)

	var menu_button := _pause_button(GameSession.loc("hud_menu"))
	menu_button.pressed.connect(_on_menu_pressed)
	pause_layout.add_child(menu_button)

	var pause_help := Label.new()
	pause_help.text = GameSession.loc("hud_pause_help")
	pause_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_help.add_theme_font_size_override("font_size", 13)
	pause_help.add_theme_color_override("font_color", GameSession.COLOR_DIM)
	pause_layout.add_child(pause_help)


func update_player(score: int, hull: int, max_hull: int, lives: int, weapon_level: int, phase_text: String, status_text: String = "") -> void:
	_stats_label.text = GameSession.loc("hud_stats", [
		score,
		hull,
		max_hull,
		GameSession.weapon_label(weapon_level),
	])
	if not status_text.is_empty():
		_stats_label.text += "   " + GameSession.loc("hud_mod", [status_text])
	_phase_label.text = phase_text


func update_stage(stage_index: int, total_stages: int, progress: float) -> void:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	_progress_fill.size.x = 260.0 * clamped_progress
	_stage_label.text = GameSession.loc("hud_phase", [
		stage_index,
		total_stages,
		int(round(clamped_progress * 100.0)),
	])


func update_boss(active: bool, current_hull: int, max_hull: int) -> void:
	_boss_label.visible = active
	if not active:
		return
	var filled := int(round((float(current_hull) / float(max_hull)) * 14.0))
	var meter := ""
	for index in range(14):
		meter += "|" if index < filled else "."
	_boss_label.text = GameSession.loc("hud_boss", [meter])


func show_center_message(text: String, duration: float = 1.8, color: Color = GameSession.COLOR_ALERT) -> void:
	_center_label.text = text
	_center_label.visible = true
	_center_label.add_theme_color_override("font_color", color)
	_center_timer = duration


func show_notice(text: String, duration: float = 1.2, color: Color = GameSession.COLOR_FG) -> void:
	_notice_label.text = text
	_notice_label.visible = true
	_notice_label.add_theme_color_override("font_color", color)
	_notice_timer = duration


func flash(color: Color = GameSession.COLOR_HIT, alpha: float = 0.35) -> void:
	_danger_timer = 0.0
	if _danger_label != null:
		_danger_label.visible = false
	if _danger_sub_label != null:
		_danger_sub_label.visible = false
	_flash_rect.color = color
	_flash_rect.modulate.a = alpha
	_flash_rect.visible = true
	_flash_timer = 0.24


func show_danger_warning(duration: float = 1.2) -> void:
	_flash_timer = 0.0
	_flash_rect.color = Color(0.25, 0.02, 0.02, 0.86)
	_flash_rect.modulate.a = 0.42
	_flash_rect.visible = true
	_danger_label.text = GameSession.loc("dangerous")
	_danger_sub_label.text = GameSession.loc("dangerous_sub")
	_danger_label.visible = true
	_danger_sub_label.visible = true
	_danger_timer = duration


func show_pause(score: int, best_score: int) -> void:
	_pause_info.text = GameSession.loc("hud_pause_info", [score, best_score])
	_pause_panel.visible = true
	if _pause_resume_button != null:
		_pause_resume_button.grab_focus()


func hide_pause() -> void:
	_pause_panel.visible = false


func _pause_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(220.0, 42.0)
	button.add_theme_stylebox_override("normal", _button_box(GameSession.COLOR_GRID))
	button.add_theme_stylebox_override("hover", _button_box(GameSession.COLOR_DIM))
	button.add_theme_stylebox_override("focus", _button_box(GameSession.COLOR_DIM))
	button.add_theme_stylebox_override("pressed", _button_box(GameSession.COLOR_ALERT))
	button.add_theme_color_override("font_color", GameSession.COLOR_FG)
	button.add_theme_color_override("font_pressed_color", GameSession.COLOR_BG)
	return button


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


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_menu_pressed() -> void:
	menu_requested.emit()
