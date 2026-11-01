extends Area2D

enum LootType { ARMA, COLETE, KIT_MEDICO }
@export var loot_type: LootType = LootType.ARMA

func _ready() -> void:
	var sprite := Sprite2D.new()
	var asset_gen = load("res://scripts/AssetGenerator.gd")

	match loot_type:
		LootType.ARMA:
			sprite.texture = asset_gen.create_rect_texture(Vector2(24, 12), Color(0.9, 0.2, 0.2))
		LootType.COLETE:
			sprite.texture = asset_gen.create_rect_texture(Vector2(20, 20), Color(0.2, 0.6, 0.9))
		LootType.KIT_MEDICO:
			sprite.texture = asset_gen.create_rect_texture(Vector2(16, 16), Color(0.2, 0.9, 0.3))

	add_child(sprite)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		match loot_type:
			LootType.ARMA:
				body.equip_weapon()
			LootType.COLETE:
				body.add_armor(50.0)
			LootType.KIT_MEDICO:
				body.heal(50.0)
		queue_free()
