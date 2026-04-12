extends RefCounted


static func sector_1() -> Array:
	var schedule: Array = []
	schedule.append(_burst_event(1.0, "straight", [112.0, 188.0, 264.0, 340.0], {"x_spacing": 58.0}))
	schedule.append_array(_staggered_bursts(4.4, "straight", [108.0, 392.0, 148.0, 352.0, 188.0, 312.0], 0.42, {
		"overrides": {"speed": 246.0},
	}))
	schedule.append(_burst_event(8.1, "wave", [138.0, 218.0, 298.0, 378.0], {"x_spacing": 66.0}))
	schedule.append_array(_staggered_bursts(11.8, "dart", [122.0, 404.0, 168.0, 358.0], 0.38, {
		"overrides": {"shoot_interval": 1.9},
	}))
	schedule.append(_burst_event(15.7, "tank", [166.0, 336.0], {
		"x_spacing": 102.0,
		"overrides": {"health": 4},
	}))
	schedule.append(_burst_event(17.0, "straight", [124.0, 210.0, 296.0, 382.0], {
		"x_spacing": 66.0,
		"overrides": {"speed": 258.0},
	}))
	schedule.append(_powerup_event(20.2, "weapon", 254.0))
	schedule.append(_powerup_event(30.2, "overdrive", 196.0))
	schedule.append_array(_staggered_bursts(23.2, "wave", [118.0, 194.0, 270.0, 346.0, 422.0], 0.34, {
		"overrides": {"speed": 224.0},
	}))
	schedule.append(_powerup_event(34.8, "weapon", 312.0))
	schedule.append(_burst_event(27.6, "dart", [124.0, 240.0, 356.0], {
		"x_spacing": 80.0,
		"overrides": {"shoot_interval": 1.72},
	}))
	schedule.append(_burst_event(31.2, "straight", [148.0, 230.0, 312.0, 394.0], {
		"x_spacing": 60.0,
		"overrides": {"speed": 266.0},
	}))
	schedule.append(_burst_event(34.6, "tank", [138.0, 270.0, 402.0], {
		"x_spacing": 84.0,
		"overrides": {"health": 4, "shoot_interval": 1.58},
	}))
	schedule.append(_boss_event(38.8))
	return schedule


static func sector_2() -> Array:
	var schedule: Array = []
	schedule.append_array(_staggered_bursts(1.2, "straight", [106.0, 434.0, 154.0, 386.0, 202.0, 338.0, 250.0, 290.0], 0.28, {
		"overrides": {"speed": 264.0},
	}))
	schedule.append(_burst_event(5.2, "wave", [126.0, 186.0, 246.0, 306.0, 366.0, 426.0], {
		"x_spacing": 48.0,
		"overrides": {"speed": 238.0},
	}))
	schedule.append(_powerup_event(8.6, "overdrive", 300.0))
	schedule.append_array(_staggered_bursts(10.2, "dart", [124.0, 248.0, 372.0, 186.0, 310.0], 0.24, {
		"overrides": {"shoot_interval": 1.48},
	}))
	schedule.append(_burst_event(14.0, "tank", [142.0, 270.0, 398.0], {
		"x_spacing": 82.0,
		"overrides": {"health": 5, "shoot_interval": 1.4},
	}))
	schedule.append(_burst_event(18.2, "wave", [152.0, 248.0, 344.0], {
		"x_spacing": 88.0,
		"overrides": {"health": 3, "speed": 232.0},
	}))
	schedule.append(_powerup_event(23.6, "weapon", 240.0))
	schedule.append_array(_staggered_bursts(21.6, "straight", [118.0, 422.0, 162.0, 378.0, 206.0, 334.0], 0.26, {
		"overrides": {"speed": 276.0},
	}))
	schedule.append(_burst_event(25.2, "dart", [114.0, 174.0, 366.0, 426.0], {
		"x_spacing": 62.0,
		"overrides": {"shoot_interval": 1.24},
	}))
	schedule.append(_powerup_event(31.2, "overdrive", 214.0))
	schedule.append(_burst_event(30.0, "tank", [120.0, 220.0, 320.0, 420.0], {
		"x_spacing": 66.0,
		"overrides": {"health": 5, "shoot_interval": 1.22},
	}))
	schedule.append(_powerup_event(37.8, "weapon", 374.0))
	schedule.append(_burst_event(35.0, "wave", [138.0, 210.0, 282.0, 354.0, 426.0], {
		"x_spacing": 52.0,
		"overrides": {"health": 3, "speed": 236.0},
	}))
	schedule.append_array(_staggered_bursts(39.0, "dart", [116.0, 424.0, 164.0, 376.0, 212.0, 328.0], 0.22, {
		"overrides": {"shoot_interval": 1.14},
	}))
	schedule.append(_boss_event(44.8))
	return schedule


