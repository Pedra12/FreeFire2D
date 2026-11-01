extends Area2D

@export var speed: float = 1200.0
@export var damage: float = 25.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	var sprite := Sprite2D.new()
	var asset_gen = load("res://scripts/AssetGenerator.gd")
	sprite.texture = asset_gen.create_circle_texture(6.0, Color(1.0, 0.9, 0.2))
	add_child(sprite)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
