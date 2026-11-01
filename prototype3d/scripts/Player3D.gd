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
var weapon_magazines: Array[int] = [30, 12, 8, 45, 5]
var weapon_reserves: Array[int] = [120, 48, 40, 180, 20]
var weapon_names: Array[String] = ["RIFLE", "PISTOLA", "ESCOPETA", "SMG", "SNIPER"]
var weapon_damages: Array[float] = [25.0, 18.0, 58.0, 13.0, 95.0]
var weapon_intervals: Array[float] = [0.12, 0.28, 0.78, 0.075, 1.1]
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
var weapon: Node3D
var weapon_attachment: BoneAttachment3D
var weapon_base_position: Vector3 = Vector3.ZERO
var weapon_base_rotation: Vector3 = Vector3.ZERO
var shot_ray: RayCast3D
var shot_audio: AudioStreamPlayer3D
var gunshot_audio_streams: Array[AudioStream] = []
var sniper_audio_stream: AudioStream
var footstep_audio: AudioStreamPlayer3D
var footstep_timer: float = 0.0
var muzzle_light: OmniLight3D
var muzzle_timer: float = 0.0
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var walk_clock: float = 0.0
var recoil_amount: float = 0.0
var character_model: Node3D
var model_animation_player: AnimationPlayer
var active_model_animation: StringName = &""
var mobile_move_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	health = max_health
	ammo = magazine_size
	add_to_group("player")
	_build_collision()
	_build_character()
	_build_camera()
	_build_audio_and_effects()
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	if death_state:
		return
	var keyboard_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_vector := mobile_move_vector if mobile_move_vector.length() > 0.01 else keyboard_vector
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
			_animate_weapon_jump()
		else:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	# Battle-royale third-person control: the soldier faces the camera/aim
	# direction, while movement remains camera-relative (forward, strafe, reverse).
	# This prevents the body from spinning 180 degrees when the joystick is pushed
	# forward after the camera has been rotated.
	rotation.y = lerp_angle(rotation.y, camera_yaw, 16.0 * delta)
	if is_instance_valid(camera_pivot):
		camera_pivot.rotation.y = wrapf(camera_yaw - rotation.y, -PI, PI)
	if direction.length() > 0.08:
		_play_model_animation("run" if Input.is_action_pressed("sprint") else "walk")
		footstep_timer -= delta
		if footstep_timer <= 0.0 and is_on_floor() and is_instance_valid(footstep_audio):
			footstep_audio.pitch_scale = randf_range(0.92, 1.08)
			footstep_audio.play()
			footstep_timer = 0.38 if Input.is_action_pressed("sprint") else 0.52
		walk_clock += delta * 10.0
		if is_instance_valid(left_leg_pivot):
			left_leg_pivot.rotation.x = sin(walk_clock) * 0.42
			right_leg_pivot.rotation.x = -sin(walk_clock) * 0.42
	else:
		_play_model_animation("idle")
		footstep_timer = 0.0
		if is_instance_valid(left_leg_pivot):
			left_leg_pivot.rotation.x = move_toward(left_leg_pivot.rotation.x, 0.0, delta * 3.0)
			right_leg_pivot.rotation.x = move_toward(right_leg_pivot.rotation.x, 0.0, delta * 3.0)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	recoil_amount = move_toward(recoil_amount, 0.0, delta * 3.5)
	muzzle_timer = maxf(0.0, muzzle_timer - delta)
	if is_instance_valid(muzzle_light):
		muzzle_light.visible = muzzle_timer > 0.0
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var viewport_size := get_viewport().get_visible_rect().size
		var over_right_hud: bool = event.position.x > viewport_size.x * 0.75 and event.position.y > viewport_size.y * 0.55
		if event.position.x > viewport_size.x * 0.42 and not over_right_hud:
			_rotate_camera(event.relative * touch_sensitivity)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rotate_camera(event.relative * mouse_sensitivity)

func _rotate_camera(delta: Vector2) -> void:
	camera_yaw -= delta.x
	camera_pitch = clampf(camera_pitch - delta.y, -0.72, 0.22)
	if is_instance_valid(camera_pivot):
		camera_pivot.rotation = Vector3(camera_pitch, wrapf(camera_yaw - rotation.y, -PI, PI), 0.0)

func set_mobile_move_vector(value: Vector2) -> void:
	mobile_move_vector = value.limit_length(1.0)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

