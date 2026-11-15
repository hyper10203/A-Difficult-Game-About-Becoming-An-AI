extends CharacterBody2D

@export_group("Movement & Jump")
@export var walk_speed: float = 95.0
@export var gravity: float = 740.0
@export var min_jump_force: float = 175.0
@export var max_jump_force: float = 410.0
@export var max_charge_time: float = 0.80
@export var overcharge_limit: float = 1.50
@export var horizontal_jump_speed: float = 170.0
@export var air_control_speed: float = 145.0
@export var air_acceleration: float = 600.0
@export var wall_bounce_retention: float = 0.55
# Unintentional fall threshold: ~95px (~1.5 ledge spacing below your highest point or takeoff ledge)
@export var unintentional_scream_fall_distance: float = 175.0
@export var drop_below_ledge_scream_distance: float = 120.0
@export_range(0.0, 1.0, 0.01) var falling_scream_chance: float = 0.33

@export_group("Ice & Surface Physics")
@export var normal_friction: float = 1000.0
@export var ice_friction: float = 125.0
@export var ice_acceleration: float = 280.0

var charge_timer: float = 0.0
var is_charging: bool = false
var jump_dir: float = 0.0
var highest_y_before_fall: float = 0.0
var last_standing_y: float = 0.0
var was_on_floor: bool = false
var stun_timer: float = 0.0
var wind_timer: float = 0.0
var anim_timer: float = 0.0
var coyote_timer: float = 0.0
var current_wind_dir: float = 1.0
var current_section_name: String = "LAYER 1: INPUT LAYER"
var pending_landing_voice_line: String = ""
var controls_locked: bool = true
var has_rolled_falling_scream: bool = false

