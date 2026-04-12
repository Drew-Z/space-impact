extends Node

const VIEW_SIZE := Vector2(960.0, 540.0)
const PLAYER_BOUNDS := Rect2(22.0, 70.0, VIEW_SIZE.x - 44.0, VIEW_SIZE.y - 118.0)
const TOTAL_PHASES := 6
const COLOR_BG := Color(0.03, 0.06, 0.03, 1.0)
const COLOR_GRID := Color(0.09, 0.18, 0.09, 1.0)
const COLOR_DIM := Color(0.23, 0.42, 0.23, 1.0)
const COLOR_FG := Color(0.62, 0.92, 0.56, 1.0)
const COLOR_ALERT := Color(0.95, 0.96, 0.58, 1.0)
const COLOR_HIT := Color(1.0, 1.0, 1.0, 1.0)
const PROFILE_PATH := "user://profile.cfg"

var high_score := 0
var total_runs := 0
var language := "zh"
var max_unlocked_phase := 1
var pending_start_phase := 1
var pending_start_weapon := 1

var last_result := {
	"victory": false,
	"score": 0,
	"time": 0.0,
	"weapon_level": 1,
	"lives_left": 0,
	"stages_cleared": 0,
	"stage_reached": 1,
	"total_stages": TOTAL_PHASES,
	"best_score": 0,
	"new_record": false,
}

