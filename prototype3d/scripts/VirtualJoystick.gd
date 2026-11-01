extends Control
class_name VirtualJoystick

signal value_changed(value: Vector2)

@export var deadzone: float = 0.12
@export var knob_radius: float = 29.0
@export var movement_radius: float = 55.0

var _value: Vector2 = Vector2.ZERO
var _touch_index: int = -1
var _mouse_pressed: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_stick(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_reset_stick()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_stick(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_pressed = event.pressed
		if _mouse_pressed:
			_update_stick(event.position)
		else:
			_reset_stick()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_pressed:
		_update_stick(event.position)
		accept_event()

func _update_stick(pointer_position: Vector2) -> void:
	var center := size * 0.5
	var offset := pointer_position - center
	_value = (offset / movement_radius).limit_length(1.0)
	if _value.length() < deadzone:
		_value = Vector2.ZERO
	value_changed.emit(_value)
	queue_redraw()

func _reset_stick() -> void:
	_value = Vector2.ZERO
	value_changed.emit(_value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 78.0, Color(0.02, 0.035, 0.04, 0.38))
	draw_arc(center, 76.0, 0.0, TAU, 64, Color(0.82, 0.88, 0.82, 0.55), 2.0, true)
	draw_circle(center, 48.0, Color(0.75, 0.82, 0.76, 0.07))
	draw_circle(center + _value * movement_radius, knob_radius, Color(0.78, 0.86, 0.80, 0.78))
	draw_arc(center + _value * movement_radius, knob_radius, 0.0, TAU, 48, Color(1.0, 1.0, 0.96, 0.85), 2.0, true)
