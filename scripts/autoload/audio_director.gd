extends Node

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.25
const SFX_VOICES := 4

var _music_player: AudioStreamPlayer
var _music_playback: AudioStreamGeneratorPlayback
var _music_sequence: Array = []
var _music_note_index := 0
var _music_note_time_left := 0.0
var _music_phase := 0.0
var _music_mode := "menu"

var _sfx_players: Array = []
var _sfx_playbacks: Array = []
var _sfx_states: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 3310
	_setup_music_player()
	_setup_sfx_players()
	set_music_mode("menu")


func _process(_delta: float) -> void:
	_fill_music_buffer()
	_fill_sfx_buffers()


func _exit_tree() -> void:
	if _music_player != null:
		_music_player.stop()
	for player in _sfx_players:
		if player != null:
			player.stop()


func set_music_mode(mode: String) -> void:
	if mode == _music_mode and not _music_sequence.is_empty():
		return
	_music_mode = mode
	_music_sequence = _music_sequence_for(mode)
	_music_note_index = 0
	_music_note_time_left = 0.0
	_music_phase = 0.0


func play_sfx(name: String) -> void:
	var profile: Dictionary = _sfx_profile(name)
	if profile.is_empty():
		return
	for index in range(_sfx_states.size()):
		if not bool(_sfx_states[index]["active"]):
			_sfx_states[index] = profile
			_sfx_states[index]["active"] = true
			_sfx_states[index]["phase"] = 0.0
			_sfx_states[index]["elapsed"] = 0.0
			return
	_sfx_states[0] = profile
	_sfx_states[0]["active"] = true
	_sfx_states[0]["phase"] = 0.0
	_sfx_states[0]["elapsed"] = 0.0


func _setup_music_player() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = BUFFER_LENGTH
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = stream
	_music_player.bus = "Master"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	_music_player.play()
	_music_playback = _music_player.get_stream_playback()


func _setup_sfx_players() -> void:
	for voice_index in range(SFX_VOICES):
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = MIX_RATE
		stream.buffer_length = BUFFER_LENGTH
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = "Master"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		player.play()
		_sfx_players.append(player)
		_sfx_playbacks.append(player.get_stream_playback())
		_sfx_states.append({
			"active": false,
			"phase": 0.0,
			"elapsed": 0.0,
			"duration": 0.1,
			"freq": 440.0,
			"target_freq": 440.0,
			"amp": 0.1,
			"wave": "square",
		})


func _fill_music_buffer() -> void:
	if _music_playback == null:
		return
	var available := _music_playback.get_frames_available()
	while available > 0:
		if _music_note_time_left <= 0.0:
			if _music_sequence.is_empty():
				_music_sequence = _music_sequence_for("menu")
			var note: Dictionary = _music_sequence[_music_note_index]
			_music_note_index = (_music_note_index + 1) % _music_sequence.size()
			_music_note_time_left = float(note["dur"])
		var current_note: Dictionary = _music_sequence[(_music_note_index - 1 + _music_sequence.size()) % _music_sequence.size()]
		var sample := _music_sample_for(current_note)
		_music_playback.push_frame(Vector2(sample, sample))
		_music_note_time_left -= 1.0 / MIX_RATE
		available -= 1


func _fill_sfx_buffers() -> void:
	for index in range(_sfx_playbacks.size()):
		var playback: AudioStreamGeneratorPlayback = _sfx_playbacks[index]
		var state: Dictionary = _sfx_states[index]
		var available := playback.get_frames_available()
		while available > 0:
			var sample := 0.0
			if bool(state["active"]):
				sample = _next_sfx_sample(state)
			playback.push_frame(Vector2(sample, sample))
			available -= 1
		_sfx_states[index] = state


func _music_sample_for(note: Dictionary) -> float:
	var freq := float(note["freq"])
	var amp := float(note["amp"])
	if freq <= 0.0 or amp <= 0.0:
		return 0.0
	_music_phase = wrapf(_music_phase + (freq / MIX_RATE), 0.0, 1.0)
	var square := 1.0 if _music_phase < 0.5 else -1.0
	var body := sin(_music_phase * TAU) * 0.4
	return (square * 0.6 + body) * amp