const TEXTS := {
	"zh": {
		"menu_subtitle": "致敬 Nokia 3310 Space Impact 初代体验",
		"menu_summary": "五个战斗阶段与最终 Boss\n累积火力，撑过消耗，击碎核心。",
		"menu_best": "最高分 %06d   局数 %d",
		"menu_last_run": "上局：%s   分数 %06d   通关 %d/%d",
		"menu_clear": "通关",
		"menu_fail": "失败",
		"menu_start": "开始游戏",
		"menu_continue": "阶段继续",
		"menu_continue_hint": "从当前最高已解锁阶段开始",
		"menu_settings": "设置",
		"menu_quit": "退出",
		"menu_back": "返回",
		"menu_no_continue": "尚无可继续进度",
		"menu_controls": "移动：WASD / 方向键\n开火 / 确认：Space 或 Z\n暂停 / 返回：Esc 或 P",
		"settings_title": "设置",
		"settings_language": "语言",
		"settings_hint": "按 Esc 返回菜单",
		"lang_zh": "中文",
		"lang_en": "English",
		"hud_stats": "分数 %06d   船体 %d/%d   武器 %s",
		"hud_mod": "状态 %s",
		"hud_phase": "阶段 %d / %d   进度 %d%%",
		"hud_boss": "BOSS %s",
		"hud_pause": "暂停中",
		"hud_pause_info": "当前 %06d   最高 %06d",
		"hud_resume": "继续",
		"hud_restart": "重新开始",
		"hud_menu": "返回主菜单",
		"hud_pause_help": "Esc / P 继续",
		"hud_footer": "移动 WASD / 方向键   开火 Space / Z   暂停 Esc / P",
		"result_clear": "任务完成",
		"result_failed": "任务失败",
		"result_score": "分数 %06d",
		"result_detail": "时长 %.1fs   武器 %s   剩余船体 %d",
		"result_note": "到达阶段 %d   完成 %d/%d",
		"result_best": "最高分 %06d%s",
		"result_new_record": "   新纪录",
		"result_again": "再次出击",
		"result_menu": "返回主菜单",
		"phase_warning": "%s 警报",
		"boss_warning_notice": "Boss 信号已锁定，保持阵型。",
		"dangerous": "DANGEROUS",
		"dangerous_sub": "危险目标接近",
		"boss_frenzy": "BOSS 狂暴",
		"boss_shift": "Boss 阵型切换",
		"boss_shift_striker": "突击阵列展开",
		"boss_shift_carrier": "无人机舱门开启",
		"boss_shift_fortress": "堡垒弹幕展开",
		"boss_shift_reaper": "镰翼俯冲切换",
		"boss_shift_bastion": "核心壁垒升压",
		"boss_spawn_striker": "高速突击舰逼近，准备迎击。",
		"boss_spawn_carrier": "敌方母舰开启弹仓，注意增援编队。",
		"boss_spawn_fortress": "重装堡垒锁定航道，准备穿墙火力。",
		"boss_spawn_reaper": "镰翼舰进入切割航线，保持机动。",
		"boss_spawn_bastion": "要塞核心展开防壁，注意正面压制。",
		"boss_spawn_overlord": "最终核心启动，全部火力准备。",
		"final_boss_shift": "核心相位偏移",
		"final_boss_meltdown": "核心熔毁临界",
		"final_core_destroyed": "最终核心已击破",
		"final_escape": "敌方主核崩解，战区脱离中",
		"phase_clear": "%s 已清除",
		"feedback_hull": "船体受损",
		"feedback_weapon_down": "武器降级",
		"feedback_weapon_up": "武器升级",
		"feedback_repair": "船体修复",
		"feedback_shield": "护盾启动",
		"feedback_shield_break": "护盾破裂",
		"feedback_overdrive": "过载启动",
		"feedback_paused": "游戏暂停",
		"feedback_resume": "继续战斗",
		"status_shield": "护盾",
		"status_boost": "过载",
		"run_intro": "穿过五个阶段，积累火力并击碎最终核心。",
		"stage_opening": "%s 前段",
		"stage_pressure": "%s 中段",
		"stage_final_wave": "%s 最终波次",
		"stage_boss": "%s Boss",
	},
	"en": {
		"menu_subtitle": "A remake inspired by Nokia 3310 Space Impact",
		"menu_summary": "Five combat phases and a final boss\nBuild firepower, survive attrition, and shatter the core.",
		"menu_best": "BEST SCORE %06d   RUNS %d",
		"menu_last_run": "Last Run: %s   Score %06d   Cleared %d/%d",
		"menu_clear": "Clear",
		"menu_fail": "Fail",
		"menu_start": "Start Game",
		"menu_continue": "Phase Resume",
		"menu_continue_hint": "Start from the highest unlocked phase",
		"menu_settings": "Settings",
		"menu_quit": "Quit",
		"menu_back": "Back",
		"menu_no_continue": "No continue data available",
		"menu_controls": "Move: WASD / Arrow Keys\nFire / Confirm: Space or Z\nPause / Back: Esc or P",
		"settings_title": "Settings",
		"settings_language": "Language",
		"settings_hint": "Press Esc to return",
		"lang_zh": "Chinese",
		"lang_en": "English",
		"hud_stats": "SCORE %06d   HULL %d/%d   WPN %s",
		"hud_mod": "MOD %s",
		"hud_phase": "PHASE %d / %d   PROGRESS %d%%",
		"hud_boss": "BOSS %s",
		"hud_pause": "PAUSED",
		"hud_pause_info": "Current %06d   Best %06d",
		"hud_resume": "Resume",
		"hud_restart": "Restart Run",
		"hud_menu": "Return To Menu",
		"hud_pause_help": "Esc / P to resume",
		"hud_footer": "Move WASD / Arrows   Fire Space / Z   Pause Esc / P",
		"result_clear": "MISSION CLEAR",
		"result_failed": "MISSION FAILED",
		"result_score": "Score %06d",
		"result_detail": "Time %.1fs   Weapon %s   Hull Left %d",
		"result_note": "Reached Phase %d   Cleared %d/%d",
		"result_best": "Best Score %06d%s",
		"result_new_record": "   NEW RECORD",
		"result_again": "Run Again",
		"result_menu": "Return To Menu",
		"phase_warning": "%s WARNING",
		"boss_warning_notice": "Boss signature detected. Hold formation.",
		"dangerous": "DANGEROUS",
		"dangerous_sub": "Hostile target approaching",
		"boss_frenzy": "BOSS FRENZY",
		"boss_shift": "BOSS PATTERN SHIFT",
		"boss_shift_striker": "SPEAR ARRAY ENGAGED",
		"boss_shift_carrier": "HANGAR DOORS OPEN",
		"boss_shift_fortress": "FORTRESS BARRAGE ONLINE",
		"boss_shift_reaper": "SCYTHE DIVE PATTERN",
		"boss_shift_bastion": "CORE SHIELD SURGE",
		"boss_spawn_striker": "Fast assault craft inbound. Brace for impact.",
		"boss_spawn_carrier": "Enemy carrier opening hangars. Watch the support lanes.",
		"boss_spawn_fortress": "Heavy fortress locking the corridor. Prepare for wall fire.",
		"boss_spawn_reaper": "Reaper wing entering the lane. Stay mobile.",
		"boss_spawn_bastion": "Bastion core deployed. Expect frontal suppression.",
		"boss_spawn_overlord": "Final core active. Commit all firepower.",
		"final_boss_shift": "CORE PHASE SHIFT",
		"final_boss_meltdown": "CORE MELTDOWN",
		"final_core_destroyed": "FINAL CORE DESTROYED",
		"final_escape": "Core collapse confirmed. Exiting combat zone.",
		"phase_clear": "%s CLEAR",
		"feedback_hull": "HULL DAMAGED",
		"feedback_weapon_down": "WEAPON DOWN",
		"feedback_weapon_up": "WEAPON UPGRADE",
		"feedback_repair": "HULL REPAIRED",
		"feedback_shield": "SHIELD ONLINE",
		"feedback_shield_break": "SHIELD BROKEN",
		"feedback_overdrive": "OVERDRIVE ENGAGED",
		"feedback_paused": "RUN PAUSED",
		"feedback_resume": "BACK IN ACTION",
		"status_shield": "SHIELD",
		"status_boost": "BOOST",
		"run_intro": "Push through five phases, build your firepower, and break the final core.",
		"stage_opening": "%s OPENING",
		"stage_pressure": "%s PRESSURE",
		"stage_final_wave": "%s FINAL WAVE",
		"stage_boss": "%s BOSS",
	},
}


