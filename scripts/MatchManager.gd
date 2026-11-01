extends Node

signal eliminations_changed(defeated: int, total: int)
signal match_finished(victory: bool)

@export var total_enemies: int = 5
var enemies_defeated: int = 0
var match_over: bool = false

func register_enemy_defeat() -> void:
	if match_over:
		return
	enemies_defeated = mini(enemies_defeated + 1, total_enemies)
	eliminations_changed.emit(enemies_defeated, total_enemies)
	print("Inimigos eliminados: ", enemies_defeated, "/", total_enemies)
	if enemies_defeated >= total_enemies:
		trigger_victory()

func trigger_victory() -> void:
	if match_over:
		return
	match_over = true
	match_finished.emit(true)
	print("Partida vencida! BOOYAH!")

func trigger_defeat() -> void:
	if match_over:
		return
	match_over = true
	match_finished.emit(false)
	print("Game Over.")