func _next_sfx_sample(state: Dictionary) -> float:
	var elapsed: float = float(state["elapsed"])
	var duration: float = float(state["duration"])
	var progress: float = min(elapsed / duration, 1.0)
	var start_freq: float = float(state["freq"])
	var end_freq: float = float(state["target_freq"])
	var freq: float = lerp(start_freq, end_freq, progress)
	var phase: float = float(state["phase"])
	phase = wrapf(phase + (freq / MIX_RATE), 0.0, 1.0)
	state["phase"] = phase
	state["elapsed"] = elapsed + (1.0 / MIX_RATE)
	if float(state["elapsed"]) >= duration:
		state["active"] = false
	var env: float = (1.0 - progress) * float(state["amp"])
	match String(state["wave"]):
		"triangle":
			return (abs(phase * 4.0 - 2.0) - 1.0) * env
		"noise":
			return _rng.randf_range(-1.0, 1.0) * env
		"hybrid":
			var square := 1.0 if phase < 0.5 else -1.0
			return ((square * 0.5) + (_rng.randf_range(-1.0, 1.0) * 0.5)) * env
		_:
			var pulse := 1.0 if phase < 0.35 else -1.0
			return pulse * env


func _music_sequence_for(mode: String) -> Array:
	match mode:
		"combat":
			return [
				{"freq": 220.0, "dur": 0.16, "amp": 0.06},
				{"freq": 330.0, "dur": 0.12, "amp": 0.06},
				{"freq": 262.0, "dur": 0.16, "amp": 0.06},
				{"freq": 392.0, "dur": 0.18, "amp": 0.07},
				{"freq": 294.0, "dur": 0.12, "amp": 0.06},
				{"freq": 0.0, "dur": 0.08, "amp": 0.0},
			]
		"pause":
			return [
				{"freq": 196.0, "dur": 0.22, "amp": 0.04},
				{"freq": 147.0, "dur": 0.22, "amp": 0.04},
				{"freq": 0.0, "dur": 0.14, "amp": 0.0},
			]
		"victory":
			return [
				{"freq": 262.0, "dur": 0.12, "amp": 0.06},
				{"freq": 330.0, "dur": 0.12, "amp": 0.06},
				{"freq": 392.0, "dur": 0.12, "amp": 0.07},
				{"freq": 523.0, "dur": 0.22, "amp": 0.07},
				{"freq": 392.0, "dur": 0.18, "amp": 0.05},
				{"freq": 0.0, "dur": 0.12, "amp": 0.0},
			]
		"defeat":
			return [
				{"freq": 220.0, "dur": 0.18, "amp": 0.05},
				{"freq": 196.0, "dur": 0.18, "amp": 0.05},
				{"freq": 174.0, "dur": 0.18, "amp": 0.05},
				{"freq": 147.0, "dur": 0.26, "amp": 0.05},
				{"freq": 0.0, "dur": 0.1, "amp": 0.0},
			]
		_:
			return [
				{"freq": 262.0, "dur": 0.16, "amp": 0.05},
				{"freq": 330.0, "dur": 0.16, "amp": 0.05},
				{"freq": 392.0, "dur": 0.2, "amp": 0.05},
				{"freq": 330.0, "dur": 0.14, "amp": 0.04},
				{"freq": 0.0, "dur": 0.14, "amp": 0.0},
			]


func _sfx_profile(name: String) -> Dictionary:
	match name:
		"shoot":
			return {"duration": 0.06, "freq": 980.0, "target_freq": 780.0, "amp": 0.12, "wave": "square"}
		"hit":
			return {"duration": 0.12, "freq": 240.0, "target_freq": 120.0, "amp": 0.14, "wave": "hybrid"}
		"pickup":
			return {"duration": 0.16, "freq": 420.0, "target_freq": 720.0, "amp": 0.11, "wave": "triangle"}
		"repair":
			return {"duration": 0.18, "freq": 300.0, "target_freq": 540.0, "amp": 0.1, "wave": "triangle"}
		"overdrive":
			return {"duration": 0.24, "freq": 340.0, "target_freq": 920.0, "amp": 0.13, "wave": "square"}
		"enemy_pop":
			return {"duration": 0.1, "freq": 300.0, "target_freq": 80.0, "amp": 0.12, "wave": "hybrid"}
		"boss_alarm":
			return {"duration": 0.22, "freq": 180.0, "target_freq": 280.0, "amp": 0.14, "wave": "square"}
		"boss_down":
			return {"duration": 0.35, "freq": 260.0, "target_freq": 60.0, "amp": 0.18, "wave": "hybrid"}
		"pause":
			return {"duration": 0.1, "freq": 300.0, "target_freq": 220.0, "amp": 0.08, "wave": "triangle"}
		"resume":
			return {"duration": 0.1, "freq": 220.0, "target_freq": 340.0, "amp": 0.08, "wave": "triangle"}
		"confirm":
			return {"duration": 0.12, "freq": 360.0, "target_freq": 520.0, "amp": 0.1, "wave": "triangle"}
		"clear":
			return {"duration": 0.22, "freq": 400.0, "target_freq": 700.0, "amp": 0.12, "wave": "triangle"}
		"defeat":
			return {"duration": 0.26, "freq": 180.0, "target_freq": 90.0, "amp": 0.12, "wave": "hybrid"}
	return {}
