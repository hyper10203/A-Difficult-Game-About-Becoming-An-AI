extends AnimatableBody2D

@export var rotation_speed_deg: float = 135.0
@export var move_offset: Vector2 = Vector2(64, 0)
@export var move_speed: float = 2.1
@export var knockback_teeth: bool = true
@export var knockback_strength: float = 250.0

var start_pos: Vector2
var time_passed: float = 0.0

@onready var teeth_hitbox: Area2D = $TeethHitbox

func _ready() -> void:
	start_pos = global_position
	if teeth_hitbox:
		teeth_hitbox.body_entered.connect(_on_teeth_body_entered)

func _physics_process(delta: float) -> void:
	time_passed += delta * move_speed
	rotation_degrees += rotation_speed_deg * delta
	
	if move_offset != Vector2.ZERO:
		var weight: float = (sin(time_passed) + 1.0) * 0.5
		global_position = start_pos.lerp(start_pos + move_offset, weight)

func _on_teeth_body_entered(body: Node2D) -> void:
	if not knockback_teeth:
		return
	if body.has_method("apply_hazard_knockback"):
		var dir_from_center: Vector2 = (body.global_position - global_position).normalized()
		var spin_sign: float = signf(rotation_speed_deg)
		var tangent: Vector2 = Vector2(-dir_from_center.y, dir_from_center.x) * spin_sign
		var launch_vector: Vector2 = ((dir_from_center * 0.6) + (tangent * 0.8)).normalized() * knockback_strength
		launch_vector.y = minf(launch_vector.y, -135.0)
		body.call("apply_hazard_knockback", launch_vector)
