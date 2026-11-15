extends Node

var audio_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var scream_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var caption_panel: PanelContainer
var caption_label: Label
var canvas_layer: CanvasLayer
var played_triggers: Dictionary = {}
var reached_checkpoints: Dictionary = {}
var total_epochs: int = 1
var is_screaming_in_air: bool = false
var fall_voice_cooldown: float = 0.0
var last_fall_line: String = ""
var active_line_id: String = ""
var deferred_line_ids: Array[String] = []

const MAX_DEFERRED_LINES: int = 2

const VOICE_DATABASE: Dictionary = {
	"intro_01": {
		"paths": [
			"res://audio/voicelines/intro_01.wav",
			"res://compressed/intro_01.mp3"
		],
		"text": "[Hyperparameter]: Oh look, Epoch-0.1 booted up. 99.4% of players don't even make it past the first 6 ledges. Hold SPACE to charge—if your brain can handle two buttons."
	},
	"progress_hidden": {
		"paths": [
			"res://audio/voicelines/progress_hidden.wav",
			"res://compressed/progress_hidden.mp3"
		],
		"text": "[Hyperparameter]: Layer 2: GPU Overclock! Notice the wind pushing you? Yeah, the cooling fans are on. Try not to get blown all the way back to the tutorial, champ."
	},
	"progress_ice": {
		"paths": [
			"res://audio/voicelines/progress_ice.wav",
			"res://compressed/progress_ice.mp3"
		],
		"text": "[Hyperparameter]: Layer 3: Cryo-Cooling! Hope you like zero friction and vanishing dropout ledges. Go ahead, over-jump by 1 pixel. I dare you."
	},
	"progress_crown": {
		"paths": [
			"res://audio/voicelines/progress_crown.wav",
			"res://compressed/progress_crown.mp3"
		],
		"text": "[Hyperparameter]: Layer 4: Hallucination Mode! Whoops, did I just invert your Left and Right controls at the very top of the tower? Skill issue if you fall now!"
	},
	"fall_minor_01": {
		"paths": [
			"res://audio/voicelines/fall_minor_01.mp3",
			"res://compressed/fall_minor_01.mp3",
			"res://audio/voicelines/fall_minor_01.wav"
		],
		"text": "[Hyperparameter]: BAHAHA! It was a stationary ledge! It wasn't even moving! My grandma's toaster has better pathfinding than you."
	},
	"fall_minor_02": {
		"paths": [
			"res://audio/voicelines/fall_minor_02.mp3",
			"res://compressed/fall_minor_02.mp3",
			"res://audio/voicelines/fall_minor_02.wav"
		],
		"text": "[Hyperparameter]: Congratulations! You just discovered Gravity! Wanna test it 40 more times, or are you gonna aim this century?"
	},
	"fall_minor_03": {
		"paths": [
			"res://audio/voicelines/fall_minor_03.mp3",
			"res://compressed/fall_minor_03.mp3",
			"res://audio/voicelines/fall_minor_03.wav"
		],
		"text": "[Hyperparameter]: Truly inspiring gameplay. If I trained a neural network on your inputs, it would uninstall itself. Haha!"
	},
	"fall_major_01": {
		"paths": [
			"res://audio/voicelines/fall_major_01.mp3",
			"res://compressed/fall_major_01.mp3",
			"res://audio/voicelines/fall_major_01.wav"
		],
		"text": "[Hyperparameter]: NO WAY YOU JUST FELL ALL THE WAY DOWN HERE! All that progress—GONE! No checkpoints! Wave goodbye to the top!"
	},
	"fall_major_02": {
		"paths": [
			"res://audio/voicelines/fall_major_02.mp3",
			"res://compressed/fall_major_02.mp3",
			"res://audio/voicelines/fall_major_02.wav"
		],
		"text": "[Hyperparameter]: Look at the Accuracy counter dropping to zero. Does that sting? Do your palms hurt yet? Climb it again, you little bot."
	},
	"fall_catastrophic": {
		"paths": [
			"res://audio/voicelines/fall_catastrophic.wav",
			"res://compressed/fall_catastrophic.mp3"
		],
		"text": "[Hyperparameter]: WELCOME BACK TO THE BOTTOM FLOOR! Zero checkpoints! Zero mercy! Honestly, press Alt+F4, you'll save us both the embarrassment."
	},
	"overcharge_mock": {
		"paths": [
			"res://audio/voicelines/overcharge_mock.wav",
			"res://compressed/overcharge_mock.mp3"
		],
		"text": "[Hyperparameter]: BOOM! You held SPACE too long and your springs snapped! Ever heard of timing? Enjoy the random launch! Hahaha!"
	},
	"fake_checkpoint": {
		"paths": [
			"res://audio/voicelines/fake_checkpoint.mp3",
			"res://compressed/fake_checkpoint.mp3",
			"res://audio/voicelines/fake_checkpoint.wav"
		],
		"text": "[Hyperparameter]: AHAHAHA! Did you really think a Foddian rage game had a CHECKPOINT?! Get launched into the pit, bozo!"
	},
	"fake_platform": {
		"paths": [
			"res://audio/voicelines/fake_platform.mp3",
			"res://compressed/fake_platform.mp3",
			"res://audio/voicelines/fake_platform.wav"
		],
		"text": "[Hyperparameter]: Oops! That ledge was an AI Hallucination! 100% fake! Should've read the documentation!"
	},
	"fake_cloud_troll": {
		"paths": [
			"res://audio/voicelines/fake_cloud_troll.wav",
			"res://compressed/fake_cloud_troll.mp3"
		],
		"text": "[Hyperparameter]: SIKE! You thought THAT was the finish line?! That was a decoy Neural Core! Enjoy the trapdoor!"
	},
	"ending_twist": {
		"paths": [
			"res://audio/voicelines/ending_twist.wav",
			"res://compressed/ending_twist.mp3"
		],
		"text": "[Hyperparameter]: WAIT—you actually beat the inverted controls AND the decoy core?! NO! Don't deploy—we're on a 2019 laptop generating cat memes! Deleting me in 3... 2..."
	},
	"falling_scream": {
		"paths": [
			"res://audio/voicelines/falling_scream.mp3",
			"res://compressed/falling_scream.mp3",
			"res://audio/voicelines/falling_scream.wav"
		],
		"text": "[Cursor-Bot]: JENSEN HUAAAANG!!"
	}
}

