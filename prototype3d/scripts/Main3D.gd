extends Node3D

const MAP_SIZE: float = 100.0
const PLAYER_SCRIPT = preload("res://scripts/Player3D.gd")
var player
var hud_layer: CanvasLayer

func _ready() -> void:
	_setup_environment()
	_create_ground()
	_create_map_features()
	_create_player()
	_create_hud()

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

	for i in range(28):
		var x := sin(float(i) * 2.4) * 36.0
		var z := cos(float(i) * 1.7) * 36.0
		if Vector2(x, z).length() > 14.0:
			_create_tree(Vector3(x, 0.0, z))

	_create_road(Vector3(0.0, 0.015, 0.0), Vector3(5.0, 0.03, 76.0))
	_create_road(Vector3(0.0, 0.02, 0.0), Vector3(76.0, 0.035, 5.0))

func _create_building(pos: Vector3, size: Vector3, color: Color) -> void:
	var building := StaticBody3D.new()
	building.position = pos + Vector3(0.0, size.y * 0.5, 0.0)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	building.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	building.add_child(collision)
	add_child(building)

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

func _create_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 8.0)
	add_child(player)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_layer.add_child(root)

	var title := Label.new()
	title.text = "FREEFIRE 3D  |  PROTÓTIPO"
	title.position = Vector2(24, 18)
	title.size = Vector2(600, 36)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	var help := Label.new()
	help.text = "Arraste o lado direito para girar a câmera"
	help.position = Vector2(24, 52)
	help.size = Vector2(600, 30)
	help.add_theme_font_size_override("font_size", 16)
	root.add_child(help)

	_add_hold_button(root, "▲", Vector2(100, 500), "move_forward")
	_add_hold_button(root, "▼", Vector2(100, 620), "move_back")
	_add_hold_button(root, "◀", Vector2(35, 560), "move_left")
	_add_hold_button(root, "▶", Vector2(165, 560), "move_right")

	var fire := Button.new()
	fire.text = "ATIRAR"
	fire.position = Vector2(1080, 540)
	fire.custom_minimum_size = Vector2(150, 120)
	fire.size = Vector2(150, 120)
	fire.add_theme_font_size_override("font_size", 23)
	fire.button_down.connect(player.shoot)
	root.add_child(fire)

	var status := Label.new()
	status.text = "FASE 1: MOVIMENTAÇÃO E CÂMERA"
	status.position = Vector2(24, 90)
	status.size = Vector2(600, 30)
	status.add_theme_font_size_override("font_size", 16)
	root.add_child(status)

func _add_hold_button(root: Control, label_text: String, pos: Vector2, action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var button := Button.new()
	button.text = label_text
	button.position = pos
	button.custom_minimum_size = Vector2(88, 88)
	button.size = Vector2(88, 88)
	button.add_theme_font_size_override("font_size", 30)
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	root.add_child(button)