func _ready() -> void:
	_configure_input_map()
	_load_profile()


func _configure_input_map() -> void:
	_bind_action("move_up", [KEY_W, KEY_UP])
	_bind_action("move_down", [KEY_S, KEY_DOWN])
	_bind_action("move_left", [KEY_A, KEY_LEFT])
	_bind_action("move_right", [KEY_D, KEY_RIGHT])
	_bind_action("fire", [KEY_SPACE, KEY_Z])
	_bind_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_bind_action("back", [KEY_ESCAPE, KEY_X])
	_bind_action("pause", [KEY_P, KEY_ESCAPE])


func _bind_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, event)
	for keycode in keys:
		var input_event := InputEventKey.new()
		input_event.keycode = keycode
		input_event.physical_keycode = keycode
		InputMap.action_add_event(action_name, input_event)


func save_result(victory: bool, score: int, elapsed: float, weapon_level: int, lives_left: int, stages_cleared: int, stage_reached: int, total_stages: int) -> void:
	total_runs += 1
	var new_record := score > high_score
	if new_record:
		high_score = score
	max_unlocked_phase = max(max_unlocked_phase, clamp(stage_reached, 1, total_stages))
	_save_profile()
	last_result = {
		"victory": victory,
		"score": score,
		"time": elapsed,
		"weapon_level": weapon_level,
		"lives_left": lives_left,
		"stages_cleared": stages_cleared,
		"stage_reached": stage_reached,
		"total_stages": total_stages,
		"best_score": high_score,
		"new_record": new_record,
	}


func loc(key: String, args: Array = []) -> String:
	var language_table: Dictionary = TEXTS.get(language, TEXTS["en"])
	var template := String(language_table.get(key, key))
	if args.is_empty():
		return template
	return template % args


func set_language(new_language: String) -> void:
	if not TEXTS.has(new_language):
		return
	language = new_language
	_save_profile()


func begin_new_run() -> void:
	pending_start_phase = 1
	pending_start_weapon = 1


func begin_continue_run() -> void:
	pending_start_phase = clamp(max_unlocked_phase, 1, int(last_result.get("total_stages", TOTAL_PHASES)))
	pending_start_weapon = max(int(last_result.get("weapon_level", 1)), min(1 + (pending_start_phase - 1) * 2, 9))


func consume_pending_start_phase() -> int:
	return max(pending_start_phase, 1)


func consume_pending_start_weapon() -> int:
	return max(pending_start_weapon, 1)


func weapon_label(level: int) -> String:
	match clamp(level, 1, 13):
		1:
			return "PULSE"
		2:
			return "DOUBLE"
		3:
			return "TRIPLE"
		4:
			return "EDGE"
		5:
			return "PULSE+"
		6:
			return "DOUBLE+"
		7:
			return "TRIPLE+"
		8:
			return "EDGE+"
		9:
			return "LINE"
		10:
			return "LINE+"
		11:
			return "LINE++"
		12:
			return "LINE MAX"
		13:
			return "OMEGA"
	return "PULSE"


func _load_profile() -> void:
	var config := ConfigFile.new()
	var error := config.load(PROFILE_PATH)
	if error != OK:
		return
	high_score = int(config.get_value("profile", "high_score", 0))
	total_runs = int(config.get_value("profile", "total_runs", 0))
	language = String(config.get_value("profile", "language", "zh"))
	max_unlocked_phase = int(config.get_value("profile", "max_unlocked_phase", 1))


func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "high_score", high_score)
	config.set_value("profile", "total_runs", total_runs)
	config.set_value("profile", "language", language)
	config.set_value("profile", "max_unlocked_phase", max_unlocked_phase)
	config.save(PROFILE_PATH)
