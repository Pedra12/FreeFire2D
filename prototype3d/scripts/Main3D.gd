extends Node3D

const MAP_SIZE: float = 100.0
const PLAYER_SCRIPT = preload("res://scripts/Player3D.gd")
const BOT_SCRIPT = preload("res://scripts/Bot3D.gd")
const LOOT_SCRIPT = preload("res://scripts/LootPickup3D.gd")

var player
var hud_layer: CanvasLayer
var health_label: Label
var health_bar: ProgressBar
var ammo_label: Label
var enemies_label: Label
var status_label: Label
var zone_label: Label
var zone_ring: MeshInstance3D
var safe_zone_radius: float = 48.0
var zone_elapsed: float = 0.0
var zone_damage_elapsed: float = 0.0

func _ready() -> void:
	_setup_environment()
	_create_ground()
	_create_zone_ring()
	_create_map_features()
	_create_player()
	_create_bots()
	_create_loot()
	_create_hud()
	_check_mesh_instances()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	health_label.text = "VIDA  %d / %d   COLETE  %d" % [roundi(player.health), roundi(player.max_health), roundi(player.armor_points)]
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	ammo_label.text = "%s  |  MUNIÇÃO  %d / %d" % [player.weapon_name, player.ammo, player.reserve_ammo]
	enemies_label.text = "INIMIGOS  %d" % get_tree().get_nodes_in_group("bots").size()
	zone_elapsed += delta
	if zone_elapsed >= 10.0 and safe_zone_radius > 12.0:
		zone_elapsed = 0.0
		safe_zone_radius = maxf(12.0, safe_zone_radius - 1.0)
		_update_zone_ring()
	zone_label.text = "ZONA SEGURA  %.0f m" % safe_zone_radius
	zone_damage_elapsed += delta
	if zone_damage_elapsed >= 1.0:
		zone_damage_elapsed = 0.0
		if Vector2(player.global_position.x, player.global_position.z).length() > safe_zone_radius:
			player.take_damage(6.0)
		for enemy in get_tree().get_nodes_in_group("bots"):
			if Vector2(enemy.global_position.x, enemy.global_position.z).length() > safe_zone_radius:
				enemy.call("take_damage", 6.0)
	if player.health <= 0.0:
		status_label.text = "ELIMINADO  |  FIM DE PARTIDA"
	elif get_tree().get_nodes_in_group("bots").is_empty():
		status_label.text = "VITÓRIA  |  TODOS OS INIMIGOS ELIMINADOS"


func _check_mesh_instances() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			push_error("MeshInstance3D sem malha: " + str(mesh_node.get_path()))

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.38, 0.58, 0.72)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.78, 0.82)
	environment.ambient_light_energy = 0.75
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _create_zone_ring() -> void:
	zone_ring = MeshInstance3D.new()
	zone_ring.name = "SafeZoneBoundary"
	add_child(zone_ring)
	_update_zone_ring()

func _update_zone_ring() -> void:
	if not is_instance_valid(zone_ring):
		return
	var ring := TorusMesh.new()
	ring.inner_radius = maxf(0.1, safe_zone_radius - 0.08)
	ring.outer_radius = safe_zone_radius
	ring.rings = 64
	ring.ring_segments = 8
	zone_ring.mesh = ring
	zone_ring.position.y = 0.08
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.12, 0.62, 1.0, 0.9)
	material.no_depth_test = true
	zone_ring.material_override = material

func _create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var mesh_instance := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(MAP_SIZE, MAP_SIZE)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.39, 0.22)
	material.roughness = 1.0
	mesh_instance.material_override = material
	ground.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(MAP_SIZE, 0.3, MAP_SIZE)
	collision.shape = shape
	collision.position.y = -0.15
	ground.add_child(collision)
	add_child(ground)

