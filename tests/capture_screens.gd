extends SceneTree

const OUTPUT_DIR := "res://docs/media"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		push_error("Failed to create media dir: %s" % mkdir_error)
		quit(1)
		return

	await _capture_menu()
	await _capture_gameplay()
	await _capture_result()
	quit()


func _capture_menu() -> void:
	await change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await process_frame
	await process_frame
	await _save_viewport("menu.png")


func _capture_gameplay() -> void:
	await change_scene_to_file("res://scenes/game/game_root.tscn")
	for _i in range(180):
		await process_frame
	await _save_viewport("gameplay.png")


func _capture_result() -> void:
	var game_session := root.get_node_or_null("GameSession")
	if game_session == null:
		push_error("GameSession autoload is not available during capture run.")
		return
	game_session.last_result = {
		"victory": true,
		"score": 12840,
		"time": 143.5,
		"weapon_level": 3,
		"lives_left": 1,
		"stages_cleared": 2,
		"stage_reached": 2,
		"best_score": max(int(game_session.high_score), 12840),
		"new_record": true,
	}
	await change_scene_to_file("res://scenes/ui/result_screen.tscn")
	await process_frame
	await process_frame
	await _save_viewport("result.png")


func _save_viewport(file_name: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
