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
			"lfo_depth": 0.0,
			"lfo_rate": 0.0,
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
	var sine := sin(_music_phase * TAU)
	var triangle := _triangle_wave(_music_phase)
	var pulse := 1.0 if _music_phase < 0.42 else -1.0
	match _music_mode:
		"combat":
			return (sine * 0.58 + triangle * 0.27 + pulse * 0.15) * amp
		"pause":
			return (sine * 0.72 + triangle * 0.28) * amp
		"victory":
			return (sine * 0.5 + triangle * 0.38 + pulse * 0.12) * amp
		"defeat":
			return (triangle * 0.56 + sine * 0.44) * amp
		_:
			return (sine * 0.74 + triangle * 0.26) * amp


func _triangle_wave(phase: float) -> float:
	return abs(phase * 4.0 - 2.0) - 1.0


func _next_sfx_sample(state: Dictionary) -> float:
	var elapsed: float = float(state["elapsed"])
	var duration: float = float(state["duration"])
	var progress: float = min(elapsed / duration, 1.0)
	var start_freq: float = float(state["freq"])
	var end_freq: float = float(state["target_freq"])
	var freq: float = lerp(start_freq, end_freq, progress)
	var lfo_depth: float = float(state.get("lfo_depth", 0.0))
	var lfo_rate: float = float(state.get("lfo_rate", 0.0))
	if lfo_depth > 0.0 and lfo_rate > 0.0:
		freq += sin(elapsed * TAU * lfo_rate) * lfo_depth
	var phase: float = float(state["phase"])
	phase = wrapf(phase + (freq / MIX_RATE), 0.0, 1.0)
	state["phase"] = phase
	state["elapsed"] = elapsed + (1.0 / MIX_RATE)
	if float(state["elapsed"]) >= duration:
		state["active"] = false
	var env: float = (1.0 - progress) * float(state["amp"])
	match String(state["wave"]):
		"sine":
			return sin(phase * TAU) * env
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
				{"freq": 174.0, "dur": 0.18, "amp": 0.03},
				{"freq": 220.0, "dur": 0.14, "amp": 0.034},
				{"freq": 262.0, "dur": 0.14, "amp": 0.034},
				{"freq": 220.0, "dur": 0.14, "amp": 0.03},
				{"freq": 294.0, "dur": 0.18, "amp": 0.036},
				{"freq": 247.0, "dur": 0.14, "amp": 0.032},
				{"freq": 196.0, "dur": 0.16, "amp": 0.028},
				{"freq": 0.0, "dur": 0.08, "amp": 0.0},
			]
		"pause":
			return [
				{"freq": 174.0, "dur": 0.24, "amp": 0.028},
				{"freq": 147.0, "dur": 0.24, "amp": 0.028},
				{"freq": 130.0, "dur": 0.18, "amp": 0.022},
				{"freq": 0.0, "dur": 0.16, "amp": 0.0},
			]
		"victory":
			return [
				{"freq": 262.0, "dur": 0.14, "amp": 0.042},
				{"freq": 330.0, "dur": 0.14, "amp": 0.042},
				{"freq": 392.0, "dur": 0.14, "amp": 0.046},
				{"freq": 523.0, "dur": 0.24, "amp": 0.048},
				{"freq": 392.0, "dur": 0.18, "amp": 0.038},
				{"freq": 330.0, "dur": 0.14, "amp": 0.034},
				{"freq": 0.0, "dur": 0.12, "amp": 0.0},
			]
		"defeat":
			return [
				{"freq": 220.0, "dur": 0.18, "amp": 0.03},
				{"freq": 196.0, "dur": 0.18, "amp": 0.03},
				{"freq": 174.0, "dur": 0.18, "amp": 0.03},
				{"freq": 147.0, "dur": 0.28, "amp": 0.032},
				{"freq": 0.0, "dur": 0.12, "amp": 0.0},
			]
		_:
			return [
				{"freq": 196.0, "dur": 0.22, "amp": 0.024},
				{"freq": 247.0, "dur": 0.2, "amp": 0.026},
				{"freq": 294.0, "dur": 0.24, "amp": 0.028},
				{"freq": 247.0, "dur": 0.18, "amp": 0.024},
				{"freq": 220.0, "dur": 0.18, "amp": 0.022},
				{"freq": 0.0, "dur": 0.16, "amp": 0.0},
			]


func _sfx_profile(name: String) -> Dictionary:
	match name:
		"shoot":
			return {"duration": 0.045, "freq": 640.0, "target_freq": 480.0, "amp": 0.052, "wave": "triangle"}
		"hit":
			return {"duration": 0.1, "freq": 220.0, "target_freq": 140.0, "amp": 0.065, "wave": "hybrid"}
		"pickup":
			return {"duration": 0.16, "freq": 420.0, "target_freq": 720.0, "amp": 0.11, "wave": "triangle"}
		"repair":
			return {"duration": 0.18, "freq": 300.0, "target_freq": 540.0, "amp": 0.1, "wave": "triangle"}
		"overdrive":
			return {"duration": 0.2, "freq": 300.0, "target_freq": 620.0, "amp": 0.08, "wave": "triangle"}
		"enemy_pop":
			return {"duration": 0.09, "freq": 260.0, "target_freq": 150.0, "amp": 0.06, "wave": "hybrid"}
		"beam":
			return {"duration": 0.14, "freq": 118.0, "target_freq": 192.0, "amp": 0.05, "wave": "sine", "lfo_depth": 18.0, "lfo_rate": 6.0}
		"boss_fire":
			return {"duration": 0.11, "freq": 260.0, "target_freq": 200.0, "amp": 0.06, "wave": "triangle"}
		"boss_alarm":
			return {"duration": 0.24, "freq": 540.0, "target_freq": 540.0, "amp": 0.11, "wave": "sine", "lfo_depth": 170.0, "lfo_rate": 4.4}
		"boss_down":
			return {"duration": 0.28, "freq": 220.0, "target_freq": 80.0, "amp": 0.1, "wave": "triangle"}
		"pause":
			return {"duration": 0.1, "freq": 300.0, "target_freq": 220.0, "amp": 0.08, "wave": "triangle"}
		"resume":
			return {"duration": 0.1, "freq": 220.0, "target_freq": 340.0, "amp": 0.08, "wave": "triangle"}
		"confirm":
			return {"duration": 0.12, "freq": 360.0, "target_freq": 520.0, "amp": 0.1, "wave": "triangle"}
		"clear":
			return {"duration": 0.22, "freq": 400.0, "target_freq": 700.0, "amp": 0.12, "wave": "triangle"}
		"defeat":
			return {"duration": 0.22, "freq": 160.0, "target_freq": 118.0, "amp": 0.065, "wave": "triangle"}
	return {}