func _create_map_features() -> void:
	_create_building(Vector3(12, 0, -12), Vector3(10, 5, 9), Color(0.62, 0.52, 0.38))
	_create_building(Vector3(-15, 0, -8), Vector3(8, 4, 8), Color(0.68, 0.62, 0.48))
	_create_building(Vector3(16, 0, 15), Vector3(12, 6, 10), Color(0.52, 0.55, 0.58))
	_create_building(Vector3(-18, 0, 17), Vector3(9, 4.5, 11), Color(0.60, 0.43, 0.34))
	_create_building(Vector3(31, 0, -13), Vector3(7, 4, 8), Color(0.58, 0.48, 0.37))
	_create_building(Vector3(-32, 0, -29), Vector3(8, 4.5, 9), Color(0.48, 0.53, 0.50))
	_create_building(Vector3(31, 0, 30), Vector3(8, 3.8, 8), Color(0.62, 0.56, 0.43))
	_create_building(Vector3(-32, 0, 31), Vector3(7, 4, 8), Color(0.52, 0.47, 0.40))
	for i in range(28):
		var x := sin(float(i) * 2.4) * 36.0
		var z := cos(float(i) * 1.7) * 36.0
		if Vector2(x, z).length() > 14.0:
			_create_tree(Vector3(x, 0.0, z))
	_create_road(Vector3(0.0, 0.015, 0.0), Vector3(5.0, 0.03, 76.0))
	_create_road(Vector3(0.0, 0.02, 0.0), Vector3(76.0, 0.035, 5.0))
	_create_vehicle(Vector3(8.0, 0.0, 3.7), 0.25)
	_create_vehicle(Vector3(-8.0, 0.0, -3.7), PI)

func _create_building(pos: Vector3, size: Vector3, color: Color) -> void:
	var building := StaticBody3D.new()
	building.position = pos + Vector3(0.0, size.y * 0.5, 0.0)
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = color
	wall_material.roughness = 0.92
	var inside_material := StandardMaterial3D.new()
	inside_material.albedo_color = color.darkened(0.22)
	inside_material.roughness = 1.0
	var wall_height := maxf(2.8, size.y - 0.3)
	var wall_y := -size.y * 0.5 + wall_height * 0.5
	_building_piece(building, Vector3(size.x, 0.3, size.z), Vector3(0.0, -size.y * 0.5 - 0.08, 0.0), inside_material)
	_building_piece(building, Vector3(size.x, wall_height, 0.24), Vector3(0.0, wall_y, size.z * 0.5 - 0.12), wall_material)
	_building_piece(building, Vector3(0.24, wall_height, size.z), Vector3(-size.x * 0.5 + 0.12, wall_y, 0.0), wall_material)
	_building_piece(building, Vector3(0.24, wall_height, size.z), Vector3(size.x * 0.5 - 0.12, wall_y, 0.0), wall_material)
	var door_width := 1.8
	var side_width := (size.x - door_width) * 0.5
	_building_piece(building, Vector3(side_width, wall_height, 0.24), Vector3(-size.x * 0.5 + side_width * 0.5, wall_y, -size.z * 0.5 + 0.12), wall_material)
	_building_piece(building, Vector3(side_width, wall_height, 0.24), Vector3(size.x * 0.5 - side_width * 0.5, wall_y, -size.z * 0.5 + 0.12), wall_material)
	_building_piece(building, Vector3(door_width, 0.55, 0.24), Vector3(0.0, -size.y * 0.5 + 2.475, -size.z * 0.5 + 0.12), wall_material)

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.10, 0.22, 0.29)
	glass.metallic = 0.3
	glass.roughness = 0.28
	for side in [-1, 1]:
		var window := MeshInstance3D.new()
		var window_mesh := BoxMesh.new()
		window_mesh.size = Vector3(1.0, 0.85, 0.06)
		window.mesh = window_mesh
		window.position = Vector3(float(side) * size.x * 0.27, 0.25, -size.z * 0.5 - 0.015)
		window.material_override = glass
		building.add_child(window)

	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = color.darkened(0.2)
	_building_piece(building, Vector3(size.x + 0.25, 0.18, 0.28), Vector3(0.0, size.y * 0.5 - 0.08, size.z * 0.5), roof_material)
	_building_piece(building, Vector3(size.x + 0.25, 0.18, 0.28), Vector3(0.0, size.y * 0.5 - 0.08, -size.z * 0.5), roof_material)
	_building_piece(building, Vector3(0.28, 0.18, size.z), Vector3(size.x * 0.5, size.y * 0.5 - 0.08, 0.0), roof_material)
	_building_piece(building, Vector3(0.28, 0.18, size.z), Vector3(-size.x * 0.5, size.y * 0.5 - 0.08, 0.0), roof_material)

	var crate := MeshInstance3D.new()
	var crate_mesh := BoxMesh.new()
	crate_mesh.size = Vector3(0.9, 0.8, 0.9)
	crate.mesh = crate_mesh
	crate.position = Vector3(size.x * 0.22, -size.y * 0.5 + 0.55, size.z * 0.12)
	var crate_material := StandardMaterial3D.new()
	crate_material.albedo_color = Color(0.32, 0.24, 0.14)
	crate.material_override = crate_material
	building.add_child(crate)
	add_child(building)

