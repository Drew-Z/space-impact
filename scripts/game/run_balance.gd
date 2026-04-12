extends RefCounted

const GUARANTEED_WEAPON_DROP_KILLS := 8
const RANDOM_DROP_CHANCE := 0.06
const RANDOM_DROP_COOLDOWN := 6.2
const GUARANTEED_DROP_COOLDOWN := 6.4
const BOSS_ALARM_BURSTS := 5
const BOSS_ALARM_INTERVAL := 0.34
const RUNTIME_POWERUP_SPEED := 118.0
const POWERUP_SPAWN_BOUNDS := Rect2(140.0, 96.0, GameSession.VIEW_SIZE.x - 260.0, GameSession.VIEW_SIZE.y - 180.0)


static func should_spawn_guaranteed_drop(kills_since_drop: int) -> bool:
	return kills_since_drop >= GUARANTEED_WEAPON_DROP_KILLS


static func should_roll_random_drop(random_drop_cooldown: float) -> bool:
	if random_drop_cooldown > 0.0:
		return false
	return randf() <= RANDOM_DROP_CHANCE


static func guaranteed_drop_kind(player_weapon: int) -> String:
	return "weapon" if player_weapon < 13 else "overdrive"


static func random_drop_kind(player_weapon: int) -> String:
	var roll := randf()
	if player_weapon < 13 and roll < 0.34:
		return "weapon"
	if roll < 0.46:
		return "repair"
	if roll < 0.58:
		return "shield"
	return "overdrive"


static func clamped_powerup_position(at_position: Vector2) -> Vector2:
	return Vector2(
		clamp(at_position.x, POWERUP_SPAWN_BOUNDS.position.x, POWERUP_SPAWN_BOUNDS.end.x),
		clamp(at_position.y, POWERUP_SPAWN_BOUNDS.position.y, POWERUP_SPAWN_BOUNDS.end.y)
	)
