extends Node2D

var current_radius: float = 2000.0
var min_radius: float = 100.0
var shrink_speed: float = 15.0

func _process(delta: float) -> void:
	if current_radius > min_radius:
		current_radius = maxf(min_radius, current_radius - shrink_speed * delta)
		queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 64, Color(0.9, 0.1, 0.1, 0.8), 8.0)
