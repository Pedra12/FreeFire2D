extends Node2D

const ENEMY_COUNT: int = 5
var player
var game_hud
var match_manager

func _ready() -> void:
	var asset_gen = load("res://scripts/AssetGenerator.gd")

	var background := Sprite2D.new()
	background.texture = asset_gen.create_rect_texture(Vector2(4000, 4000), Color(0.15, 0.35, 0.15))
	background.z_index = -10
	add_child(background)

	create_wall(Vector2(-300, -200), Vector2(200, 400))
	create_wall(Vector2(400, 300), Vector2(500, 150))
	create_wall(Vector2(-700, 500), Vector2(350, 120))
	create_wall(Vector2(800, -650), Vector2(140, 400))

	spawn_loot(Vector2(-100, -100), 0)
	spawn_loot(Vector2(100, 200), 1)
	spawn_loot(Vector2(200, -150), 2)

	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/Player.gd"))
	player.position = Vector2.ZERO
	add_child(player)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	player.add_child(camera)

	var safe_zone := Node2D.new()
	safe_zone.set_script(load("res://scripts/SafeZone.gd"))
	add_child(safe_zone)

	match_manager = Node.new()
	match_manager.name = "MatchManager"
	match_manager.set_script(load("res://scripts/MatchManager.gd"))
	match_manager.set("total_enemies", ENEMY_COUNT)
	add_child(match_manager)

	game_hud = CanvasLayer.new()
	game_hud.set_script(load("res://scripts/GameHUD.gd"))
	add_child(game_hud)
	match_manager.eliminations_changed.connect(game_hud.update_eliminations)
	match_manager.match_finished.connect(_on_match_finished)
	game_hud.update_eliminations(0, ENEMY_COUNT)

	spawn_enemies()
	setup_mobile_ui(player)

func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(game_hud):
		game_hud.update_hud(player.health, player.armor, 30)

func spawn_enemies() -> void:
	var positions: Array[Vector2] = [
		Vector2(650, 250),
		Vector2(-650, -350),
		Vector2(950, 700),
		Vector2(-1000, 800),
		Vector2(1200, -900)
	]
	for enemy_position in positions:
		var enemy := CharacterBody2D.new()
		enemy.set_script(load("res://scripts/Enemy.gd"))
		enemy.position = enemy_position
		add_child(enemy)

func _on_match_finished(victory: bool) -> void:
	if is_instance_valid(game_hud):
		game_hud.show_message("VITÓRIA! BOOYAH!" if victory else "VOCÊ FOI ELIMINADO")
	get_tree().paused = true

func create_wall(pos: Vector2, size: Vector2) -> void:
	var asset_gen = load("res://scripts/AssetGenerator.gd")
	var wall := StaticBody2D.new()
	wall.position = pos
	var sprite := Sprite2D.new()
	sprite.texture = asset_gen.create_rect_texture(size, Color(0.4, 0.4, 0.45))
	wall.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func spawn_loot(pos: Vector2, loot_type: int) -> void:
	var loot := Area2D.new()
	loot.set_script(load("res://scripts/Loot.gd"))
	loot.loot_type = loot_type
	loot.position = pos
	add_child(loot)

func setup_mobile_ui(target_player: CharacterBody2D) -> void:
	var canvas := CanvasLayer.new()
	_add_move_button(canvas, "↑", Vector2(170, 700), "ui_up")
	_add_move_button(canvas, "←", Vector2(60, 810), "ui_left")
	_add_move_button(canvas, "→", Vector2(280, 810), "ui_right")
	_add_move_button(canvas, "↓", Vector2(170, 920), "ui_down")

	var shoot_button := Button.new()
	shoot_button.text = "ATIRAR"
	shoot_button.custom_minimum_size = Vector2(180, 180)
	shoot_button.position = Vector2(1600, 800)
	shoot_button.add_theme_font_size_override("font_size", 28)
	shoot_button.pressed.connect(Callable(target_player, "shoot"))
	canvas.add_child(shoot_button)
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