func _build_character() -> void:
	var character_scene := load("res://assets/codelove/military-male-03.glb") as PackedScene
	if character_scene != null:
		character_model = character_scene.instantiate() as Node3D
		if character_model != null:
			character_model.name = "RootNode"
			character_model.scale = Vector3.ONE
			# Imported soldier rig faces +Z; the Godot character forward axis is -Z.
			character_model.rotation.y = PI
			add_child(character_model)
			model_animation_player = AnimationPlayer.new()
			model_animation_player.name = "SoldierAnimationPlayer"
			model_animation_player.root_node = NodePath("..")
			add_child(model_animation_player)
			_load_external_animation_clips()
			_play_model_animation("idle")
			_create_weapon_visual(weapon_index)
			return
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




func _load_external_animation_clips() -> void:
	var skeletons := character_model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("Tactical soldier model has no Skeleton3D for animation retargeting")
		return
	var target_skeleton := skeletons[0] as Skeleton3D
	var skeleton_relative_path := character_model.get_path_to(target_skeleton)
	var library := AnimationLibrary.new()
	var clip_files := {
		"idle": "m_idle_neutral_01.glb",
		"walk": "m_walk_neutral_01.glb",
		"run": "m_run_neutral_01.glb"
	}
	for state_name in clip_files:
		var clip_path := "res://assets/codelove/animations/" + String(clip_files[state_name])
		var clip_scene := load(clip_path) as PackedScene
		if clip_scene == null:
			push_warning("Animation clip missing: " + clip_path)
			continue
		var clip_root := clip_scene.instantiate()
		add_child(clip_root)
		var source_player := _find_animation_player(clip_root)
		if source_player != null:
			var names := source_player.get_animation_list()
			if not names.is_empty():
				var copied_animation := source_player.get_animation(names[0]).duplicate(true) as Animation
				var retargeted_tracks := 0
				var invalid_tracks: Array[int] = []
				for track_index in range(copied_animation.get_track_count()):
					var source_path := String(copied_animation.track_get_path(track_index))
					var bone_name := source_path.get_slice("/", source_path.get_slice_count("/") - 1)
					if target_skeleton.find_bone(bone_name) >= 0:
						var target_path := "RootNode/" + String(skeleton_relative_path) + ":" + bone_name
						copied_animation.track_set_path(track_index, NodePath(target_path))
						retargeted_tracks += 1
					else:
						invalid_tracks.append(track_index)
				for invalid_index in range(invalid_tracks.size() - 1, -1, -1):
					copied_animation.remove_track(invalid_tracks[invalid_index])
				if retargeted_tracks > 0:
					library.add_animation(StringName(state_name), copied_animation)
					print("Retargeted ", retargeted_tracks, " tracks for ", state_name)
				else:
					push_warning("No matching Biped bones found in clip: " + clip_path)
		else:
			push_warning("No AnimationPlayer in clip: " + clip_path)
		clip_root.queue_free()
	if library.get_animation_list().size() > 0:
		model_animation_player.add_animation_library("", library)

func _create_weapon_visual(index: int) -> void:
	if is_instance_valid(weapon_attachment):
		weapon_attachment.queue_free()
	elif is_instance_valid(weapon):
		weapon.queue_free()
	var weapon_files: Array[String] = [
		"rifle_assault.glb",
		"pistol_full.glb",
		"shotgun_pump.glb",
		"smg_full.glb",
		"sniper_rifle.glb"
	]
	var weapon_path: String = "res://assets/fps/weapons/" + weapon_files[index % weapon_files.size()]
	var packed := load(weapon_path) as PackedScene
	if packed != null:
		weapon = packed.instantiate() as Node3D
		if weapon != null:
			weapon.name = "EquippedFirearm"
			weapon.scale = Vector3.ONE
			var skeletons := character_model.find_children("*", "Skeleton3D", true, false)
			if not skeletons.is_empty():
				var soldier_skeleton := skeletons[0] as Skeleton3D
				if soldier_skeleton.find_bone("Bip01 R Hand") >= 0:
					weapon_attachment = BoneAttachment3D.new()
					weapon_attachment.name = "WeaponAttachment"
					weapon_attachment.bone_name = "Bip01 R Hand"
					soldier_skeleton.add_child(weapon_attachment)
					weapon.position = Vector3(0.0, 0.0, -0.08)
					weapon.rotation = Vector3(0.0, PI, 0.0)
					weapon_attachment.add_child(weapon)
				else:
					weapon.position = Vector3(0.38, 1.10, -0.48)
					weapon.rotation = Vector3(0.0, PI, 0.0)
					add_child(weapon)
			else:
				weapon.position = Vector3(0.38, 1.10, -0.48)
				weapon.rotation = Vector3(0.0, PI, 0.0)
				add_child(weapon)
			weapon_base_position = weapon.position
			weapon_base_rotation = weapon.rotation
			_animate_weapon_aim(is_aiming)
			return
	push_warning("Firearm model unavailable, using temporary mesh: " + weapon_path)
	weapon = _make_box(Vector3(0.13, 0.13, 0.85), Vector3(0.38, 1.10, -0.48), _weapon_material())
	weapon_base_position = weapon.position
	weapon_base_rotation = weapon.rotation


