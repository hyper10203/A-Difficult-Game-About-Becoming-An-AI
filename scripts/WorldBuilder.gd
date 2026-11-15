extends Node2D

const SUMMIT_Y: float = -2450.0

@onready var player: CharacterBody2D = $Player
@onready var hud_label: Label = $HUD/StatsLabel

var circuit_left: Texture2D = preload("res://assets/tiles/circuit_top_left_16x16.png")
var circuit_mid: Texture2D = preload("res://assets/tiles/circuit_top_center_16x16.png")
var circuit_right: Texture2D = preload("res://assets/tiles/circuit_top_right_16x16.png")
var circuit_wall: Texture2D = preload("res://assets/tiles/circuit_mid_center_16x16.png")

var ice_left: Texture2D = preload("res://assets/tiles/ice_top_left_16x16.png")
var ice_mid: Texture2D = preload("res://assets/tiles/ice_top_center_16x16.png")
var ice_right: Texture2D = preload("res://assets/tiles/ice_top_right_16x16.png")

var glitch_tex: Texture2D = preload("res://assets/tiles/circuit_glitch_16x16.png")
var flag_tex: Texture2D = preload("res://assets/player/click_action.png")
var gear_scene: PackedScene = preload("res://scenes/SpinningGear.tscn")
var brain_goal_tex: Texture2D = preload("res://assets/backgrounds/golden_brain_core_64x44.png")
var home_logo_tex: Texture2D = preload("res://assets/ui/home_logo.png")

var bg_tower_tile: Texture2D = preload("res://assets/backgrounds/tower_background_320x640.png")
var bg_biome1: Texture2D = preload("res://assets/backgrounds/biome1_motherboard_server.png")
var bg_biome2: Texture2D = preload("res://assets/backgrounds/biome2_spinning_gears_fans.png")
var bg_biome3: Texture2D = preload("res://assets/backgrounds/biome3_cryo_nitrogen_pipes.png")
var bg_biome4: Texture2D = preload("res://assets/backgrounds/biome4_golden_brain_crown.png")

func _ready() -> void:
	_build_real_tower_backgrounds()
	_build_tower_boundaries()
	_build_rage_course()
	_build_voice_zones()
	_build_home_and_pause_menus()
	if player:
		player.set("controls_locked", true)

func _process(_delta: float) -> void:
	if player and hud_label:
		var height_px: float = maxf(0.0, -player.global_position.y)
		var progress: float = clampf((height_px / absf(SUMMIT_Y)) * 100.0, 0.0, 99.9)
		var loss: float = clampf(1.0 - (progress / 100.0), 0.0001, 1.0)
		hud_label.text = "MODEL: Epoch-0.%d | %s
ACCURACY: %.1f%% | LOSS: %.4f" % [
			VoiceManager.total_epochs,
			player.get("current_section_name"),
			progress,
			loss
		]

func _build_real_tower_backgrounds() -> void:
	# 1. Tile the native 320x640 pixel-art tower background at 1:1 pixel ratio (zero distortion!)
	var tile_y_centers: Array[float] = [-280.0, -920.0, -1560.0, -2200.0, -2840.0]
	for cy in tile_y_centers:
		var base_spr: Sprite2D = Sprite2D.new()
		base_spr.texture = bg_tower_tile
		base_spr.z_index = -25
		base_spr.modulate = Color(0.55, 0.58, 0.65, 1.0)
		base_spr.position = Vector2(160.0, cy)
		base_spr.scale = Vector2.ONE
		add_child(base_spr)

	# 2. Place each biome's art proportionally (uniform aspect ratio, no squishing!)
	var biome_configs: Array = [
		[bg_biome1, -260.0],
		[bg_biome2, -880.0],
		[bg_biome3, -1500.0],
		[bg_biome4, -2160.0]
	]
	for cfg in biome_configs:
		var tex: Texture2D = cfg[0]
		var center_y: float = float(cfg[1])
		# Uniform scale based on height so the 16:9 biome art covers the section without horizontal squishing
		var uniform_scale: float = 640.0 / float(tex.get_height())
		var spr: Sprite2D = Sprite2D.new()
		spr.texture = tex
		spr.z_index = -20
		spr.modulate = Color(0.62, 0.64, 0.72, 0.55)
		spr.position = Vector2(160.0, center_y)
		spr.scale = Vector2(uniform_scale, uniform_scale)
		add_child(spr)