func _building_piece(parent: StaticBody3D, piece_size: Vector3, piece_position: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = piece_size
	visual.mesh = mesh
	visual.position = piece_position
	visual.material_override = material
	parent.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = piece_size
	collision.shape = shape
	collision.position = piece_position
	parent.add_child(collision)

func _create_tree(pos: Vector3) -> void:
	var tree := StaticBody3D.new()
	tree.position = pos
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.32
	trunk_mesh.height = 2.0
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.0
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.30, 0.20, 0.12)
	trunk.material_override = bark
	tree.add_child(trunk)
	var leaves := MeshInstance3D.new()
	var leaves_mesh := SphereMesh.new()
	leaves_mesh.radius = 1.25
	leaves_mesh.height = 2.5
	leaves.mesh = leaves_mesh
	leaves.position.y = 2.65
	var foliage := StandardMaterial3D.new()
	foliage.albedo_color = Color(0.12, 0.31, 0.13)
	leaves.material_override = foliage
	tree.add_child(leaves)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.38
	shape.height = 2.0
	collision.shape = shape
	collision.position.y = 1.0
	tree.add_child(collision)
	add_child(tree)

func _create_road(pos: Vector3, size: Vector3) -> void:
	var road := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	road.mesh = mesh
	road.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.21, 0.19)
	material.roughness = 1.0
	road.material_override = material
	add_child(road)
	var stripe_material := StandardMaterial3D.new()
	stripe_material.albedo_color = Color(0.82, 0.78, 0.58)
	stripe_material.roughness = 1.0
	if size.z > size.x:
		for i in range(12):
			var stripe := MeshInstance3D.new()
			var stripe_mesh := BoxMesh.new()
			stripe_mesh.size = Vector3(0.12, 0.035, 2.0)
			stripe.mesh = stripe_mesh
			stripe.position = pos + Vector3(0.0, 0.035, -size.z * 0.5 + 3.0 + float(i) * 6.0)
			stripe.material_override = stripe_material
			add_child(stripe)
	else:
		for i in range(12):
			var stripe := MeshInstance3D.new()
			var stripe_mesh := BoxMesh.new()
			stripe_mesh.size = Vector3(2.0, 0.035, 0.12)
			stripe.mesh = stripe_mesh
			stripe.position = pos + Vector3(-size.x * 0.5 + 3.0 + float(i) * 6.0, 0.035, 0.0)
			stripe.material_override = stripe_material
			add_child(stripe)


func _create_vehicle(pos: Vector3, heading: float) -> void:
	var vehicle := StaticBody3D.new()
	vehicle.name = "ParkedVehicle"
	vehicle.position = pos
	vehicle.rotation.y = heading
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.16, 0.24, 0.27)
	paint.metallic = 0.45
	paint.roughness = 0.38
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.08, 0.16, 0.19, 0.82)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.025, 0.03, 0.03)
	var chassis := MeshInstance3D.new()
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(2.1, 0.72, 3.6)
	chassis.mesh = chassis_mesh
	chassis.position.y = 0.72
	chassis.material_override = paint
	vehicle.add_child(chassis)
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.72, 0.82, 1.85)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.0, 1.42, 0.05)
	cabin.material_override = glass
	vehicle.add_child(cabin)
	for x in [-0.92, 0.92]:
		for z in [-1.18, 1.18]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.42
			wheel_mesh.bottom_radius = 0.42
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(x, 0.42, z)
			wheel.material_override = rubber
			vehicle.add_child(wheel)
	var bumper := MeshInstance3D.new()
	var bumper_mesh := BoxMesh.new()
	bumper_mesh.size = Vector3(2.18, 0.18, 0.22)
	bumper.mesh = bumper_mesh
	bumper.position = Vector3(0.0, 0.48, -1.82)
	bumper.material_override = rubber
	vehicle.add_child(bumper)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.15, 1.55, 3.65)
	collision.shape = shape
	collision.position.y = 0.82
	vehicle.add_child(collision)
	add_child(vehicle)

