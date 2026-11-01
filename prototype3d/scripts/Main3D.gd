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
var zone_ring: Node3D
var zone_segments: Array[MeshInstance3D] = []
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
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.075, 0.16, 0.27)
	sky_material.sky_horizon_color = Color(0.48, 0.61, 0.68)
	sky_material.ground_bottom_color = Color(0.12, 0.16, 0.13)
	sky_material.ground_horizon_color = Color(0.48, 0.55, 0.45)
	sky_material.sun_angle_max = 18.0
	sky_material.use_debanding = true
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.56, 0.64, 0.66)
	environment.fog_density = 0.0025
	environment.fog_sun_scatter = 0.12
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

func _create_zone_ring() -> void:
	zone_ring = Node3D.new()
	zone_ring.name = "SafeZoneBoundary"
	add_child(zone_ring)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.12, 0.62, 1.0, 0.9)
	for i in range(64):
		var segment := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22, 0.08, 0.9)
		segment.mesh = mesh
		segment.material_override = material
		zone_ring.add_child(segment)
		zone_segments.append(segment)
	_update_zone_ring()

func _update_zone_ring() -> void:
	if not is_instance_valid(zone_ring):
		return
	for i in range(zone_segments.size()):
		var angle := TAU * float(i) / float(zone_segments.size())
		var segment := zone_segments[i]
		segment.position = Vector3(cos(angle) * safe_zone_radius, 0.08, sin(angle) * safe_zone_radius)
		segment.rotation.y = angle + PI * 0.5

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
	for i in range(18):
		var angle := float(i) * TAU / 18.0
		var cover_position := Vector3(cos(angle) * 30.0, 0.0, sin(angle) * 30.0)
		_spawn_asset(self, "nature-kit/plant-bushlarge.glb", cover_position, 1.1 + float(i % 3) * 0.18, angle)
	for i in range(14):
		var angle := float(i) * TAU / 14.0 + 0.3
		var rock_position := Vector3(cos(angle) * 39.0, 0.0, sin(angle) * 39.0)
		_spawn_asset(self, "nature-kit/rock-largea.glb", rock_position, 1.0 + float(i % 2) * 0.35, angle)
	_create_road(Vector3(0.0, 0.015, 0.0), Vector3(5.0, 0.03, 76.0))
	_create_road(Vector3(0.0, 0.02, 0.0), Vector3(76.0, 0.035, 5.0))
	_create_vehicle(Vector3(8.0, 0.0, 3.7), 0.25)
	_create_vehicle(Vector3(-8.0, 0.0, -3.7), PI)
	_spawn_asset(self, "city-kit-roads/light-curved.glb", Vector3(4.0, 0.0, -10.0), 1.8, 0.0)
	_spawn_asset(self, "city-kit-roads/light-curved.glb", Vector3(-4.0, 0.0, 10.0), 1.8, PI)
	_spawn_asset(self, "city-kit-roads/dumpster.glb", Vector3(19.0, 0.0, -13.0), 1.3)
	_spawn_asset(self, "city-kit-roads/road-sign-street.glb", Vector3(-7.0, 0.0, 5.0), 1.5)