func _build_tower_boundaries() -> void:
	_spawn_platform(Vector2(16, 16), 19, false)
	for y in range(16, -2700, -16):
		_spawn_wall_tile(Vector2(8, y))
		_spawn_wall_tile(Vector2(312, y))

func _spawn_wall_tile(pos: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16.0, 16.0)
	shape.shape = rect
	body.add_child(shape)
	var spr: Sprite2D = Sprite2D.new()
	spr.texture = circuit_wall
	body.add_child(spr)
	add_child(body)

func _build_rage_course() -> void:
	# =========================================================================
	# LAYER 1: INPUT LAYER (y = 0 to -550) - Gradual, fair onboarding!
	# =========================================================================
	_spawn_platform(Vector2(48, -42), 5, false)
	_spawn_platform(Vector2(176, -88), 5, false)
	_spawn_platform(Vector2(56, -138), 4, false)
	_spawn_platform(Vector2(168, -190), 4, false)
	_spawn_platform(Vector2(48, -245), 4, false)
	# Optional side bait fake platform (real path is clearly on the right)
	_spawn_fake_hallucination_platform(Vector2(72, -300), 2)
	_spawn_platform(Vector2(168, -300), 4, false)
	_spawn_platform(Vector2(72, -356), 4, false)
	_spawn_collapsing_platform(Vector2(184, -412), 4)
	_spawn_platform(Vector2(64, -468), 4, false)
	_spawn_platform(Vector2(176, -522), 4, false)
	# Optional bait checkpoint on the far right edge of Layer 1 top
	_spawn_fake_checkpoint(Vector2(276, -538), Vector2(-175, -130))

	# =========================================================================
	# LAYER 2: GPU FAN WIND & GEARS (y = -550 to -1200) - Moderate challenge
	# =========================================================================
	_spawn_platform(Vector2(56, -576), 4, false)
	_spawn_platform(Vector2(176, -632), 4, false)
	_spawn_gear(Vector2(148, -668), Vector2(36, 0), 115.0)
	_spawn_platform(Vector2(56, -692), 3, false)
	_spawn_collapsing_platform(Vector2(160, -750), 3)
	_spawn_platform(Vector2(64, -810), 3, false)
	_spawn_platform(Vector2(184, -868), 3, false)
	_spawn_gear(Vector2(148, -905), Vector2(-40, 0), -125.0)
	_spawn_fake_hallucination_platform(Vector2(224, -925), 2)
	_spawn_platform(Vector2(64, -928), 3, false)
	_spawn_collapsing_platform(Vector2(168, -988), 3)
	_spawn_platform(Vector2(64, -1048), 3, false)
	_spawn_platform(Vector2(184, -1108), 3, false)
	_spawn_platform(Vector2(72, -1168), 4, false)

	# =========================================================================
	# LAYER 3: CRYO SLIDE & DROPOUT (y = -1200 to -1800) - Ice & timing
	# =========================================================================
	_spawn_platform(Vector2(184, -1230), 4, true)
	_spawn_fake_checkpoint(Vector2(276, -1246), Vector2(-185, -140))
	_spawn_platform(Vector2(64, -1292), 3, true)
	_spawn_collapsing_platform(Vector2(168, -1354), 3)
	_spawn_platform(Vector2(64, -1416), 3, true)
	_spawn_gear(Vector2(156, -1454), Vector2(38, 0), 135.0)
	_spawn_platform(Vector2(184, -1480), 3, true)
	_spawn_fake_hallucination_platform(Vector2(192, -1540), 2)
	_spawn_platform(Vector2(64, -1542), 3, true)
	_spawn_collapsing_platform(Vector2(168, -1604), 3)
	_spawn_platform(Vector2(64, -1666), 3, true)
	_spawn_platform(Vector2(184, -1728), 3, true)
	_spawn_platform(Vector2(72, -1788), 3, true)

	# =========================================================================
	# LAYER 4: HALLUCINATION CROWN (y = -1800 to -2450) - Inverted Controls!
	# =========================================================================
	_spawn_platform(Vector2(184, -1850), 3, false)
	_spawn_collapsing_platform(Vector2(80, -1912), 3)
	_spawn_platform(Vector2(184, -1974), 3, true)
	_spawn_sniper_bonk_block(Vector2(152, -2018))
	_spawn_platform(Vector2(64, -2038), 3, false)
	_spawn_collapsing_platform(Vector2(168, -2102), 3)
	_spawn_platform(Vector2(64, -2166), 3, true)
	_spawn_platform(Vector2(176, -2230), 3, false)
	_spawn_platform(Vector2(64, -2292), 3, false)
	
	# Decoy Neural Core on the right vs Real Golden Brain Core on the left
	_spawn_fake_summit_cloud(Vector2(216, -2350))
	
	_spawn_platform(Vector2(64, -2420), 5, false)
	var real_goal: Sprite2D = Sprite2D.new()
	real_goal.texture = brain_goal_tex
	real_goal.position = Vector2(96, -2450)
	add_child(real_goal)

