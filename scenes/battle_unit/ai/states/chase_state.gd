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

	# 连接导航系统的死锁检测信号
	if not UnitNavigation.chase_deadlock_detected.is_connected(_on_chase_deadlock_detected):
		UnitNavigation.chase_deadlock_detected.connect(_on_chase_deadlock_detected)


func chase() -> void:
	if tween and tween.is_running():
		return

	# 检查是否有有效的目标
	if not target or not is_instance_valid(target):
		print("Warning: No valid target for unit %s, emitting stuck signal" % actor_unit.stats.name)
		stuck.emit()
		return

	var new_position = UnitNavigation.get_next_position(actor_unit, target)

	# 如果无法找到下一个位置
	if new_position == Vector2(-1, -1):
		_handle_no_path_found()
		return

	_execute_movement(new_position)


func _set_target(team: UnitStats.Team) -> void:
	var target_group: String
	if team == UnitStats.Team.PLAYER:
		target_group = "enemy_units"
	else:
		target_group = "player_units"

	var potential_targets = actor_unit.get_tree().get_nodes_in_group(target_group)

	# 检查是否有可用的目标
	if potential_targets.is_empty():
		print("Warning: No targets found in group '%s' for unit %s" % [target_group, actor_unit.stats.name])
		target = null
		return

	target = potential_targets.pick_random()


func _has_target_in_range() -> bool:
	if not target or not is_instance_valid(target):
		return false
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
	if target and is_instance_valid(target):
		target_reached.emit(target)
	else:
		# 如果目标无效，发出stuck信号重新寻找目标
		stuck.emit()


func _on_chase_deadlock_detected(moving_unit: BattleUnit, _target_unit: BattleUnit) -> void:
	# 只处理当前单位的死锁
	if moving_unit != actor_unit:
		return

	print("Chase deadlock detected for unit %s, switching to stuck state" % actor_unit.stats.name)
	stuck.emit()
