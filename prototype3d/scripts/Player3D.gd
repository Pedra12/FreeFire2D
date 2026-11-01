extends CharacterBody3D
class_name Player3D

@export var move_speed: float = 5.5
@export var acceleration: float = 18.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.004

var camera_yaw: float = 0.0
var camera_pitch: float = -0.16
var fire_cooldown: float = 0.0
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var weapon: MeshInstance3D
var shot_ray: RayCast3D

func _ready() -> void:
	_build_collision()
	_build_character()
	_build_camera()

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis_yaw := Basis(Vector3.UP, camera_yaw)
	var direction := basis_yaw * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	direction = direction.normalized()

	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if direction.length() > 0.08:
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
			_rotate_camera(event.relative * touch_sensitivity)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rotate_camera(event.relative * mouse_sensitivity)

func _rotate_camera(delta: Vector2) -> void:
	camera_yaw -= delta.x
	camera_pitch = clampf(camera_pitch - delta.y, -0.75, 0.25)
	if is_instance_valid(camera_pivot):
		camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0.0)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

func _build_character() -> void:
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.36
	body_mesh.height = 1.75
	body.mesh = body_mesh
	body.position.y = 0.92
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.12, 0.28, 0.42)
	body_material.roughness = 0.82
	body.material_override = body_material
	add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.93, 0.0)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.72, 0.52, 0.38)
	head.material_override = skin
	add_child(head)

	weapon = MeshInstance3D.new()
	var gun_mesh := BoxMesh.new()
	gun_mesh.size = Vector3(0.13, 0.13, 0.85)
	weapon.mesh = gun_mesh
	weapon.position = Vector3(0.36, 1.28, -0.32)
	var gun_material := StandardMaterial3D.new()
	gun_material.albedo_color = Color(0.09, 0.10, 0.11)
	weapon.material_override = gun_material
	add_child(weapon)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0.0, 1.55, 0.0)
	camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0.0)
	add_child(camera_pivot)

	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 5.2
	spring_arm.margin = 0.2
	camera_pivot.add_child(spring_arm)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 0.0)
	camera.current = true
	camera.fov = 75.0
	spring_arm.add_child(camera)

	shot_ray = RayCast3D.new()
	shot_ray.target_position = Vector3(0.0, 0.0, -100.0)
	shot_ray.collision_mask = 1
	shot_ray.enabled = true
	camera.add_child(shot_ray)

func shoot() -> void:
	if fire_cooldown > 0.0:
		return
	fire_cooldown = 0.22
	if not is_instance_valid(shot_ray):
		return
	shot_ray.force_raycast_update()
	if shot_ray.is_colliding():
		var marker := MeshInstance3D.new()
		var marker_mesh := SphereMesh.new()
		marker_mesh.radius = 0.07
		marker_mesh.height = 0.14
		marker.mesh = marker_mesh
		marker.global_position = shot_ray.get_collision_point()
		get_tree().current_scene.add_child(marker)
		var timer := get_tree().create_timer(0.35)
		timer.timeout.connect(marker.queue_free)
