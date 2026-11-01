extends CharacterBody3D
class_name Bot3D

@export var max_health: float = 100.0
@export var move_speed: float = 2.8
@export var detection_range: float = 34.0
@export var attack_range: float = 19.0
@export var fire_rate: float = 1.15
@export var damage: float = 9.0

var health: float
var target: Node3D
var attack_cooldown: float = 0.0
var body_mesh: MeshInstance3D

func _ready() -> void:
	health = max_health
	add_to_group("bots")
	_build_bot()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > detection_range:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
	elif distance > attack_range:
		var direction := offset.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 7.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if distance > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-offset.x, -offset.z), 8.0 * delta)
		if attack_cooldown <= 0.0:
			_fire_at_target()
			attack_cooldown = fire_rate
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _build_bot() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	body_mesh = MeshInstance3D.new()
	var body_shape := CapsuleMesh.new()
	body_shape.radius = 0.36
	body_shape.height = 1.7
	body_mesh.mesh = body_shape
	body_mesh.position.y = 0.9
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.48, 0.12, 0.10)
	body_material.roughness = 0.8
	body_mesh.material_override = body_material
	add_child(body_mesh)

	var head := MeshInstance3D.new()
	var head_shape := SphereMesh.new()
	head_shape.radius = 0.21
	head_shape.height = 0.42
	head.mesh = head_shape
	head.position.y = 1.88
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.65, 0.47, 0.35)
	head.material_override = head_material
	add_child(head)

	var gun := MeshInstance3D.new()
	var gun_shape := BoxMesh.new()
	gun_shape.size = Vector3(0.12, 0.12, 0.7)
	gun.mesh = gun_shape
	gun.position = Vector3(0.3, 1.25, -0.3)
	add_child(gun)

func _fire_at_target() -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	var from := global_position + Vector3(0.0, 1.35, 0.0)
	var to := target.global_position + Vector3(0.0, 1.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.get("collider") == target:
		target.call("take_damage", damage)

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		queue_free()
