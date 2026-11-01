extends CharacterBody2D

@export var speed: float = 250.0
@export var health: float = 100.0
@export var detection_range: float = 600.0
@export var attack_range: float = 80.0

var player_target: Node2D = null
var defeated: bool = false

func _ready() -> void:
	name = "Enemy"
	var asset_gen = load("res://scripts/AssetGenerator.gd")
	var sprite := Sprite2D.new()
	sprite.texture = asset_gen.create_circle_texture(24.0, Color(0.9, 0.2, 0.2))
	add_child(sprite)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	collision.shape = shape
	add_child(collision)

func _physics_process(_delta: float) -> void:
	if defeated:
		return
	if not is_instance_valid(player_target):
		player_target = get_parent().get_node_or_null("Player") as Node2D
	if not is_instance_valid(player_target):
		velocity = Vector2.ZERO
		return

	var offset := player_target.global_position - global_position
	var distance := offset.length()
	if distance <= detection_range and distance > attack_range:
		var direction := offset.normalized()
		velocity = direction * speed
		rotation = direction.angle()
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func take_damage(amount: float) -> void:
	if defeated:
		return
	health = maxf(0.0, health - amount)
	print("Inimigo atingido! Vida: ", health)
	if health <= 0.0:
		defeated = true
		var manager := get_parent().get_node_or_null("MatchManager")
		if manager and manager.has_method("register_enemy_defeat"):
			manager.call("register_enemy_defeat")
		queue_free()
