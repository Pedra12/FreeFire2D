extends Node2D

@export var current_radius: float = 2000.0
@export var min_radius: float = 100.0
@export var shrink_speed: float = 15.0
@export var damage_per_second: float = 8.0
@export var damage_interval: float = 0.5

var player_target: Node2D = null
var damage_timer: float = 0.0

func _process(delta: float) -> void:
	if current_radius > min_radius:
		current_radius = maxf(min_radius, current_radius - shrink_speed * delta)
		queue_redraw()

	damage_timer = maxf(0.0, damage_timer - delta)
	if damage_timer > 0.0:
		return
	if not is_instance_valid(player_target):
		player_target = get_parent().get_node_or_null("Player") as Node2D
	if not is_instance_valid(player_target):
		return

	if player_target.global_position.distance_to(global_position) > current_radius:
		if player_target.has_method("take_damage"):
			player_target.call("take_damage", damage_per_second * damage_interval)
		damage_timer = damage_interval

func _draw() -> void:
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 96, Color(0.9, 0.1, 0.1, 0.85), 8.0)