func _get_ledge_tile(idx: int, total: int, is_ice: bool) -> Texture2D:
	if is_ice:
		if idx == 0:
			return ice_left
		elif idx == total - 1:
			return ice_right
		return ice_mid
	else:
		if idx == 0:
			return circuit_left
		elif idx == total - 1:
			return circuit_right
		return circuit_mid

func _spawn_platform(pos: Vector2, tile_count: int, is_ice: bool) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	if is_ice:
		body.add_to_group("ice_surface")
	
	var total_width: float = tile_count * 16.0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(total_width, 16.0)
	shape.shape = rect
	shape.position = Vector2((total_width * 0.5) - 8.0, 0.0)
	body.add_child(shape)
	
	for i in range(tile_count):
		var spr: Sprite2D = Sprite2D.new()
		spr.texture = _get_ledge_tile(i, tile_count, is_ice)
		spr.position = Vector2(i * 16.0, 0.0)
		body.add_child(spr)
		
	add_child(body)

func _spawn_collapsing_platform(pos: Vector2, tile_count: int) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	var total_width: float = tile_count * 16.0
	
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(total_width, 16.0)
	shape.shape = rect
	shape.position = Vector2((total_width * 0.5) - 8.0, 0.0)
	body.add_child(shape)
	
	var visual_root: Node2D = Node2D.new()
	body.add_child(visual_root)
	for i in range(tile_count):
		var spr: Sprite2D = Sprite2D.new()
		spr.texture = glitch_tex
		spr.position = Vector2(i * 16.0, 0.0)
		visual_root.add_child(spr)
		
	var detector: Area2D = Area2D.new()
	var det_shape: CollisionShape2D = CollisionShape2D.new()
	var det_rect: RectangleShape2D = RectangleShape2D.new()
	det_rect.size = Vector2(total_width, 6.0)
	det_shape.shape = det_rect
	det_shape.position = Vector2((total_width * 0.5) - 8.0, -10.0)
	detector.add_child(det_shape)
	body.add_child(detector)
	
	var triggered: Array[bool] = [false]
	detector.body_entered.connect(func(b: Node2D) -> void:
		if b == player and not triggered[0]:
			triggered[0] = true
			var tw: Tween = create_tween()
			# Give 0.65s of shake warning before collapsing so the player has fair time to charge a jump!
			for j in range(13):
				tw.tween_property(visual_root, "position", Vector2(randf_range(-2.0, 2.0), 0), 0.05)
			tw.tween_callback(func() -> void:
				shape.set_deferred("disabled", true)
				visual_root.modulate = Color(1, 1, 1, 0.15)
				VoiceManager.play_sfx("troll")
			)
			tw.tween_interval(2.5)
			tw.tween_callback(func() -> void:
				shape.set_deferred("disabled", false)
				visual_root.position = Vector2.ZERO
				visual_root.modulate = Color.WHITE
				triggered[0] = false
			)
	)
	add_child(body)