func _animate_weapon_recoil() -> void:
	if not is_instance_valid(weapon):
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(weapon, "position", weapon_base_position + Vector3(0.0, 0.0, 0.12), 0.045)
	tween.tween_property(weapon, "position", weapon_base_position, 0.10)

func _animate_weapon_aim(active: bool) -> void:
	if not is_instance_valid(weapon):
		return
	var target_rotation := weapon_base_rotation + (Vector3(-0.08, 0.0, 0.0) if active else Vector3.ZERO)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(weapon, "rotation", target_rotation, 0.16)

func _animate_weapon_reload() -> void:
	if not is_instance_valid(weapon):
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(weapon, "rotation", weapon_base_rotation + Vector3(0.48, 0.0, 0.10), 0.24)
	tween.parallel().tween_property(weapon, "position", weapon_base_position + Vector3(0.0, -0.10, 0.04), 0.24)
	tween.tween_interval(0.34)
	tween.tween_property(weapon, "rotation", weapon_base_rotation, 0.24)
	tween.parallel().tween_property(weapon, "position", weapon_base_position, 0.24)

func _animate_weapon_jump() -> void:
	if not is_instance_valid(weapon):
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(weapon, "position", weapon_base_position + Vector3(0.0, 0.10, -0.04), 0.12)
	tween.tween_property(weapon, "position", weapon_base_position, 0.24)

func _weapon_material() -> Material:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.055, 0.065, 0.06)
	material.metallic = 0.55
	material.roughness = 0.42
	return material

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
		var lower := String(animation_name).to_lower()
		if lower.contains(wanted):
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

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0.0, 1.55, 0.0)
	camera_pivot.rotation = Vector3(camera_pitch, wrapf(camera_yaw - rotation.y, -PI, PI), 0.0)
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


func _build_audio_and_effects() -> void:
	shot_audio = AudioStreamPlayer3D.new()
	shot_audio.name = "GunshotAudio"
	shot_audio.volume_db = -7.0
	shot_audio.max_distance = 65.0
	for sound_file in ["impact-gunshot-16.mp3", "impact-gunshot-08.mp3", "impact-gunshot-09.mp3", "impact-gunshot-10.mp3"]:
		var sound_stream := load("res://assets/fps/audio/" + sound_file) as AudioStream
		if sound_stream != null:
			gunshot_audio_streams.append(sound_stream)
	sniper_audio_stream = load("res://assets/fps/audio/impact-gunshot-08.mp3") as AudioStream
	if not gunshot_audio_streams.is_empty():
		shot_audio.stream = gunshot_audio_streams[0]
	add_child(shot_audio)

	footstep_audio = AudioStreamPlayer3D.new()
	footstep_audio.name = "FootstepAudio"
	footstep_audio.stream = load("res://assets/fps/audio/footstep_stone.ogg") as AudioStream
	footstep_audio.volume_db = -15.0
	footstep_audio.max_distance = 24.0
	add_child(footstep_audio)

	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "MuzzleFlash"
	muzzle_light.light_color = Color(1.0, 0.72, 0.32)
	muzzle_light.light_energy = 2.2
	muzzle_light.omni_range = 3.5
	muzzle_light.position = Vector3(0.39, 1.25, -0.95)
	muzzle_light.visible = false
	add_child(muzzle_light)

