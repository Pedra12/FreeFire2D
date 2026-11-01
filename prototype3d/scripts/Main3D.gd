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

func _make_pbr_material(pack_name: String, tint: Color, uv_scale: Vector3) -> StandardMaterial3D:
	var folder := "res://assets/pbr/" + pack_name + "/" + pack_name + "_"
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load(folder + "Color.jpg") as Texture2D
	material.normal_enabled = true
	material.normal_texture = load(folder + "NormalGL.jpg") as Texture2D
	material.normal_scale = 0.72
	material.roughness_texture = load(folder + "Roughness.jpg") as Texture2D
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	var ao_map := load(folder + "AmbientOcclusion.jpg") as Texture2D
	if ao_map != null:
		material.ao_enabled = true
		material.ao_texture = ao_map
		material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	material.roughness = 0.88
	material.uv1_scale = uv_scale
	return material

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
	var material := _make_pbr_material("Grass004_2K-JPG", Color(0.78, 0.86, 0.72), Vector3(22.0, 22.0, 1.0))
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
	_spawn_city_building("building-type-a.glb", Vector3(12, 0, -12), Vector3(10.0, 5.5, 9.0), 0.0)
	_spawn_city_building("building-type-b.glb", Vector3(-15, 0, -8), Vector3(8.5, 5.0, 8.5), PI * 0.5)
	_spawn_city_building("building-type-c.glb", Vector3(16, 0, 15), Vector3(11.0, 6.0, 10.0), PI)
	_spawn_city_building("building-type-d.glb", Vector3(-18, 0, 17), Vector3(9.5, 5.5, 10.5), -PI * 0.5)
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
	_spawn_asset(self, "city-kit-suburban/driveway-long.glb", Vector3(12.0, 0.01, -5.8), 1.0, 0.0)
	_spawn_asset(self, "city-kit-suburban/path-stones-messy.glb", Vector3(-15.0, 0.02, -1.0), 1.5, 0.4)
	_spawn_asset(self, "city-kit-suburban/fence-1x3.glb", Vector3(6.0, 0.0, -19.0), 1.0, 0.0)
	_spawn_asset(self, "city-kit-suburban/fence-1x4.glb", Vector3(19.0, 0.0, -19.0), 1.0, 0.0)
	_spawn_asset(self, "city-kit-suburban/planter.glb", Vector3(22.0, 0.0, 10.0), 1.0, PI * 0.5)