func _spawn_fake_hallucination_platform(pos: Vector2, tile_count: int) -> void:
	var root: Node2D = Node2D.new()
	root.position = pos
	var total_width: float = tile_count * 16.0
	for i in range(tile_count):
		var spr: Sprite2D = Sprite2D.new()
		spr.texture = _get_ledge_tile(i, tile_count, false)
		spr.position = Vector2(i * 16.0, 0.0)
		root.add_child(spr)
		
	var detector: Area2D = Area2D.new()
	var det_shape: CollisionShape2D = CollisionShape2D.new()
	var det_rect: RectangleShape2D = RectangleShape2D.new()
	det_rect.size = Vector2(total_width, 16.0)
	det_shape.shape = det_rect
	det_shape.position = Vector2((total_width * 0.5) - 8.0, 0.0)
	detector.add_child(det_shape)
	root.add_child(detector)
	
	detector.body_entered.connect(func(b: Node2D) -> void:
		if b == player:
			root.modulate = Color(1.0, 0.2, 0.8, 0.35)
			VoiceManager.play_sfx("troll")
			b.call("queue_landing_voice_line", "fake_platform")
	)
	add_child(root)

func _spawn_fake_checkpoint(pos: Vector2, launch_impulse: Vector2) -> void:
	var area: Area2D = Area2D.new()
	area.position = pos
	var spr: Sprite2D = Sprite2D.new()
	spr.texture = flag_tex
	spr.scale = Vector2(0.5, 0.5)
	spr.modulate = Color(0.3, 1.0, 0.4)
	area.add_child(spr)
	
	var col: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(14, 16)
	col.shape = rect
	area.add_child(col)
	
	area.body_entered.connect(func(b: Node2D) -> void:
		if b == player and b.has_method("apply_hazard_knockback"):
			spr.modulate = Color(1.0, 0.1, 0.1)
			VoiceManager.play_sfx("troll")
			b.call("queue_landing_voice_line", "fake_checkpoint")
			b.call("apply_hazard_knockback", launch_impulse)
	)
	add_child(area)

func _spawn_sniper_bonk_block(pos: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	body.add_child(shape)
	
	var spr: Sprite2D = Sprite2D.new()
	spr.texture = glitch_tex
	spr.modulate = Color(1, 1, 1, 0.15)
	body.add_child(spr)
	
	var area: Area2D = Area2D.new()
	var acol: CollisionShape2D = CollisionShape2D.new()
	var arect: RectangleShape2D = RectangleShape2D.new()
	arect.size = Vector2(20, 20)
	acol.shape = arect
	area.add_child(acol)
	body.add_child(area)
	
	area.body_entered.connect(func(b: Node2D) -> void:
		if b == player:
			spr.modulate = Color(1.0, 0.2, 0.2, 1.0)
			VoiceManager.play_sfx("troll")
	)
	add_child(body)

func _spawn_fake_summit_cloud(pos: Vector2) -> void:
	_spawn_collapsing_platform(pos, 3)
	var fake_cloud: Sprite2D = Sprite2D.new()
	fake_cloud.texture = brain_goal_tex
	fake_cloud.position = pos + Vector2(16, -26)
	add_child(fake_cloud)
	
	var area: Area2D = Area2D.new()
	area.position = pos + Vector2(16, -16)
	var col: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(48, 24)
	col.shape = rect
	area.add_child(col)
	area.body_entered.connect(func(b: Node2D) -> void:
		if b == player:
			fake_cloud.modulate = Color(1.0, 0.1, 0.1, 0.4)
			VoiceManager.play_sfx("troll")
			b.call("queue_landing_voice_line", "fake_cloud_troll")
	)
	add_child(area)

func _spawn_gear(pos: Vector2, move_vec: Vector2, rot_speed: float) -> void:
	var gear: Node2D = gear_scene.instantiate() as Node2D
	gear.position = pos
	gear.set("move_offset", move_vec)
	gear.set("rotation_speed_deg", rot_speed)
	add_child(gear)

func _build_voice_zones() -> void:
	_create_voice_zone(-555.0, "progress_hidden", true)
	_create_voice_zone(-1205.0, "progress_ice", true)
	_create_voice_zone(-1810.0, "progress_crown", true)
	_create_voice_zone(-2430.0, "ending_twist", true)

func _create_voice_zone(y_pos: float, trigger_id: String, one_shot: bool) -> void:
	var area: Area2D = Area2D.new()
	area.position = Vector2(160, y_pos)
	var col: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(300, 24)
	col.shape = rect
	area.add_child(col)
	var zone_crossed: Array[bool] = [false]
	area.body_entered.connect(func(body: Node2D) -> void:
		if body == player and not zone_crossed[0] and not VoiceManager.has_reached_location(trigger_id):
			# Only trigger when climbing/reaching the zone (not when plummeting downward through it)
			if player.velocity.y <= 120.0:
				zone_crossed[0] = true
				VoiceManager.play_line(trigger_id, true)
				col.set_deferred("disabled", true)
				area.queue_free()
	)
	add_child(area)


var home_layer: CanvasLayer
var pause_layer: CanvasLayer
var game_started: bool = false
var is_game_paused: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
			if game_started:
				_toggle_pause_menu()

func _style_menu_panel(panel: PanelContainer, bg_col: Color, border_col: Color) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)

