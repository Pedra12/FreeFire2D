extends Area3D
class_name LootPickup3D

@export_enum("ammo", "medkit") var loot_type: String = "ammo"
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
	material.albedo_color = Color(0.12, 0.55, 0.82) if loot_type == "ammo" else Color(0.12, 0.72, 0.28)
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
	else:
		return
	queue_free()