func _create_road(pos: Vector3, road_size: Vector3) -> void:
	var road := StaticBody3D.new()
	road.name = "Road"
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = road_size
	visual.mesh = mesh
	visual.position = pos
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.105, 0.12, 0.13)
	asphalt.roughness = 0.98
	visual.material_override = asphalt
	road.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(road_size.x, maxf(road_size.y, 0.12), road_size.z)
	collision.shape = shape
	collision.position = pos
	road.add_child(collision)
	var horizontal := road_size.x > road_size.z
	var dash_count := 14
	for i in range(dash_count):
		var marker := MeshInstance3D.new()
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.12, 0.025, 1.65) if horizontal else Vector3(1.65, 0.025, 0.12)
		marker.mesh = marker_mesh
		var offset := -road_size.z * 0.5 + (float(i) + 0.5) * road_size.z / float(dash_count) if horizontal else -road_size.x * 0.5 + (float(i) + 0.5) * road_size.x / float(dash_count)
		marker.position = pos + (Vector3(0.0, 0.03, offset) if horizontal else Vector3(offset, 0.03, 0.0))
		var paint := StandardMaterial3D.new()
		paint.albedo_color = Color(0.82, 0.78, 0.58)
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.material_override = paint
		road.add_child(marker)
	add_child(road)

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
	# Furniture and loot cover inside the playable building shell.
	_spawn_asset(building, "furniture-kit/beddouble.glb", Vector3(-size.x * 0.22, -size.y * 0.5 + 0.12, size.z * 0.18), 0.9)
	_spawn_asset(building, "furniture-kit/chair.glb", Vector3(size.x * 0.20, -size.y * 0.5 + 0.05, -size.z * 0.10), 0.9)
	_spawn_asset(building, "furniture-kit/desk.glb", Vector3(size.x * 0.20, -size.y * 0.5 + 0.05, -size.z * 0.28), 0.85)
	_spawn_asset(building, "furniture-kit/cardboardboxclosed.glb", Vector3(-size.x * 0.25, -size.y * 0.5 + 0.1, -size.z * 0.25), 0.8)

	# Second storey: half-floor, a walkable ramp and visible stair treads.
	var upper_floor_y := -size.y * 0.5 + wall_height * 0.58
	var upper_floor_size := Vector3(size.x - 0.4, 0.18, size.z * 0.48)
	var upper_floor_pos := Vector3(0.0, upper_floor_y, size.z * 0.25)
	_building_piece(building, upper_floor_size, upper_floor_pos, inside_material)
	var ramp_height := upper_floor_y + size.y * 0.5
	var ramp_run := size.z * 0.56
	var ramp_angle := atan2(ramp_height, ramp_run)
	var ramp_pos := Vector3(-size.x * 0.28, -size.y * 0.5 + ramp_height * 0.5, -size.z * 0.38 + ramp_run * 0.5)
	var ramp_mesh := MeshInstance3D.new()
	var ramp_box := BoxMesh.new()
	ramp_box.size = Vector3(1.45, 0.16, ramp_run)
	ramp_mesh.mesh = ramp_box
	ramp_mesh.position = ramp_pos
	ramp_mesh.rotation.x = -ramp_angle
	var stair_material := StandardMaterial3D.new()
	stair_material.albedo_color = Color(0.27, 0.20, 0.13)
	stair_material.roughness = 0.94
	ramp_mesh.material_override = stair_material
	building.add_child(ramp_mesh)
	var ramp_collision := CollisionShape3D.new()
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = ramp_box.size
	ramp_collision.shape = ramp_shape
	ramp_collision.position = ramp_pos
	ramp_collision.rotation.x = -ramp_angle
	building.add_child(ramp_collision)
	for step_index in range(8):
		var step := MeshInstance3D.new()
		var step_mesh := BoxMesh.new()
		step_mesh.size = Vector3(1.48, 0.16, ramp_run / 8.0 + 0.04)
		step.mesh = step_mesh
		step.position = Vector3(ramp_pos.x, -size.y * 0.5 + (float(step_index) + 0.5) * ramp_height / 8.0 + 0.12, -size.z * 0.38 + (float(step_index) + 0.5) * ramp_run / 8.0)
		step.material_override = stair_material
		building.add_child(step)
	_spawn_asset(building, "furniture-kit/loungesofa.glb", Vector3(size.x * 0.18, upper_floor_y + 0.12, size.z * 0.30), 0.78)
	_spawn_asset(building, "furniture-kit/table.glb", Vector3(-size.x * 0.08, upper_floor_y + 0.12, size.z * 0.34), 0.78)
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
	tree.name = "KenneyTree"
	tree.position = pos
	var variant := "tree-default.glb" if int(absf(pos.x * 11.0 + pos.z * 7.0)) % 2 == 0 else "tree-palm.glb"
	_spawn_asset(tree, "nature-kit/" + variant, Vector3.ZERO, 1.35)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.48
	shape.height = 3.2
	collision.shape = shape
	collision.position.y = 1.6
	tree.add_child(collision)
	add_child(tree)

func _create_vehicle(pos: Vector3, heading: float) -> void:
	var vehicle := StaticBody3D.new()
	vehicle.name = "ParkedVehicle"
	vehicle.position = pos
	vehicle.rotation.y = heading
	var model := "car-kit/suv.glb" if pos.x > 0.0 else "car-kit/police.glb"
	_spawn_asset(vehicle, model, Vector3.ZERO, 1.35)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.15, 1.7, 4.1)
	collision.shape = shape
	collision.position.y = 0.85
	vehicle.add_child(collision)
	add_child(vehicle)

func _spawn_asset(parent: Node3D, asset_file: String, local_position: Vector3, asset_scale: float = 1.0, yaw: float = 0.0) -> Node3D:
	var path := "res://assets/kenney/" + asset_file
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Asset 3D ausente ou não importado: " + path)
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		push_warning("Asset 3D não possui raiz Node3D: " + path)
		return null
	instance.position = local_position
	instance.scale = Vector3.ONE * asset_scale
	instance.rotation.y = yaw
	parent.add_child(instance)
	return instance

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