static func sector_3() -> Array:
	var schedule: Array = []
	schedule.append_array(_staggered_bursts(1.0, "spinner", [120.0, 420.0, 168.0, 372.0], 0.32, {
		"overrides": {"shoot_interval": 1.4},
	}))
	schedule.append(_powerup_event(9.0, "weapon", 268.0))
	schedule.append(_burst_event(6.2, "sentinel", [146.0, 268.0, 390.0], {
		"x_spacing": 86.0,
		"overrides": {"shoot_interval": 1.52},
	}))
	schedule.append_array(_staggered_bursts(10.4, "dart", [118.0, 202.0, 338.0, 422.0], 0.24, {
		"overrides": {"shoot_interval": 1.18},
	}))
	schedule.append(_powerup_event(20.4, "overdrive", 194.0))
	schedule.append(_burst_event(15.4, "tank", [140.0, 270.0, 400.0], {
		"x_spacing": 78.0,
		"overrides": {"health": 6, "shoot_interval": 1.3},
	}))
	schedule.append(_burst_event(19.2, "spinner", [150.0, 250.0, 350.0], {
		"x_spacing": 74.0,
		"overrides": {"shoot_interval": 1.12},
	}))
	schedule.append(_burst_event(24.2, "wave", [132.0, 192.0, 252.0, 312.0, 372.0, 432.0], {
		"x_spacing": 46.0,
		"overrides": {"health": 3, "speed": 242.0},
	}))
	schedule.append(_burst_event(29.0, "sentinel", [118.0, 220.0, 322.0, 424.0], {
		"x_spacing": 70.0,
		"overrides": {"health": 4, "shoot_interval": 1.18},
	}))
	schedule.append(_powerup_event(33.8, "overdrive", 360.0))
	schedule.append_array(_staggered_bursts(34.2, "spinner", [110.0, 430.0, 160.0, 380.0, 210.0, 330.0], 0.22, {
		"overrides": {"shoot_interval": 0.98},
	}))
	schedule.append(_boss_event(43.2))
	return schedule


static func sector_4() -> Array:
	var schedule: Array = []
	schedule.append(_burst_event(1.0, "sentinel", [124.0, 214.0, 304.0, 394.0], {
		"x_spacing": 68.0,
		"overrides": {"health": 4, "shoot_interval": 1.14},
	}))
	schedule.append_array(_staggered_bursts(4.0, "dart", [116.0, 426.0, 160.0, 382.0, 204.0, 338.0], 0.18, {
		"overrides": {"shoot_interval": 1.02},
	}))
	schedule.append(_powerup_event(11.0, "weapon", 210.0))
	schedule.append(_burst_event(9.6, "spinner", [142.0, 232.0, 322.0, 412.0], {
		"x_spacing": 62.0,
		"overrides": {"shoot_interval": 0.96},
	}))
	schedule.append(_burst_event(13.8, "tank", [136.0, 232.0, 328.0, 424.0], {
		"x_spacing": 70.0,
		"overrides": {"health": 6, "shoot_interval": 1.14},
	}))
	schedule.append(_powerup_event(24.8, "weapon", 286.0))
	schedule.append(_burst_event(18.4, "wave", [126.0, 178.0, 230.0, 282.0, 334.0, 386.0, 438.0], {
		"x_spacing": 42.0,
		"overrides": {"health": 3, "speed": 248.0},
	}))
	schedule.append(_burst_event(24.2, "sentinel", [120.0, 188.0, 256.0, 324.0, 392.0], {
		"x_spacing": 54.0,
		"overrides": {"health": 4, "shoot_interval": 1.02},
	}))
	schedule.append_array(_staggered_bursts(28.2, "skirmisher", [112.0, 428.0, 164.0, 376.0, 216.0, 324.0], 0.18, {
		"overrides": {"shoot_interval": 0.88},
	}))
	schedule.append(_powerup_event(35.4, "overdrive", 178.0))
	schedule.append(_burst_event(33.0, "tank", [150.0, 270.0, 390.0], {
		"x_spacing": 82.0,
		"overrides": {"health": 7, "shoot_interval": 1.02},
	}))
	schedule.append(_burst_event(38.0, "lancer", [122.0, 202.0, 282.0, 362.0, 442.0], {
		"x_spacing": 58.0,
		"overrides": {"shoot_interval": 1.06, "health": 3},
	}))
	schedule.append(_powerup_event(42.2, "overdrive", 320.0))
	schedule.append(_boss_event(46.8))
	return schedule


