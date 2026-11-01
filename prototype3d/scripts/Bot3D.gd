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
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var right_arm_pivot: Node3D
var dead: bool = false
var walk_clock: float = 0.0
var character_model: Node3D
var model_animation_player: AnimationPlayer
var active_model_animation: StringName = &""

func _ready() -> void:
	health = max_health
	add_to_group("bots")
	_build_bot()

func _physics_process(delta: float) -> void:
	if dead:
		return
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
		_reset_legs(delta)
	elif distance > attack_range:
		_play_model_animation("run")
		var direction := offset.normalized()
		walk_clock += delta * 8.0
		if is_instance_valid(left_leg_pivot):
			left_leg_pivot.rotation.x = sin(walk_clock) * 0.35
			right_leg_pivot.rotation.x = -sin(walk_clock) * 0.35
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 7.0 * delta)
	else:
		_play_model_animation("idle")
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		_reset_legs(delta)
		if distance > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-offset.x, -offset.z), 8.0 * delta)
		if is_instance_valid(right_arm_pivot):
			right_arm_pivot.rotation.x = lerpf(right_arm_pivot.rotation.x, -0.62, delta * 7.0)
		if attack_cooldown <= 0.0:
			_fire_at_target()
			attack_cooldown = fire_rate
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _build_bot() -> void:
	var model_path := "res://assets/kenney/mini-characters/character-male-b.glb"
	if get_instance_id() % 2 == 0:
		model_path = "res://assets/kenney/mini-characters/character-male-c.glb"
	var character_scene := load(model_path) as PackedScene
	if character_scene != null:
		character_model = character_scene.instantiate() as Node3D
		if character_model != null:
			character_model.name = "BotCharacterModel"
			character_model.scale = Vector3.ONE * 1.25
			add_child(character_model)
			model_animation_player = _find_animation_player(character_model)
			return
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.25, 0.09, 0.08)
	armor.roughness = 0.9
	var vest := StandardMaterial3D.new()
	vest.albedo_color = Color(0.40, 0.16, 0.12)
	vest.roughness = 0.95
	var fabric := StandardMaterial3D.new()
	fabric.albedo_color = Color(0.18, 0.20, 0.19)
	fabric.roughness = 1.0
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.65, 0.47, 0.35)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.06, 0.07, 0.07)
	metal.metallic = 0.3

	_make_box(Vector3(0.68, 0.78, 0.36), Vector3(0.0, 1.28, 0.0), armor)
	_make_box(Vector3(0.72, 0.48, 0.18), Vector3(0.0, 1.34, -0.22), vest)
	for i in range(3):
		_make_box(Vector3(0.16, 0.17, 0.09), Vector3(-0.23 + float(i) * 0.23, 1.23, -0.34), armor)
	_make_box(Vector3(0.30, 0.48, 0.25), Vector3(0.0, 1.34, 0.29), fabric)
	_make_capsule(0.10, 0.18, Vector3(0.0, 1.78, 0.0), skin)
	_make_sphere(Vector3(0.0, 1.98, 0.0), Vector3(0.22, 0.25, 0.21), skin)
	var helmet := StandardMaterial3D.new()
	helmet.albedo_color = Color(0.28, 0.12, 0.10)
	_make_sphere(Vector3(0.0, 2.14, 0.0), Vector3(0.26, 0.17, 0.25), helmet)
	_make_box(Vector3(0.34, 0.045, 0.24), Vector3(0.0, 2.06, -0.04), metal)

	var left_arm := Node3D.new()
	left_arm.position = Vector3(-0.42, 1.58, 0.0)
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
	_make_box(Vector3(0.13, 0.13, 0.72), Vector3(0.39, 1.25, -0.40), metal)


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _play_model_animation(wanted: String) -> void:
	if not is_instance_valid(model_animation_player):
		return
	var selected: StringName = &""
	for animation_name in model_animation_player.get_animation_list():
		if String(animation_name).to_lower().contains(wanted):
			selected = StringName(animation_name)
			break
	if selected == &"" and wanted == "run":
		for animation_name in model_animation_player.get_animation_list():
			if String(animation_name).to_lower().contains("walk"):
				selected = StringName(animation_name)
				break
	if selected != &"" and selected != active_model_animation:
		active_model_animation = selected
		model_animation_player.play(selected)

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

func _reset_legs(delta: float) -> void:
	if is_instance_valid(left_leg_pivot):
		left_leg_pivot.rotation.x = move_toward(left_leg_pivot.rotation.x, 0.0, delta * 3.0)
		right_leg_pivot.rotation.x = move_toward(right_leg_pivot.rotation.x, 0.0, delta * 3.0)

func _fire_at_target() -> void:
	_play_model_animation("shoot")
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
	if dead:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		dead = true
		_play_model_animation("death")
		velocity = Vector3.ZERO
		set_physics_process(false)
		var tween := create_tween()
		tween.tween_property(self, "rotation:z", deg_to_rad(88.0), 0.55)
		tween.tween_callback(queue_free).set_delay(1.1)
