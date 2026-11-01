extends CharacterBody2D

@export var speed: float = 400.0
@export var health: float = 100.0
@export var armor: float = 0.0

var has_weapon: bool = false
var can_shoot: bool = true
var shoot_cooldown: float = 0.0
const FIRE_INTERVAL: float = 0.25

@onready var sprite: Sprite2D = Sprite2D.new()

func _ready() -> void:
	name = "Player"
	var asset_gen = load("res://scripts/AssetGenerator.gd")
	sprite.texture = asset_gen.create_circle_texture(24.0, Color(0.1, 0.8, 0.3))
	add_child(sprite)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	col.shape = shape
	add_child(col)

func _physics_process(delta: float) -> void:
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	var input_vec := Vector2.ZERO
	input_vec.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vec.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	velocity = input_vec.normalized() * speed
	move_and_slide()

	if velocity.length() > 0.0:
		rotation = velocity.angle()

func equip_weapon() -> void:
	has_weapon = true
	print("Arma Equipada!")

func add_armor(amount: float) -> void:
	armor = clamp(armor + amount, 0.0, 100.0)
	print("Colete: ", armor)

func heal(amount: float) -> void:
	health = clamp(health + amount, 0.0, 100.0)
	print("Vida: ", health)

func shoot() -> void:
	if not has_weapon or not can_shoot or shoot_cooldown > 0.0:
		return

	shoot_cooldown = FIRE_INTERVAL
	var bullet_script = load("res://scripts/Bullet.gd")
	var bullet := Area2D.new()
	bullet.set_script(bullet_script)
	bullet.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 30.0
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	get_parent().add_child(bullet)

func take_damage(amount: float) -> void:
	var damage_after_armor: float = amount * (1.0 - (armor / 200.0))
	health -= damage_after_armor
	print("Dano recebido! Vida restante: ", health)
	if health <= 0.0:
		print("Você foi eliminado!")
		queue_free()
