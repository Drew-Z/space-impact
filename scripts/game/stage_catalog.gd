extends RefCounted


static func enemy_config(enemy_type: String, base_y: float, overrides: Dictionary = {}) -> Dictionary:
	var config: Dictionary
	match enemy_type:
		"wave":
			config = {
				"enemy_type": "wave",
				"speed": 218.0,
				"health": 2,
				"amplitude": 34.0,
				"frequency": 3.8,
				"base_y": base_y,
				"score_value": 140,
				"tint": GameSession.COLOR_FG,
			}
		"tank":
			config = {
				"enemy_type": "tank",
				"speed": 154.0,
				"health": 5,
				"amplitude": 24.0,
				"frequency": 2.2,
				"base_y": base_y,
				"score_value": 260,
				"shoot_interval": 1.7,
				"shot_mode": "single",
				"tint": GameSession.COLOR_ALERT,
			}
		"spinner":
			config = {
				"enemy_type": "spinner",
				"speed": 208.0,
				"health": 3,
				"amplitude": 46.0,
				"frequency": 4.8,
				"base_y": base_y,
				"score_value": 220,
				"shoot_interval": 1.32,
				"shot_mode": "spread",
				"tint": GameSession.COLOR_ALERT,
			}
		"sentinel":
			config = {
				"enemy_type": "sentinel",
				"speed": 174.0,
				"health": 4,
				"amplitude": 18.0,
				"frequency": 2.6,
				"base_y": base_y,
				"score_value": 240,
				"shoot_interval": 1.45,
				"shot_mode": "aimed",
				"tint": GameSession.COLOR_FG,
			}
		"dart":
			var drift := -1.0 if base_y > GameSession.VIEW_SIZE.y * 0.5 else 1.0
			config = {
				"enemy_type": "dart",
				"speed": 270.0,
				"health": 2,
				"base_y": base_y,
				"score_value": 170,
				"shoot_interval": 0.0,
				"shot_mode": "dart",
				"vertical_speed": 118.0,
				"drift_direction": drift,
				"tint": GameSession.COLOR_HIT,
			}
		"skirmisher":
			config = {
				"enemy_type": "skirmisher",
				"speed": 234.0,
				"health": 3,
				"amplitude": 36.0,
				"frequency": 5.4,
				"base_y": base_y,
				"score_value": 210,
				"shoot_interval": 1.08,
				"shot_mode": "fan",
				"tint": GameSession.COLOR_HIT,
			}
		"lancer":
			config = {
				"enemy_type": "lancer",
				"speed": 196.0,
				"health": 4,
				"amplitude": 12.0,
				"frequency": 1.8,
				"base_y": base_y,
				"score_value": 260,
				"shoot_interval": 1.3,
				"shot_mode": "cross",
				"tint": GameSession.COLOR_ALERT,
			}
		_:
			config = {
				"enemy_type": "straight",
				"speed": 252.0,
				"health": 2,
				"base_y": base_y,
				"score_value": 110,
				"tint": GameSession.COLOR_DIM,
			}
	for key in overrides.keys():
		config[key] = overrides[key]
	return config


static func boss_support_overrides(enemy_type: String) -> Dictionary:
	match enemy_type:
		"tank":
			return {"health": 1, "shoot_interval": 1.28, "speed": 184.0}
		"spinner":
			return {"health": 1, "shoot_interval": 1.08, "speed": 230.0}
		"sentinel":
			return {"health": 1, "shoot_interval": 1.16, "speed": 198.0}
		"dart":
			return {"health": 1, "shoot_interval": 0.0, "speed": 284.0}
		"wave":
			return {"health": 1, "speed": 240.0}
		"skirmisher":
			return {"health": 1, "shoot_interval": 0.92, "speed": 246.0}
		"lancer":
			return {"health": 1, "shoot_interval": 1.08, "speed": 214.0}
	return {"health": 1, "speed": 260.0}


static func boss_spawn_notice_key(profile_name: String) -> String:
	match profile_name:
		"striker":
			return "boss_spawn_striker"
		"carrier":
			return "boss_spawn_carrier"
		"fortress":
			return "boss_spawn_fortress"
		"reaper":
			return "boss_spawn_reaper"
		"bastion":
			return "boss_spawn_bastion"
		"overlord":
			return "boss_spawn_overlord"
	return "boss_warning_notice"


static func boss_shift_notice_key(profile_name: String) -> String:
	match profile_name:
		"striker":
			return "boss_shift_striker"
		"carrier":
			return "boss_shift_carrier"
		"fortress":
			return "boss_shift_fortress"
		"reaper":
			return "boss_shift_reaper"
		"bastion":
			return "boss_shift_bastion"
	return "boss_shift"
