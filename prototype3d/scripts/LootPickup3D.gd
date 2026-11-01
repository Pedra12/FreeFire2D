extends Area3D
class_name LootPickup3D

@export_enum("ammo", "medkit", "armor", "backpack") var loot_type: String = "ammo"
@export var amount: int = 30

func _ready() -> void:
	_build_visual()
	body_entered.connect(_on_body_entered)

func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.65, 0.42, 0.65)
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	var loot_colors := {"ammo": Color(0.12, 0.55, 0.82), "medkit": Color(0.12, 0.72, 0.28), "armor": Color(0.85, 0.62, 0.12), "backpack": Color(0.58, 0.32, 0.78)}
	material.albedo_color = loot_colors.get(loot_type, Color.WHITE)
	material.metallic = 0.15
	mesh_instance.material_override = material
	mesh_instance.position.y = 0.35
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.1
	collision.shape = shape
	collision.position.y = 0.45
	add_child(collision)

func _on_body_entered(body: Node3D) -> void:
	if loot_type == "ammo" and body.has_method("add_ammo"):
		body.call("add_ammo", amount)
	elif loot_type == "medkit" and body.has_method("heal"):
		body.call("heal", float(amount))
	elif loot_type == "armor" and body.has_method("repair_armor"):
		body.call("repair_armor", float(amount))
	elif loot_type == "backpack" and body.has_method("upgrade_backpack"):
		body.call("upgrade_backpack")
	else:
		return
	queue_free()