static func sector_5() -> Array:
	var schedule: Array = []
	schedule.append_array(_staggered_bursts(1.0, "lancer", [116.0, 424.0, 164.0, 376.0, 212.0, 328.0], 0.2, {
		"overrides": {"health": 4, "shoot_interval": 1.0},
	}))
	schedule.append(_burst_event(5.4, "spinner", [130.0, 206.0, 282.0, 358.0, 434.0], {
		"x_spacing": 52.0,
		"overrides": {"shoot_interval": 0.94},
	}))
	schedule.append(_powerup_event(12.2, "weapon", 250.0))
	schedule.append(_burst_event(14.0, "tank", [132.0, 224.0, 316.0, 408.0], {
		"x_spacing": 66.0,
		"overrides": {"health": 7, "shoot_interval": 0.98},
	}))
	schedule.append_array(_staggered_bursts(19.4, "dart", [118.0, 422.0, 174.0, 366.0, 230.0, 310.0], 0.18, {
		"overrides": {"shoot_interval": 0.84},
	}))
	schedule.append(_powerup_event(24.8, "overdrive", 178.0))
	schedule.append(_burst_event(27.4, "skirmisher", [136.0, 228.0, 320.0, 412.0], {
		"x_spacing": 58.0,
		"overrides": {"health": 3, "shoot_interval": 0.9},
	}))
	schedule.append(_burst_event(32.6, "wave", [124.0, 176.0, 228.0, 280.0, 332.0, 384.0, 436.0], {
		"x_spacing": 40.0,
		"overrides": {"health": 3, "speed": 252.0},
	}))
	schedule.append(_powerup_event(37.0, "weapon", 302.0))
	schedule.append_array(_staggered_bursts(39.2, "lancer", [120.0, 420.0, 170.0, 370.0, 220.0, 320.0], 0.16, {
		"overrides": {"shoot_interval": 0.92},
	}))
	schedule.append(_burst_event(44.4, "tank", [152.0, 270.0, 388.0], {
		"x_spacing": 84.0,
		"overrides": {"health": 8, "shoot_interval": 0.92},
	}))
	schedule.append(_boss_event(52.0))
	return schedule


static func final_sector() -> Array:
	return [
		_powerup_event(1.4, "overdrive", 270.0),
		_boss_event(3.4),
	]


static func _burst_event(time: float, enemy_type: String, lanes: Array, extra: Dictionary = {}) -> Dictionary:
	var event: Dictionary = {
		"time": time,
		"kind": "burst",
		"enemy_type": enemy_type,
		"lanes": lanes.duplicate(),
	}
	for key in extra.keys():
		event[key] = extra[key]
	return event


static func _powerup_event(time: float, kind_name: String, y: float) -> Dictionary:
	return {
		"time": time,
		"kind": "powerup",
		"kind_name": kind_name,
		"position": Vector2(GameSession.VIEW_SIZE.x + 30.0, y),
	}


static func _boss_event(time: float) -> Dictionary:
	return {
		"time": time,
		"kind": "boss",
	}


static func _staggered_bursts(start_time: float, enemy_type: String, lanes: Array, step: float, extra: Dictionary = {}) -> Array:
	var events: Array = []
	for index in range(lanes.size()):
		var event_extra := extra.duplicate(true)
		if event_extra.has("lanes"):
			event_extra.erase("lanes")
		events.append(_burst_event(start_time + float(index) * step, enemy_type, [float(lanes[index])], event_extra))
	return events
