class_name ChaseState
extends State

signal target_reached(target: BattleUnit)
signal stuck

const ATTACK_RANGE := 35.0

var actor_unit: BattleUnit
var target: BattleUnit
var tween: Tween


func enter() -> void:
	actor_unit = actor as BattleUnit
	_set_target(actor_unit.stats.team)


func chase() -> void:
	if tween and tween.is_running():
		return

	var new_position = UnitNavigation.get_next_position(actor_unit, target)

	# 如果无法找到下一个位置
	if new_position == Vector2(-1, -1):
		_handle_no_path_found()
		return

	_execute_movement(new_position)


func _set_target(team: UnitStats.Team) -> void:
	if team == UnitStats.Team.PLAYER:
		target = actor_unit.get_tree().get_nodes_in_group("enemy_units").pick_random()
	else:
		target = actor_unit.get_tree().get_nodes_in_group("player_units").pick_random()


func _has_target_in_range() -> bool:
	return target.position.distance_to(actor_unit.position) <= ATTACK_RANGE


func _handle_no_path_found() -> void:
	if _has_target_in_range():
		_end_chase()
	else:
		stuck.emit()


func _execute_movement(new_position: Vector2) -> void:
	tween = actor_unit.create_tween()
	tween.tween_callback(actor_unit.animation_player.play.bind("move"))
	tween.tween_property(actor_unit, "global_position", new_position, UnitStats.MOVE_ONE_TILE_SPEED)
	tween.finished.connect(_on_movement_finished)


func _on_movement_finished() -> void:
	tween.kill()
	if _has_target_in_range():
		_end_chase()
	else:
		chase()


func _end_chase() -> void:
	target_reached.emit(target)