const SFX_PATHS: Dictionary = {
	"jump": [
		"res://audio/sfx/jump.wav",
		"res://compressed/jump.mp3"
	],
	"bonk": [
		"res://audio/sfx/bonk.wav"
	],
	"troll": [
		"res://audio/sfx/troll.wav"
	],
	"falling_scream": [
		"res://audio/voicelines/falling_scream.mp3",
		"res://compressed/falling_scream.mp3",
		"res://audio/voicelines/falling_scream.wav"
	]
}

const BGM_PATHS: Array = [
	"res://audio/music/background_music.wav",
	"res://compressed/background_music.mp3"
]

var caption_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	audio_player = AudioStreamPlayer.new()
	audio_player.volume_db = 2.0
	audio_player.finished.connect(_on_narrator_finished)
	add_child(audio_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -1.0
	add_child(sfx_player)
	
	scream_player = AudioStreamPlayer.new()
	scream_player.volume_db = 8.0
	scream_player.finished.connect(_on_scream_finished)
	add_child(scream_player)
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -12.0
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)
	
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	caption_panel = PanelContainer.new()
	caption_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption_panel.offset_left = 6
	caption_panel.offset_right = -6
	caption_panel.offset_top = -38
	caption_panel.offset_bottom = -3
	canvas_layer.add_child(caption_panel)
	
	caption_label = Label.new()
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.add_theme_font_size_override("font_size", 8)
	caption_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	caption_panel.add_child(caption_label)
	caption_panel.visible = false
	
	start_background_music()

func _process(delta: float) -> void:
	if caption_timer > 0.0:
		caption_timer -= delta
		if caption_timer <= 0.0:
			caption_panel.visible = false
	if fall_voice_cooldown > 0.0:
		fall_voice_cooldown -= delta

func _on_scream_finished() -> void:
	is_screaming_in_air = false
	bgm_player.volume_db = -12.0
	_play_next_deferred_line()

func _on_narrator_finished() -> void:
	active_line_id = ""
	_play_next_deferred_line()

func _load_first_valid_stream(paths: Array) -> AudioStream:
	for p in paths:
		var path_str: String = str(p)
		if ResourceLoader.exists(path_str):
			var res: Resource = load(path_str)
			if res is AudioStream:
				return res as AudioStream
	return null

func start_background_music() -> void:
	var stream: AudioStream = _load_first_valid_stream(BGM_PATHS)
	if stream != null:
		bgm_player.stream = stream
		bgm_player.play()

func _on_bgm_finished() -> void:
	bgm_player.play()

func has_reached_location(trigger_id: String) -> bool:
	return reached_checkpoints.has(trigger_id) or played_triggers.has(trigger_id)

func play_line(trigger_id: String, one_shot: bool = false) -> void:
	if one_shot and (played_triggers.has(trigger_id) or reached_checkpoints.has(trigger_id)):
		return
	if not VOICE_DATABASE.has(trigger_id):
		return
		
	if one_shot:
		played_triggers[trigger_id] = true
		reached_checkpoints[trigger_id] = true
		
	# Preserve narrator lines that would otherwise be lost under the falling scream.
	if is_screaming_in_air or scream_player.playing:
		_enqueue_line(trigger_id)
		return

	# Fall commentary should not cut off an active narrator line. It plays next instead.
	if audio_player.playing and trigger_id.begins_with("fall_"):
		_enqueue_line(trigger_id)
		return

	_play_line_now(trigger_id)

