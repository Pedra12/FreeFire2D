extends CanvasLayer

var health_label: Label
var armor_label: Label
var ammo_label: Label
var enemies_label: Label
var message_label: Label

func _ready() -> void:
	var container := VBoxContainer.new()
	container.position = Vector2(40, 35)
	container.add_theme_constant_override("separation", 8)
	add_child(container)

	health_label = _make_label(container, "Vida: 100")
	armor_label = _make_label(container, "Colete: 0")
	ammo_label = _make_label(container, "Munição: 30")
	enemies_label = _make_label(container, "Inimigos: 0/5")

	message_label = Label.new()
	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 64)
	message_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	add_child(message_label)

func _make_label(parent: VBoxContainer, initial_text: String) -> Label:
	var label := Label.new()
	label.text = initial_text
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(label)
	return label

func update_hud(health: float, armor: float, ammo: int) -> void:
	health_label.text = "Vida: " + str(int(health))
	armor_label.text = "Colete: " + str(int(armor))
	ammo_label.text = "Munição: " + str(ammo)

func update_eliminations(defeated: int, total: int) -> void:
	enemies_label.text = "Inimigos: " + str(defeated) + "/" + str(total)

func show_message(message: String) -> void:
	message_label.text = message