func _create_styled_button(label_text: String, accent_col: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(172, 22)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.4))
	
	var normal_sb: StyleBoxFlat = StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.08, 0.14, 0.22, 0.95)
	normal_sb.border_color = accent_col
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(2)
	
	var hover_sb: StyleBoxFlat = StyleBoxFlat.new()
	hover_sb.bg_color = Color(0.15, 0.26, 0.38, 1.0)
	hover_sb.border_color = Color(1.0, 0.9, 0.3, 1.0)
	hover_sb.set_border_width_all(1)
	hover_sb.set_corner_radius_all(2)
	
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)
	return btn

func _build_home_and_pause_menus() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# =========================================================================
	# 1. HOME SCREEN OVERLAY
	# =========================================================================
	home_layer = CanvasLayer.new()
	home_layer.layer = 20
	home_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(home_layer)
	
	var home_bg: ColorRect = ColorRect.new()
	home_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	home_bg.color = Color(0.03, 0.05, 0.10, 0.88)
	home_layer.add_child(home_bg)
	
	var home_center: CenterContainer = CenterContainer.new()
	home_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	home_layer.add_child(home_center)
	
	var home_panel: PanelContainer = PanelContainer.new()
	home_panel.custom_minimum_size = Vector2(300, 170)
	_style_menu_panel(home_panel, Color(0.06, 0.10, 0.18, 0.96), Color(0.0, 0.95, 0.85, 1.0))
	home_center.add_child(home_panel)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	home_panel.add_child(vbox)

	var logo_rect: TextureRect = TextureRect.new()
	logo_rect.texture = home_logo_tex
	logo_rect.custom_minimum_size = Vector2(188, 74)
	logo_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(logo_rect)
	
	var sub_lbl: Label = Label.new()
	sub_lbl.text = "CHARGE: SPACE / W / UP   •   STEER: A / D OR ARROWS\nESC / P: PAUSE"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 8)
	sub_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	vbox.add_child(sub_lbl)
	
	var btn_box: VBoxContainer = VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_box.add_theme_constant_override("separation", 4)
	vbox.add_child(btn_box)
	
	var start_btn: Button = _create_styled_button("START TRAINING", Color(0.0, 0.95, 0.8))
	start_btn.pressed.connect(_on_start_game_pressed)
	btn_box.add_child(start_btn)
	
	var home_quit_btn: Button = _create_styled_button("QUIT TO DESKTOP", Color(1.0, 0.35, 0.45))
	home_quit_btn.pressed.connect(func() -> void: get_tree().quit())
	btn_box.add_child(home_quit_btn)
	
	# =========================================================================
	# 2. PAUSE SCREEN OVERLAY (ESC / P)
	# =========================================================================
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 25
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	add_child(pause_layer)
	
	var pause_bg: ColorRect = ColorRect.new()
	pause_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_bg.color = Color(0.02, 0.03, 0.07, 0.80)
	pause_layer.add_child(pause_bg)
	
	var pause_center: CenterContainer = CenterContainer.new()
	pause_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(pause_center)
	
	var pause_panel: PanelContainer = PanelContainer.new()
	pause_panel.custom_minimum_size = Vector2(286, 158)
	_style_menu_panel(pause_panel, Color(0.07, 0.11, 0.20, 0.96), Color(1.0, 0.82, 0.25, 1.0))
	pause_center.add_child(pause_panel)
	
	var pvbox: VBoxContainer = VBoxContainer.new()
	pvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pvbox.add_theme_constant_override("separation", 6)
	pause_panel.add_child(pvbox)
	
	var ptitle: Label = Label.new()
	ptitle.text = "// TRAINING PAUSED //"
	ptitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ptitle.add_theme_font_size_override("font_size", 13)
	ptitle.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	pvbox.add_child(ptitle)
	
	var psub: Label = Label.new()
	psub.text = "Your ascent is frozen. Choose how to continue."
	psub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	psub.add_theme_font_size_override("font_size", 9)
	psub.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	pvbox.add_child(psub)
	
	var pbtn_box: VBoxContainer = VBoxContainer.new()
	pbtn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pbtn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pbtn_box.add_theme_constant_override("separation", 5)
	pvbox.add_child(pbtn_box)
	
	var resume_btn: Button = _create_styled_button("RESUME (ESC)", Color(0.0, 0.95, 0.8))
	resume_btn.pressed.connect(_toggle_pause_menu)
	pbtn_box.add_child(resume_btn)
	
	var restart_btn: Button = _create_styled_button("RESTART EPOCH", Color(0.3, 0.75, 1.0))
	restart_btn.pressed.connect(_on_restart_pressed)
	pbtn_box.add_child(restart_btn)
	
	var menu_btn: Button = _create_styled_button("HOME SCREEN", Color(0.95, 0.65, 0.2))
	menu_btn.pressed.connect(_on_return_home_pressed)
	pbtn_box.add_child(menu_btn)
	
	var pause_quit_btn: Button = _create_styled_button("QUIT GAME", Color(1.0, 0.35, 0.45))
	pause_quit_btn.pressed.connect(func() -> void: get_tree().quit())
	pbtn_box.add_child(pause_quit_btn)
	
	# Add a small top-right Pause hint on HUD
	var pause_hint: Label = Label.new()
	pause_hint.text = "[ESC/P: PAUSE]"
	pause_hint.position = Vector2(238, 4)
	pause_hint.add_theme_font_size_override("font_size", 9)
	pause_hint.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0, 0.95))
	$HUD.add_child(pause_hint)

