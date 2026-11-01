extends CharacterBody3D
class_name Player3D

signal stats_changed

@export var move_speed: float = 5.5
@export var acceleration: float = 18.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.004
@export var max_health: float = 200.0
@export var magazine_size: int = 30
@export var reload_duration: float = 1.6

var health: float
var ammo: int
var reserve_ammo: int = 120
var weapon_name: String = "RIFLE"
var weapon_damage: float = 25.0
var weapon_fire_interval: float = 0.12
var weapon_index: int = 0
var weapon_magazines: Array[int] = [30, 12, 8, 45]
var weapon_reserves: Array[int] = [120, 48, 40, 180]
var weapon_names: Array[String] = ["RIFLE", "PISTOLA", "ESCOPETA", "SMG"]
var weapon_damages: Array[float] = [25.0, 18.0, 58.0, 13.0]
var weapon_intervals: Array[float] = [0.12, 0.28, 0.78, 0.075]
var armor_points: float = 75.0
var backpack_level: int = 2
var death_state: bool = false
var reload_pose_time: float = 0.0
var is_reloading: bool = false
var is_aiming: bool = false
var is_firing: bool = false
var reload_timer: float = 0.0
var camera_yaw: float = 0.0
var camera_pitch: float = -0.16
var fire_cooldown: float = 0.0
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var weapon: MeshInstance3D
var shot_ray: RayCast3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var walk_clock: float = 0.0
var recoil_amount: float = 0.0

func _ready() -> void:
	health = max_health
	ammo = magazine_size
	add_to_group("player")
	_build_collision()
	_build_character()
	_build_camera()
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	if death_state:
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis_yaw := Basis(Vector3.UP, camera_yaw)
	var direction := basis_yaw * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	direction = direction.normalized()
	var current_speed := move_speed * (1.45 if Input.is_action_pressed("sprint") else 1.0)
	var target_velocity := direction * current_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = 7.0
		else:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	if direction.length() > 0.08:
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)
		walk_clock += delta * 10.0
		if is_instance_valid(left_leg_pivot):
			left_leg_pivot.rotation.x = sin(walk_clock) * 0.42
			right_leg_pivot.rotation.x = -sin(walk_clock) * 0.42
	else:
		if is_instance_valid(left_leg_pivot):
			left_leg_pivot.rotation.x = move_toward(left_leg_pivot.rotation.x, 0.0, delta * 3.0)
			right_leg_pivot.rotation.x = move_toward(right_leg_pivot.rotation.x, 0.0, delta * 3.0)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	recoil_amount = move_toward(recoil_amount, 0.0, delta * 3.5)
	if is_instance_valid(right_arm_pivot):
		var pose := -0.75 if is_aiming else -0.48
		if is_reloading:
			pose = -0.12
		right_arm_pivot.rotation.x = lerpf(right_arm_pivot.rotation.x, pose - recoil_amount, delta * 9.0)
	if is_instance_valid(left_arm_pivot):
		var left_pose := -0.58 if is_aiming else -0.34
		if is_reloading:
			left_pose = -0.08
		left_arm_pivot.rotation.x = lerpf(left_arm_pivot.rotation.x, left_pose, delta * 8.0)
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	if is_instance_valid(camera):
		camera.fov = lerpf(camera.fov, 52.0 if is_aiming else 75.0, 10.0 * delta)
	if is_firing:
		shoot()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var viewport_size := get_viewport().get_visible_rect().size
		var over_right_hud := event.position.x > viewport_size.x * 0.75 and event.position.y > viewport_size.y * 0.55
		if event.position.x > viewport_size.x * 0.42 and not over_right_hud:
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
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.12, 0.20, 0.18)
	armor.roughness = 0.88
	var vest_material := StandardMaterial3D.new()
	vest_material.albedo_color = Color(0.30, 0.34, 0.25)
	vest_material.roughness = 0.95
	var fabric := StandardMaterial3D.new()
	fabric.albedo_color = Color(0.18, 0.25, 0.20)
	fabric.roughness = 1.0
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.72, 0.52, 0.38)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.07, 0.08, 0.075)
	metal.metallic = 0.35
	metal.roughness = 0.55

	_make_box(Vector3(0.68, 0.78, 0.36), Vector3(0.0, 1.28, 0.0), armor)
	_make_box(Vector3(0.72, 0.48, 0.18), Vector3(0.0, 1.34, -0.22), vest_material)
	for i in range(3):
		_make_box(Vector3(0.16, 0.17, 0.09), Vector3(-0.23 + float(i) * 0.23, 1.23, -0.34), armor)
	_make_box(Vector3(0.30, 0.48, 0.25), Vector3(0.0, 1.34, 0.29), fabric)
	_make_capsule(0.10, 0.18, Vector3(0.0, 1.78, 0.0), skin)
	_make_sphere(Vector3(0.0, 1.98, 0.0), Vector3(0.22, 0.25, 0.21), skin)
	var helmet_material := StandardMaterial3D.new()
	helmet_material.albedo_color = Color(0.20, 0.27, 0.19)
	helmet_material.roughness = 0.82
	_make_sphere(Vector3(0.0, 2.14, 0.0), Vector3(0.26, 0.17, 0.25), helmet_material)
	_make_box(Vector3(0.34, 0.045, 0.24), Vector3(0.0, 2.06, -0.04), metal)

	var left_arm := Node3D.new()
	left_arm.position = Vector3(-0.42, 1.58, 0.0)
	left_arm_pivot = left_arm
	add_child(left_arm)
	_make_capsule_on(left_arm, 0.13, 0.68, Vector3(0.0, -0.30, 0.0), fabric)
	_make_box_on(left_arm, Vector3(0.19, 0.14, 0.18), Vector3(0.0, -0.65, -0.02), armor)
	var right_arm := Node3D.new()
	right_arm.position = Vector3(0.42, 1.58, 0.0)
	right_arm_pivot = right_arm
	add_child(right_arm)
	_make_capsule_on(right_arm, 0.13, 0.68, Vector3(0.0, -0.30, -0.04), fabric)
	_make_box_on(right_arm, Vector3(0.19, 0.14, 0.18), Vector3(0.0, -0.65, -0.08), armor)

	left_leg_pivot = Node3D.new()
	left_leg_pivot.position = Vector3(-0.20, 0.91, 0.0)
	add_child(left_leg_pivot)
	_make_capsule_on(left_leg_pivot, 0.16, 0.78, Vector3(0.0, -0.35, 0.0), fabric)
	_make_box_on(left_leg_pivot, Vector3(0.30, 0.16, 0.43), Vector3(0.0, -0.72, -0.08), armor)
	right_leg_pivot = Node3D.new()
	right_leg_pivot.position = Vector3(0.20, 0.91, 0.0)
	add_child(right_leg_pivot)
	_make_capsule_on(right_leg_pivot, 0.16, 0.78, Vector3(0.0, -0.35, 0.0), fabric)
	_make_box_on(right_leg_pivot, Vector3(0.30, 0.16, 0.43), Vector3(0.0, -0.72, -0.08), armor)

	weapon = _make_box(Vector3(0.13, 0.13, 0.85), Vector3(0.39, 1.25, -0.43), metal)
	_make_box(Vector3(0.15, 0.22, 0.18), Vector3(0.39, 1.08, -0.28), armor)