func _spawn_city_building(model_file: String, pos: Vector3, collision_size: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = "CityBuilding_" + model_file.trim_suffix(".glb")
	body.position = pos
	_spawn_asset(body, "city-kit-suburban/" + model_file, Vector3.ZERO, 1.0, yaw)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.shape = shape
	collision.position.y = collision_size.y * 0.5
	body.add_child(collision)
	add_child(body)

func _create_road(pos: Vector3, road_size: Vector3) -> void:
	var road := StaticBody3D.new()
	road.name = "Road"
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = road_size
	visual.mesh = mesh
	visual.position = pos
	var asphalt := _make_pbr_material("Asphalt021_2K-JPG", Color(0.72, 0.74, 0.76), Vector3(7.0, 7.0, 1.0))
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
	var wall_material := _make_pbr_material("Concrete012_2K-JPG", color.lightened(0.16), Vector3(2.6, 2.6, 1.0))
	var inside_material := _make_pbr_material("Concrete012_2K-JPG", color.darkened(0.18), Vector3(2.2, 2.2, 1.0))
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
	hud_layer.layer = 10
	add_child(hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_layer.add_child(root)
	var screen := get_viewport().get_visible_rect().size

	for action in ["move_left", "move_right", "move_forward", "move_back", "jump", "sprint"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

	_add_hud_panel(root, Rect2(18.0, 14.0, 310.0, 112.0))
	_add_hud_panel(root, Rect2(screen.x - 230.0, 14.0, 212.0, 82.0))

	var title := Label.new()
	title.text = "BATTLE ROYALE"
	title.position = Vector2(30.0, 18.0)
	title.size = Vector2(270.0, 24.0)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.88, 0.91, 0.86))
	root.add_child(title)

	health_label = Label.new()
	health_label.position = Vector2(30.0, 43.0)
	health_label.size = Vector2(280.0, 24.0)
	health_label.add_theme_font_size_override("font_size", 16)
	root.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(30.0, 70.0)
	health_bar.size = Vector2(270.0, 12.0)
	health_bar.min_value = 0.0
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_bar.show_percentage = false
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color(0.04, 0.05, 0.05, 0.9)
	health_background.set_corner_radius_all(6)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(0.20, 0.78, 0.34, 1.0)
	health_fill.set_corner_radius_all(6)
	health_bar.add_theme_stylebox_override("background", health_background)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	root.add_child(health_bar)

	ammo_label = Label.new()
	ammo_label.position = Vector2(screen.x - 220.0, screen.y - 62.0)
	ammo_label.size = Vector2(205.0, 42.0)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size", 17)
	root.add_child(ammo_label)

	enemies_label = Label.new()
	enemies_label.position = Vector2(screen.x - 215.0, 23.0)
	enemies_label.size = Vector2(190.0, 28.0)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemies_label.add_theme_font_size_override("font_size", 17)
	root.add_child(enemies_label)

	zone_label = Label.new()
	zone_label.position = Vector2(screen.x - 215.0, 54.0)
	zone_label.size = Vector2(190.0, 25.0)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	zone_label.add_theme_font_size_override("font_size", 14)
	root.add_child(zone_label)

	status_label = Label.new()
	status_label.text = "ELIMINE OS BOTS E COLETE SUPRIMENTOS"
	status_label.position = Vector2(screen.x * 0.5 - 220.0, 18.0)
	status_label.size = Vector2(440.0, 28.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	root.add_child(status_label)

	var crosshair := Label.new()
	crosshair.text = "·"
	crosshair.position = screen * 0.5 - Vector2(5.0, 15.0)
	crosshair.size = Vector2(12.0, 24.0)
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 0.95))
	root.add_child(crosshair)

	var joystick = preload("res://scripts/VirtualJoystick.gd").new()
	joystick.name = "MovementJoystick"
	joystick.position = Vector2(34.0, screen.y - 204.0)
	joystick.custom_minimum_size = Vector2(176.0, 176.0)
	joystick.size = Vector2(176.0, 176.0)
	joystick.value_changed.connect(player.set_mobile_move_vector)
	root.add_child(joystick)

	_add_touch_button(root, "CORRER", Vector2(62.0, screen.y - 270.0), Vector2(112.0, 44.0), "sprint")
	_add_touch_button(root, "ATIRAR", Vector2(screen.x - 154.0, screen.y - 176.0), Vector2(112.0, 112.0), "fire")
	_add_touch_button(root, "MIRA", Vector2(screen.x - 270.0, screen.y - 112.0), Vector2(76.0, 76.0), "aim")
	_add_touch_button(root, "PULAR", Vector2(screen.x - 104.0, screen.y - 302.0), Vector2(78.0, 78.0), "jump")
	_add_touch_button(root, "REC", Vector2(screen.x - 252.0, screen.y - 260.0), Vector2(68.0, 68.0), "reload")
	_add_touch_button(root, "ARMA", Vector2(screen.x - 164.0, screen.y - 350.0), Vector2(68.0, 68.0), "switch")

func _add_touch_button(root: Control, label_text: String, pos: Vector2, button_size: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = label_text
	button.position = pos
	button.custom_minimum_size = button_size
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14 if button_size.x < 90.0 else 17)
	var radius := int(minf(button_size.x, button_size.y) * 0.5) if button_size.x == button_size.y else 16
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.055, 0.060, 0.78)
	normal.border_color = Color(0.78, 0.84, 0.76, 0.86)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(radius)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.18, 0.38, 0.29, 0.96)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.97, 0.98, 0.94))
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	match action:
		"fire":
			button.button_down.connect(player.set_firing.bind(true))
			button.button_up.connect(player.set_firing.bind(false))
		"aim":
			button.button_down.connect(player.set_aiming.bind(true))
			button.button_up.connect(player.set_aiming.bind(false))
		"jump":
			button.button_down.connect(func() -> void: Input.action_press("jump"))
			button.button_up.connect(func() -> void: Input.action_release("jump"))
		"sprint":
			button.button_down.connect(func() -> void: Input.action_press("sprint"))
			button.button_up.connect(func() -> void: Input.action_release("sprint"))
		"reload":
			button.pressed.connect(player.reload)
		"switch":
			button.pressed.connect(player.switch_weapon)
	root.add_child(button)

func _add_hud_panel(root: Control, rect: Rect2) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.035, 0.045, 0.72)
	style.border_color = Color(0.22, 0.48, 0.52, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 5
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

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