func _on_start_game_pressed() -> void:
	game_started = true
	is_game_paused = false
	get_tree().paused = false
	home_layer.visible = false
	pause_layer.visible = false
	if player:
		player.set("controls_locked", false)
	VoiceManager.play_sfx("jump")
	VoiceManager.play_line("intro_01", true)

func _toggle_pause_menu() -> void:
	if not game_started:
		return
	is_game_paused = not is_game_paused
	get_tree().paused = is_game_paused
	pause_layer.visible = is_game_paused

func _on_restart_pressed() -> void:
	get_tree().paused = false
	is_game_paused = false
	pause_layer.visible = false
	VoiceManager.reset_run_state()
	if player:
		player.global_position = Vector2(65, -12)
		player.velocity = Vector2.ZERO
		player.set("highest_y_before_fall", -12.0)
		player.set("last_standing_y", -12.0)
		player.set("pending_landing_voice_line", "")
		player.set("controls_locked", false)
	VoiceManager.play_line("intro_01", true)

func _on_return_home_pressed() -> void:
	get_tree().paused = false
	is_game_paused = false
	game_started = false
	pause_layer.visible = false
	home_layer.visible = true
	VoiceManager.reset_run_state()
	if player:
		player.global_position = Vector2(65, -12)
		player.velocity = Vector2.ZERO
		player.set("highest_y_before_fall", -12.0)
		player.set("last_standing_y", -12.0)
		player.set("pending_landing_voice_line", "")
		player.set("controls_locked", true)
