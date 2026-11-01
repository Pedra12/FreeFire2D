extends CharacterBody2D

@export var speed: float = 400.0
@export var health: float = 100.0
@export var armor: float = 0.0

var has_weapon: bool = false
var can_shoot: bool = true
var shoot_cooldown: float = 0.0
var ammo: int = 30
const FIRE_INTERVAL: float = 0.25

func _ready() -> void:
	name = "Player"
	var asset_gen = load("res://scripts/AssetGenerator.gd")
	var sprite := Sprite2D.new()
	sprite.texture = asset_gen.create_circle_texture(24.0, Color(0.1, 0.8, 0.3))
	add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	velocity = input_vector.normalized() * speed
	move_and_slide()
	if velocity.length() > 0.0:
		rotation = velocity.angle()

func equip_weapon() -> void:
	has_weapon = true
	print("Arma equipada!")

func add_armor(amount: float) -> void:
	armor = clampf(armor + amount, 0.0, 100.0)

func heal(amount: float) -> void:
	health = clampf(health + amount, 0.0, 100.0)

func shoot() -> void:
	if not has_weapon or not can_shoot or shoot_cooldown > 0.0 or ammo <= 0:
		return
	shoot_cooldown = FIRE_INTERVAL
	ammo -= 1
	var bullet := Area2D.new()
	bullet.set_script(load("res://scripts/Bullet.gd"))
	bullet.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 30.0
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	get_parent().add_child(bullet)

func take_damage(amount: float) -> void:
	var damage_after_armor: float = amount * (1.0 - armor / 200.0)
	health = maxf(0.0, health - damage_after_armor)
	if health <= 0.0:
		var manager := get_parent().get_node_or_null("MatchManager")
		if manager and manager.has_method("trigger_defeat"):
			manager.trigger_defeat()
		queue_free()