func _create_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 8.0)
	add_child(player)

func _create_bots() -> void:
	var spawn_points: Array[Vector3] = [
		Vector3(-27.0, 0.0, -22.0),
		Vector3(-28.0, 0.0, 7.0),
		Vector3(27.0, 0.0, -27.0),
		Vector3(29.0, 0.0, 25.0),
		Vector3(0.0, 0.0, -34.0),
		Vector3(35.0, 0.0, 0.0)
	]
	for i in range(spawn_points.size()):
		var bot = BOT_SCRIPT.new()
		bot.name = "Bot_%02d" % (i + 1)
		bot.position = spawn_points[i]
		bot.target = player
		add_child(bot)

func _create_loot() -> void:
	_spawn_loot("ammo", 45, Vector3(7.0, 0.0, 4.0))
	_spawn_loot("ammo", 45, Vector3(-8.0, 0.0, -3.0))
	_spawn_loot("ammo", 60, Vector3(22.0, 0.0, 4.0))
	_spawn_loot("medkit", 50, Vector3(-23.0, 0.0, 1.0))
	_spawn_loot("medkit", 50, Vector3(3.0, 0.0, -25.0))
	_spawn_loot("armor", 45, Vector3(12.0, 0.0, -12.0))
	_spawn_loot("backpack", 1, Vector3(-15.0, 0.0, -8.0))
	_spawn_loot("ammo", 60, Vector3(16.0, 0.0, 15.0))
	_spawn_loot("medkit", 35, Vector3(-18.0, 0.0, 17.0))