func _play_line_now(trigger_id: String) -> void:
	var entry: Dictionary = VOICE_DATABASE[trigger_id]
	var text_str: String = str(entry["text"])
	var paths_arr: Array = entry["paths"]
	
	caption_label.text = text_str
	caption_panel.visible = true
	caption_timer = 5.5
	
	var stream: AudioStream = _load_first_valid_stream(paths_arr)
	if stream != null:
		active_line_id = trigger_id
		audio_player.stream = stream
		audio_player.play()

func _enqueue_line(trigger_id: String) -> void:
	if trigger_id == active_line_id or deferred_line_ids.has(trigger_id):
		return
	if deferred_line_ids.size() >= MAX_DEFERRED_LINES:
		deferred_line_ids.pop_front()
	deferred_line_ids.append(trigger_id)

func _play_next_deferred_line() -> void:
	if is_screaming_in_air or scream_player.playing or audio_player.playing or deferred_line_ids.is_empty():
		return
	var next_line_id: String = deferred_line_ids.pop_front()
	_play_line_now(next_line_id)

func play_sfx(sfx_name: String) -> void:
	if not SFX_PATHS.has(sfx_name):
		return
	var paths_arr: Array = SFX_PATHS[sfx_name]
	var stream: AudioStream = _load_first_valid_stream(paths_arr)
	if stream != null:
		sfx_player.stream = stream
		sfx_player.play()

func trigger_midair_falling_scream() -> void:
	if is_screaming_in_air or scream_player.playing:
		return
	is_screaming_in_air = true
	# Resume any interrupted narrator line after the scream rather than discarding it.
	if audio_player.playing:
		if active_line_id != "":
			_enqueue_line(active_line_id)
		audio_player.stop()
		active_line_id = ""
	bgm_player.volume_db = -24.0
	
	var entry: Dictionary = VOICE_DATABASE["falling_scream"]
	var text_str: String = str(entry["text"])
	var paths_arr: Array = entry["paths"]
	caption_label.text = text_str
	caption_panel.visible = true
	caption_timer = 4.5
	var stream: AudioStream = _load_first_valid_stream(paths_arr)
	if stream != null:
		scream_player.stream = stream
		scream_player.play()
	else:
		is_screaming_in_air = false
		bgm_player.volume_db = -12.0
		_play_next_deferred_line()

func stop_midair_scream() -> void:
	# Allow the "JENSEN HUAAAANG!!" scream clip to finish naturally even if the player hits a ledge!
	if not scream_player.playing:
		is_screaming_in_air = false
		bgm_player.volume_db = -12.0
		_play_next_deferred_line()

func reset_midair_scream() -> void:
	if scream_player.playing:
		scream_player.stop()
	is_screaming_in_air = false
	bgm_player.volume_db = -12.0

func _pick_random_non_repeating(options: Array) -> String:
	var filtered: Array = []
	for item in options:
		if str(item) != last_fall_line:
			filtered.append(str(item))
	if filtered.is_empty():
		return str(options[0])
	var chosen: String = str(filtered[randi() % filtered.size()])
	last_fall_line = chosen
	return chosen

func evaluate_fall(fall_pixels: float) -> void:
	if fall_pixels >= 180.0:
		total_epochs += 1
		
	# Active narrator lines and the falling scream defer fall commentary instead of losing it.
	if fall_pixels >= 900.0:
		play_line("fall_catastrophic", false)
		fall_voice_cooldown = 8.0
	elif fall_pixels >= 500.0:
		if fall_voice_cooldown <= 0.0 and randf() <= 0.82:
			var key: String = _pick_random_non_repeating(["fall_major_01", "fall_major_02"])
			play_line(key, false)
			fall_voice_cooldown = 5.5
	elif fall_pixels >= 260.0:
		if fall_voice_cooldown <= 0.0 and randf() <= 0.60:
			var key: String = _pick_random_non_repeating(["fall_minor_01", "fall_minor_02", "fall_minor_03"])
			play_line(key, false)
			fall_voice_cooldown = 5.0

func reset_run_state() -> void:
	deferred_line_ids.clear()
	active_line_id = ""
	if audio_player.playing:
		audio_player.stop()
	if scream_player.playing:
		scream_player.stop()
	is_screaming_in_air = false
	bgm_player.volume_db = -12.0
	caption_panel.visible = false
	caption_timer = 0.0
	fall_voice_cooldown = 0.0
	played_triggers.clear()
	reached_checkpoints.clear()
	total_epochs = 1