var tex_idle: Array[Texture2D] = [
	preload("res://assets/player/idle_1.png"),
	preload("res://assets/player/idle_2.png"),
	preload("res://assets/player/idle_3.png")
]
var tex_run: Array[Texture2D] = [
	preload("res://assets/player/run_1.png"),
	preload("res://assets/player/run_2.png"),
	preload("res://assets/player/run_3.png")
]
var tex_jump_charge: Texture2D = preload("res://assets/player/jump_1_charge.png")
var tex_jump_launch: Texture2D = preload("res://assets/player/jump_2_launch.png")
var tex_jump_air: Texture2D = preload("res://assets/player/jump_3_air.png")
var tex_click: Texture2D = preload("res://assets/player/click_action.png")
var tex_hover_bonk: Texture2D = preload("res://assets/player/hover_arrow.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var charge_bar: ProgressBar = $ProgressBar
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	charge_bar.visible = false
	highest_y_before_fall = global_position.y
	last_standing_y = global_position.y
	sprite.texture = tex_idle[0]

func queue_landing_voice_line(trigger_id: String) -> void:
	pending_landing_voice_line = trigger_id

func _physics_process(delta: float) -> void:
	if controls_locked:
		return
	wind_timer += delta
	anim_timer += delta
	if stun_timer > 0.0:
		stun_timer -= delta

	# Debug keys 1-5 for instant layer/long-fall testing in Godot
	if Input.is_key_pressed(KEY_1):
		global_position = Vector2(70, -20)
		velocity = Vector2.ZERO
		highest_y_before_fall = global_position.y
		last_standing_y = global_position.y
		pending_landing_voice_line = ""
		VoiceManager.reset_midair_scream()
	elif Input.is_key_pressed(KEY_2):
		global_position = Vector2(70, -585)
		velocity = Vector2.ZERO
		highest_y_before_fall = global_position.y
		last_standing_y = global_position.y
		pending_landing_voice_line = ""
		VoiceManager.reset_midair_scream()
	elif Input.is_key_pressed(KEY_3):
		global_position = Vector2(240, -1255)
		velocity = Vector2.ZERO
		highest_y_before_fall = global_position.y
		last_standing_y = global_position.y
		pending_landing_voice_line = ""
		VoiceManager.reset_midair_scream()
	elif Input.is_key_pressed(KEY_4):
		global_position = Vector2(70, -1870)
		velocity = Vector2.ZERO
		highest_y_before_fall = global_position.y
		last_standing_y = global_position.y
		pending_landing_voice_line = ""
		VoiceManager.reset_midair_scream()
	elif Input.is_key_pressed(KEY_5):
		# Test JENSEN HUANG Scream (clear vertical drop lane + instant scream trigger)
		if not VoiceManager.scream_player.playing:
			global_position = Vector2(128, -2380)
			velocity = Vector2(0, 220)
			highest_y_before_fall = -2550.0
			last_standing_y = -2500.0
			pending_landing_voice_line = ""
			VoiceManager.trigger_midair_falling_scream()

	# Safety catch if somehow below the bottom floor: place right onto the floor so landing triggers cleanly
	if global_position.y > 40.0:
		global_position = Vector2(clampf(global_position.x, 24.0, 296.0), 0.0)
		velocity.y = 0.0

	var is_inverted_zone: bool = global_position.y < -1800.0
	var is_wind_zone: bool = global_position.y < -550.0 and global_position.y >= -1200.0
	var is_cryo_zone: bool = global_position.y < -1200.0 and global_position.y >= -1800.0

	if is_inverted_zone:
		current_section_name = "LAYER 4: INVERTED CONTROLS!"
		sprite.modulate = Color(1.0, 0.55, 1.0)
	elif is_cryo_zone:
		current_section_name = "LAYER 3: CRYO SLIDE & DROPOUT"
		sprite.modulate = Color(0.65, 1.0, 1.0)
	elif is_wind_zone:
		current_wind_dir = 1.0 if sin(wind_timer * 1.2) >= 0.0 else -1.0
		var wind_arrow: String = ">>>" if current_wind_dir > 0.0 else "<<<"
		current_section_name = "LAYER 2: GPU FAN WIND " + wind_arrow
		sprite.modulate = Color(1.0, 0.9, 0.55)
	else:
		current_section_name = "LAYER 1: INPUT LAYER"
		sprite.modulate = Color.WHITE

	var input_dir: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir += 1.0

	if is_inverted_zone:
		input_dir = -input_dir

	if input_dir != 0.0 and stun_timer <= 0.0:
		sprite.flip_h = input_dir < 0.0

	var on_ice: bool = _is_standing_on_ice() or is_cryo_zone
	var current_friction: float = ice_friction if on_ice else normal_friction
	var jump_held: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)

	if is_on_floor():
		coyote_timer = 0.12
		sprite.rotation_degrees = 0.0
		if not was_on_floor:
			var fall_distance: float = global_position.y - highest_y_before_fall
			VoiceManager.stop_midair_scream()
			if pending_landing_voice_line != "" and fall_distance < 480.0 and not VoiceManager.scream_player.playing:
				VoiceManager.play_line(pending_landing_voice_line, false)
			else:
				VoiceManager.evaluate_fall(fall_distance)
			pending_landing_voice_line = ""
			
			if fall_distance >= 280.0:
				stun_timer = 0.25
				sprite.texture = tex_hover_bonk
				sprite.scale = Vector2(0.85, 0.35)
				_trigger_camera_shake(minf(fall_distance * 0.02, 10.0))
				VoiceManager.play_sfx("bonk")
		
		highest_y_before_fall = global_position.y
		last_standing_y = global_position.y
		was_on_floor = true

		if jump_held and stun_timer <= 0.0:
			is_charging = true
			if input_dir != 0.0:
				jump_dir = input_dir
				velocity.x = move_toward(velocity.x, input_dir * (walk_speed * 0.45), current_friction * delta)
			else:
				jump_dir = 0.0
				velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)
				
			charge_timer += delta
			
			var charge_ratio: float = clampf(charge_timer / max_charge_time, 0.0, 1.0)
			sprite.texture = tex_click if charge_ratio > 0.65 else tex_jump_charge
			sprite.scale = Vector2(0.55 + (charge_ratio * 0.2), 0.55 - (charge_ratio * 0.2))
			charge_bar.visible = true
			charge_bar.value = charge_ratio * 100.0
			
			if charge_timer > max_charge_time:
				charge_bar.modulate = Color(1.0, 0.1, 0.1) if int(charge_timer * 20.0) % 2 == 0 else Color.YELLOW
			else:
				charge_bar.modulate = Color.WHITE
				
			if charge_timer >= overcharge_limit:
				_execute_overcharge_backfire()
		elif is_charging and not jump_held:
			_execute_jump(input_dir)
		else:
			if stun_timer <= 0.0:
				sprite.scale = Vector2(0.55, 0.55)
				if absf(velocity.x) > 8.0 or input_dir != 0.0:
					var run_idx: int = int(anim_timer * 10.0) % 3
					sprite.texture = tex_run[run_idx]
				else:
					var idle_idx: int = int(anim_timer * 5.0) % 3
					sprite.texture = tex_idle[idle_idx]
					
			if input_dir != 0.0 and stun_timer <= 0.0:
				if on_ice:
					velocity.x = move_toward(velocity.x, input_dir * walk_speed * 1.12, ice_acceleration * delta)
				else:
					velocity.x = input_dir * walk_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)
	else:
		if was_on_floor:
			# Roll only once for each airborne fall; otherwise a 33% check every frame would become near-certain.
			has_rolled_falling_scream = false
		was_on_floor = false
		if coyote_timer > 0.0:
			coyote_timer -= delta
			if is_charging and not jump_held:
				_execute_jump(input_dir)
		else:
			if is_charging and not jump_held:
				is_charging = false
				charge_timer = 0.0
				charge_bar.visible = false

		var active_gravity: float = gravity * (0.84 if is_cryo_zone else 1.0)
		velocity.y += active_gravity * delta
		
		if input_dir != 0.0 and stun_timer <= 0.0:
			var target_air_vx: float = input_dir * air_control_speed
			if signf(velocity.x) != input_dir or absf(velocity.x) < absf(target_air_vx):
				velocity.x = move_toward(velocity.x, target_air_vx, air_acceleration * delta)
		
		if is_wind_zone:
			velocity.x += current_wind_dir * 32.0 * delta
			
		if velocity.y < -120.0:
			sprite.texture = tex_jump_air
		elif velocity.y < 110.0:
			sprite.texture = tex_jump_launch
		else:
			sprite.texture = tex_hover_bonk
			sprite.rotation_degrees += 540.0 * delta
			
		# Trigger "JENSEN HUAAAANG!!" as soon as an unintentional fall is detected!
		# An unintentional fall is when:
		# 1) You drop at least 55px below the ledge you took off from (missed jump / slipped off ledge), OR
		# 2) You drop at least `unintentional_scream_fall_distance` (95px) from your jump apex
		if velocity.y > 165.0:
			var drop_from_peak: float = global_position.y - highest_y_before_fall
			var drop_below_takeoff_ledge: float = global_position.y - last_standing_y
			if not has_rolled_falling_scream and (drop_below_takeoff_ledge >= drop_below_ledge_scream_distance or drop_from_peak >= unintentional_scream_fall_distance):
				has_rolled_falling_scream = true
				if randf() <= falling_scream_chance:
					VoiceManager.trigger_midair_falling_scream()
			
		if global_position.y < highest_y_before_fall:
			highest_y_before_fall = global_position.y

	var pre_collision_vel: Vector2 = velocity
	move_and_slide()

	if not is_on_floor() and is_on_wall():
		velocity.x = -pre_collision_vel.x * wall_bounce_retention
		if absf(velocity.x) < 55.0:
			velocity.x = signf(get_wall_normal().x) * 65.0
		sprite.texture = tex_hover_bonk
		VoiceManager.play_sfx("bonk")