func shoot() -> void:
	if fire_cooldown > 0.0 or is_reloading or ammo <= 0:
		if ammo <= 0 and not is_reloading:
			reload()
		return
	fire_cooldown = weapon_fire_interval
	_play_model_animation("shoot")
	_animate_weapon_recoil()
	recoil_amount = 0.22 if weapon_index == 2 else 0.12
	muzzle_timer = 0.055
	if is_instance_valid(muzzle_light):
		muzzle_light.visible = true
	if is_instance_valid(shot_audio):
		if weapon_index == 4 and sniper_audio_stream != null:
			shot_audio.stream = sniper_audio_stream
		elif not gunshot_audio_streams.is_empty():
			shot_audio.stream = gunshot_audio_streams[randi_range(0, gunshot_audio_streams.size() - 1)]
		shot_audio.pitch_scale = [0.96, 1.12, 0.82, 1.28, 0.92][weapon_index]
		shot_audio.play()
	ammo -= 1
	weapon_magazines[weapon_index] = ammo
	if is_instance_valid(shot_ray):
		shot_ray.force_raycast_update()
		var shot_end := camera.global_position - camera.global_basis.z * 70.0
		if shot_ray.is_colliding():
			shot_end = shot_ray.get_collision_point()
			var collider: Object = shot_ray.get_collider()
			if collider != null and collider.has_method("take_damage"):
				collider.call("take_damage", weapon_damage)
			_spawn_impact_spark(shot_end)
		var shot_start := weapon.global_position if is_instance_valid(weapon) else camera.global_position
		shot_start += (shot_end - shot_start).normalized() * 0.38
		if is_instance_valid(muzzle_light):
			muzzle_light.global_position = shot_start
		_spawn_bullet_tracer(shot_start, shot_end)
	stats_changed.emit()

func _spawn_bullet_tracer(start_point: Vector3, end_point: Vector3) -> void:
	var distance := start_point.distance_to(end_point)
	if distance < 0.1:
		return
	var tracer := MeshInstance3D.new()
	tracer.name = "BulletTracer"
	var beam := BoxMesh.new()
	beam.size = Vector3(0.018, 0.018, distance)
	tracer.mesh = beam
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.72, 0.28, 0.96)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.42, 0.08)
	glow.emission_energy_multiplier = 2.4
	tracer.material_override = glow
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(tracer)
	tracer.global_position = (start_point + end_point) * 0.5
	tracer.look_at(end_point, Vector3.UP)
	var fade := create_tween()
	fade.tween_interval(0.065)
	fade.tween_callback(tracer.queue_free)

func _spawn_impact_spark(point: Vector3) -> void:
	var spark := MeshInstance3D.new()
	spark.name = "BulletImpactSpark"
	var mesh := SphereMesh.new()
	mesh.radius = 0.055
	mesh.height = 0.11
	spark.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.68, 0.24, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.32, 0.04)
	material.emission_energy_multiplier = 2.0
	spark.material_override = material
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(spark)
	spark.global_position = point
	var fade := create_tween()
	fade.tween_interval(0.12)
	fade.tween_callback(spark.queue_free)

func switch_weapon() -> void:
	weapon_magazines[weapon_index] = ammo
	weapon_reserves[weapon_index] = reserve_ammo
	weapon_index = (weapon_index + 1) % weapon_names.size()
	weapon_name = weapon_names[weapon_index]
	magazine_size = [30, 12, 8, 45, 5][weapon_index]
	weapon_damage = weapon_damages[weapon_index]
	weapon_fire_interval = weapon_intervals[weapon_index]
	ammo = weapon_magazines[weapon_index]
	reserve_ammo = weapon_reserves[weapon_index]
	_create_weapon_visual(weapon_index)
	is_reloading = false
	reload_timer = 0.0
	fire_cooldown = 0.0
	stats_changed.emit()

func set_aiming(active: bool) -> void:
	is_aiming = active
	_animate_weapon_aim(active)

func set_firing(active: bool) -> void:
	is_firing = active

func reload() -> void:
	if is_reloading or ammo >= magazine_size or reserve_ammo <= 0:
		return
	is_reloading = true
	_play_model_animation("reload")
	_animate_weapon_reload()
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

func repair_armor(amount: float) -> void:
	armor_points = minf(100.0, armor_points + amount)
	stats_changed.emit()

func upgrade_backpack() -> void:
	backpack_level = mini(3, backpack_level + 1)
	for i in range(weapon_reserves.size()):
		weapon_reserves[i] += 30
	reserve_ammo = weapon_reserves[weapon_index]
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
		_play_model_animation("death")
		is_firing = false
		is_aiming = false
		velocity = Vector3.ZERO
		set_physics_process(false)
		var tween := create_tween()
		tween.tween_property(self, "rotation:z", deg_to_rad(82.0), 0.7)
		tween.parallel().tween_property(self, "position:y", -0.35, 0.7)