func _spawn_loot(kind: String, amount: int, spawn_position: Vector3) -> void:
	var pickup = LOOT_SCRIPT.new()
	pickup.loot_type = kind
	pickup.amount = amount
	pickup.position = spawn_position
	add_child(pickup)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_layer.add_child(root)
	var screen := get_viewport().get_visible_rect().size

	var title := Label.new()
	title.text = "SOBREVIVÊNCIA  |  BATTLE ROYALE 3D"
	title.position = Vector2(24.0, 16.0)
	title.size = Vector2(600.0, 34.0)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	health_label = Label.new()
	health_label.position = Vector2(24.0, 55.0)
	health_label.size = Vector2(250.0, 30.0)
	health_label.add_theme_font_size_override("font_size", 19)
	root.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(24.0, 84.0)
	health_bar.size = Vector2(250.0, 14.0)
	health_bar.min_value = 0.0
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_bar.show_percentage = false
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color(0.04, 0.05, 0.05, 0.88)
	health_background.set_corner_radius_all(5)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(0.16, 0.72, 0.32, 0.98)
	health_fill.set_corner_radius_all(5)
	health_bar.add_theme_stylebox_override("background", health_background)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	root.add_child(health_bar)

	ammo_label = Label.new()
	ammo_label.position = Vector2(24.0, 106.0)
	ammo_label.size = Vector2(300.0, 30.0)
	ammo_label.add_theme_font_size_override("font_size", 19)
	root.add_child(ammo_label)

	enemies_label = Label.new()
	enemies_label.position = Vector2(screen.x - 230.0, 20.0)
	enemies_label.size = Vector2(210.0, 34.0)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemies_label.add_theme_font_size_override("font_size", 19)
	root.add_child(enemies_label)

	zone_label = Label.new()
	zone_label.position = Vector2(screen.x - 230.0, 54.0)
	zone_label.size = Vector2(210.0, 30.0)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	zone_label.add_theme_font_size_override("font_size", 17)
	root.add_child(zone_label)

	status_label = Label.new()
	status_label.text = "ELIMINE OS BOTS E COLETE SUPRIMENTOS"
	status_label.position = Vector2(24.0, 124.0)
	status_label.size = Vector2(550.0, 28.0)
	status_label.add_theme_font_size_override("font_size", 15)
	root.add_child(status_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = screen * 0.5 - Vector2(10.0, 20.0)
	crosshair.size = Vector2(24.0, 40.0)
	crosshair.add_theme_font_size_override("font_size", 30)
	root.add_child(crosshair)

	_add_hold_button(root, "▲", Vector2(105.0, screen.y - 218.0), "move_forward")
	_add_hold_button(root, "▼", Vector2(105.0, screen.y - 90.0), "move_back")
	_add_hold_button(root, "◀", Vector2(38.0, screen.y - 154.0), "move_left")
	_add_hold_button(root, "▶", Vector2(172.0, screen.y - 154.0), "move_right")


	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
	var jump_button := Button.new()
	jump_button.text = "PULAR"
	jump_button.position = Vector2(screen.x - 300.0, screen.y - 145.0)
	jump_button.custom_minimum_size = Vector2(100.0, 86.0)
	jump_button.size = Vector2(100.0, 86.0)
	jump_button.add_theme_font_size_override("font_size", 17)
	jump_button.button_down.connect(func() -> void: Input.action_press("jump"))
	jump_button.button_up.connect(func() -> void: Input.action_release("jump"))
	_style_button(jump_button)
	root.add_child(jump_button)

	var fire := Button.new()
	fire.text = "ATIRAR"
	fire.position = Vector2(screen.x - 180.0, screen.y - 150.0)
	fire.custom_minimum_size = Vector2(145.0, 115.0)
	fire.size = Vector2(145.0, 115.0)
	fire.add_theme_font_size_override("font_size", 22)
	fire.button_down.connect(player.set_firing.bind(true))
	fire.button_up.connect(player.set_firing.bind(false))
	_style_button(fire)
	root.add_child(fire)

	var weapon_button := Button.new()
	weapon_button.text = "TROCAR ARMA"
	weapon_button.position = Vector2(screen.x - 180.0, screen.y - 365.0)
	weapon_button.custom_minimum_size = Vector2(145.0, 56.0)
	weapon_button.size = Vector2(145.0, 56.0)
	weapon_button.add_theme_font_size_override("font_size", 15)
	weapon_button.pressed.connect(player.switch_weapon)
	_style_button(weapon_button)
	root.add_child(weapon_button)

	var aim_button := Button.new()
	aim_button.text = "MIRAR"
	aim_button.position = Vector2(screen.x - 180.0, screen.y - 295.0)
	aim_button.custom_minimum_size = Vector2(145.0, 56.0)
	aim_button.size = Vector2(145.0, 56.0)
	aim_button.add_theme_font_size_override("font_size", 15)
	aim_button.button_down.connect(func() -> void: player.set_aiming(true))
	aim_button.button_up.connect(func() -> void: player.set_aiming(false))
	_style_button(aim_button)
	root.add_child(aim_button)

	var sprint_button := Button.new()
	sprint_button.text = "CORRER"
	sprint_button.position = Vector2(38.0, screen.y - 270.0)
	sprint_button.custom_minimum_size = Vector2(145.0, 52.0)
	sprint_button.size = Vector2(145.0, 52.0)
	sprint_button.add_theme_font_size_override("font_size", 15)
	sprint_button.button_down.connect(func() -> void: Input.action_press("sprint"))
	sprint_button.button_up.connect(func() -> void: Input.action_release("sprint"))
	if not InputMap.has_action("sprint"):
		InputMap.add_action("sprint")
	_style_button(sprint_button)
	root.add_child(sprint_button)

	var reload_button := Button.new()
	reload_button.text = "RECARREGAR"
	reload_button.position = Vector2(screen.x - 180.0, screen.y - 225.0)
	reload_button.custom_minimum_size = Vector2(145.0, 56.0)
	reload_button.size = Vector2(145.0, 56.0)
	reload_button.add_theme_font_size_override("font_size", 15)
	reload_button.pressed.connect(player.reload)
	_style_button(reload_button)
	root.add_child(reload_button)

func _add_hold_button(root: Control, label_text: String, pos: Vector2, action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var button := Button.new()
	button.text = label_text
	button.position = pos
	button.custom_minimum_size = Vector2(76.0, 76.0)
	button.size = Vector2(76.0, 76.0)
	button.add_theme_font_size_override("font_size", 28)
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	_style_button(button)
	root.add_child(button)

func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.045, 0.055, 0.82)
	normal.border_color = Color(0.58, 0.72, 0.66, 0.92)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 7.0
	normal.content_margin_right = 7.0
	normal.content_margin_top = 5.0
	normal.content_margin_bottom = 5.0
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.12, 0.30, 0.25, 0.96)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 0.93))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