func _execute_jump(current_input: float) -> void:
	var ratio: float = clampf(charge_timer / max_charge_time, 0.0, 1.0)
	var vertical_power: float = lerpf(min_jump_force, max_jump_force, ratio)
	
	velocity.y = -vertical_power
	var final_dir: float = current_input if current_input != 0.0 else jump_dir
	velocity.x = final_dir * horizontal_jump_speed * (0.55 + (ratio * 0.45))
	
	is_charging = false
	charge_timer = 0.0
	coyote_timer = 0.0
	jump_dir = 0.0
	sprite.texture = tex_jump_air
	sprite.scale = Vector2(0.45, 0.7)
	charge_bar.visible = false
	VoiceManager.play_sfx("jump")

func _execute_overcharge_backfire() -> void:
	is_charging = false
	charge_timer = 0.0
	charge_bar.visible = false
	stun_timer = 0.3
	var random_dir: float = -1.0 if randf() < 0.5 else 1.0
	velocity = Vector2(random_dir * 165.0, -175.0)
	sprite.texture = tex_hover_bonk
	sprite.scale = Vector2(0.8, 0.35)
	_trigger_camera_shake(5.0)
	VoiceManager.play_sfx("troll")
	pending_landing_voice_line = "overcharge_mock"

func _is_standing_on_ice() -> bool:
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is Node and (collider as Node).is_in_group("ice_surface") and collision.get_normal().y < -0.5:
			return true
	return false

func apply_hazard_knockback(impulse: Vector2) -> void:
	is_charging = false
	charge_timer = 0.0
	charge_bar.visible = false
	stun_timer = 0.25
	velocity = impulse
	sprite.texture = tex_hover_bonk
	sprite.scale = Vector2(0.75, 0.4)
	_trigger_camera_shake(6.0)
	VoiceManager.play_sfx("bonk")

func _trigger_camera_shake(strength: float) -> void:
	if not camera:
		return
	var tween: Tween = create_tween()
	for i in range(6):
		tween.tween_property(camera, "offset", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)
