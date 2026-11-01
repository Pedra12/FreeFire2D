extends Node2D

func _ready() -> void:
	var asset_gen = load("res://scripts/AssetGenerator.gd")

	# Chão / grama do mapa (4000 x 4000)
	var bg := Sprite2D.new()
	bg.texture = asset_gen.create_rect_texture(Vector2(4000, 4000), Color(0.15, 0.35, 0.15))
	bg.z_index = -10
	add_child(bg)

	# Obstáculos / construções
	create_wall(Vector2(-300, -200), Vector2(200, 400))
	create_wall(Vector2(400, 300), Vector2(500, 150))

	# Itens no chão
	spawn_loot(Vector2(-100, -100), 0) # Arma
	spawn_loot(Vector2(100, 200), 1) # Colete
	spawn_loot(Vector2(200, -150), 2) # Kit médico

	# Jogador
	var player_script = load("res://scripts/Player.gd")
	var player := CharacterBody2D.new()
	player.set_script(player_script)
	player.position = Vector2.ZERO
	add_child(player)

	# Câmera
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	player.add_child(camera)

	# Zona segura
	var safe_zone_script = load("res://scripts/SafeZone.gd")
	var safe_zone := Node2D.new()
	safe_zone.set_script(safe_zone_script)
	add_child(safe_zone)

	setup_mobile_ui(player)

func create_wall(pos: Vector2, size: Vector2) -> void:
	var asset_gen = load("res://scripts/AssetGenerator.gd")
	var wall := StaticBody2D.new()
	wall.position = pos

	var sprite := Sprite2D.new()
	sprite.texture = asset_gen.create_rect_texture(size, Color(0.4, 0.4, 0.45))
	wall.add_child(sprite)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	wall.add_child(col)

	add_child(wall)

func spawn_loot(pos: Vector2, loot_type: int) -> void:
	var loot_script = load("res://scripts/Loot.gd")
	var loot := Area2D.new()
	loot.set_script(loot_script)
	loot.loot_type = loot_type
	loot.position = pos
	add_child(loot)

func setup_mobile_ui(player: CharacterBody2D) -> void:
	var canvas := CanvasLayer.new()

	# Direcional touch à esquerda. Também mantém os controles de teclado.
	_add_move_button(canvas, "↑", Vector2(170, 700), "ui_up")
	_add_move_button(canvas, "←", Vector2(60, 810), "ui_left")
	_add_move_button(canvas, "→", Vector2(280, 810), "ui_right")
	_add_move_button(canvas, "↓", Vector2(170, 920), "ui_down")

	var shoot_btn := Button.new()
	shoot_btn.text = "ATIRAR"
	shoot_btn.custom_minimum_size = Vector2(180, 180)
	shoot_btn.position = Vector2(1600, 800)
	shoot_btn.add_theme_font_size_override("font_size", 28)
	shoot_btn.pressed.connect(Callable(player, "shoot"))
	canvas.add_child(shoot_btn)
	add_child(canvas)

func _add_move_button(canvas: CanvasLayer, label: String, button_position: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(100, 100)
	button.position = button_position
	button.add_theme_font_size_override("font_size", 34)
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	canvas.add_child(button)
