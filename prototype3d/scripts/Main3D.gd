extends Node3D

const MAP_SIZE: float = 100.0
const PLAYER_SCRIPT = preload("res://scripts/Player3D.gd")
const BOT_SCRIPT = preload("res://scripts/Bot3D.gd")
const LOOT_SCRIPT = preload("res://scripts/LootPickup3D.gd")

var player
var hud_layer: CanvasLayer
var health_label: Label
var ammo_label: Label
var enemies_label: Label
var status_label: Label

func _ready() -> void:
	_setup_environment()
	_create_ground()
	_create_map_features()
	_create_player()
	_create_bots()
	_create_loot()
	_create_hud()

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	health_label.text = "VIDA  %d / %d" % [roundi(player.health), roundi(player.max_health)]
	ammo_label.text = "%s  |  MUNIÇÃO  %d / %d" % [player.weapon_name, player.ammo, player.reserve_ammo]
	enemies_label.text = "INIMIGOS  %d" % get_tree().get_nodes_in_group("bots").size()
	if player.health <= 0.0:
		status_label.text = "ELIMINADO  |  FIM DE PARTIDA"
	elif get_tree().get_nodes_in_group("bots").is_empty():
		status_label.text = "VITÓRIA  |  TODOS OS INIMIGOS ELIMINADOS"

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

	ammo_label = Label.new()
	ammo_label.position = Vector2(24.0, 87.0)
	ammo_label.size = Vector2(300.0, 30.0)
	ammo_label.add_theme_font_size_override("font_size", 19)
	root.add_child(ammo_label)

	enemies_label = Label.new()
	enemies_label.position = Vector2(screen.x - 230.0, 20.0)
	enemies_label.size = Vector2(210.0, 34.0)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemies_label.add_theme_font_size_override("font_size", 19)
	root.add_child(enemies_label)

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

	var fire := Button.new()
	fire.text = "ATIRAR"
	fire.position = Vector2(screen.x - 180.0, screen.y - 150.0)
	fire.custom_minimum_size = Vector2(145.0, 115.0)
	fire.size = Vector2(145.0, 115.0)
	fire.add_theme_font_size_override("font_size", 22)
	fire.button_down.connect(player.set_firing.bind(true))
	fire.button_up.connect(player.set_firing.bind(false))
	root.add_child(fire)

	var weapon_button := Button.new()
	weapon_button.text = "TROCAR ARMA"
	weapon_button.position = Vector2(screen.x - 180.0, screen.y - 365.0)
	weapon_button.custom_minimum_size = Vector2(145.0, 56.0)
	weapon_button.size = Vector2(145.0, 56.0)
	weapon_button.add_theme_font_size_override("font_size", 15)
	weapon_button.pressed.connect(player.switch_weapon)
	root.add_child(weapon_button)

	var aim_button := Button.new()
	aim_button.text = "MIRAR"
	aim_button.position = Vector2(screen.x - 180.0, screen.y - 295.0)
	aim_button.custom_minimum_size = Vector2(145.0, 56.0)
	aim_button.size = Vector2(145.0, 56.0)
	aim_button.add_theme_font_size_override("font_size", 15)
	aim_button.button_down.connect(func() -> void: player.set_aiming(true))
	aim_button.button_up.connect(func() -> void: player.set_aiming(false))
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
	root.add_child(sprint_button)

	var reload_button := Button.new()
	reload_button.text = "RECARREGAR"
	reload_button.position = Vector2(screen.x - 180.0, screen.y - 225.0)
	reload_button.custom_minimum_size = Vector2(145.0, 56.0)
	reload_button.size = Vector2(145.0, 56.0)
	reload_button.add_theme_font_size_override("font_size", 15)
	reload_button.pressed.connect(player.reload)
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
	root.add_child(button)