func _make_box(size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	return _make_box_on(self, size, pos, material)

func _make_box_on(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _make_capsule(radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	return _make_capsule_on(self, radius, height, pos, material)

func _make_capsule_on(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _make_sphere(pos: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	instance.mesh = mesh
	instance.position = pos
	instance.scale = scale_value
	instance.material_override = material
	add_child(instance)
	return instance

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
	camera.current = true
	camera.position = Vector3(0.48, 0.12, 0.0)
	camera.fov = 75.0
	spring_arm.add_child(camera)
	shot_ray = RayCast3D.new()
	shot_ray.target_position = Vector3(0.0, 0.0, -100.0)
	shot_ray.collision_mask = 1
	shot_ray.enabled = true
	camera.add_child(shot_ray)
	shot_ray.add_exception(self)

func shoot() -> void:
	if fire_cooldown > 0.0 or is_reloading or ammo <= 0:
		if ammo <= 0 and not is_reloading:
			reload()
		return
	fire_cooldown = weapon_fire_interval
	recoil_amount = 0.22 if weapon_index == 2 else 0.12
	ammo -= 1
	weapon_magazines[weapon_index] = ammo
	if is_instance_valid(shot_ray):
		shot_ray.force_raycast_update()
		if shot_ray.is_colliding():
			var collider: Object = shot_ray.get_collider()
			if collider != null and collider.has_method("take_damage"):
				collider.call("take_damage", weapon_damage)
	stats_changed.emit()

func switch_weapon() -> void:
	weapon_magazines[weapon_index] = ammo
	weapon_reserves[weapon_index] = reserve_ammo
	weapon_index = (weapon_index + 1) % weapon_names.size()
	weapon_name = weapon_names[weapon_index]
	magazine_size = [30, 12, 8, 45][weapon_index]
	weapon_damage = weapon_damages[weapon_index]
	weapon_fire_interval = weapon_intervals[weapon_index]
	ammo = weapon_magazines[weapon_index]
	reserve_ammo = weapon_reserves[weapon_index]
	var weapon_size := [Vector3(0.13, 0.13, 0.85), Vector3(0.11, 0.12, 0.42), Vector3(0.18, 0.18, 0.72), Vector3(0.12, 0.13, 0.62)][weapon_index]
	if is_instance_valid(weapon):
		var mesh := BoxMesh.new()
		mesh.size = weapon_size
		weapon.mesh = mesh
	is_reloading = false
	reload_timer = 0.0
	fire_cooldown = 0.0
	stats_changed.emit()

func set_aiming(active: bool) -> void:
	is_aiming = active

func set_firing(active: bool) -> void:
	is_firing = active

func reload() -> void:
	if is_reloading or ammo >= magazine_size or reserve_ammo <= 0:
		return
	is_reloading = true
	reload_timer = reload_duration
	stats_changed.emit()

func _finish_reload() -> void:
	var needed := magazine_size - ammo
	var loaded := mini(needed, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	weapon_magazines[weapon_index] = ammo
	weapon_reserves[weapon_index] = reserve_ammo
	is_reloading = false
	reload_timer = 0.0
	stats_changed.emit()

func add_ammo(amount: int) -> void:
	reserve_ammo += amount
	weapon_reserves[weapon_index] = reserve_ammo
	stats_changed.emit()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	stats_changed.emit()

func take_damage(amount: float) -> void:
	if death_state:
		return
	var absorbed := minf(armor_points, amount * 0.65)
	armor_points -= absorbed
	health = maxf(0.0, health - (amount - absorbed))
	stats_changed.emit()
	if health <= 0.0:
		death_state = true
		is_firing = false
		is_aiming = false
		velocity = Vector3.ZERO
		set_physics_process(false)
		var tween := create_tween()
		tween.tween_property(self, "rotation:z", deg_to_rad(82.0), 0.7)
		tween.parallel().tween_property(self, "position:y", -0.35, 0.7)
