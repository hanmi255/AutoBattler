class_name UnitStateMachine
extends Node

signal state_changed(from_state: int, to_state: int)

enum BattleUnitStates {
	IDLE,
	SEEK_TARGET,
	MOVE,
	ATTACK,
	CAST,
	TAKE_DAMAGE,
	DEAD
}

@export var initial_state: int = 0

var battle_unit: BattleUnit
var current_state: int = -1
var previous_state: int = -1
var states_map: Dictionary = {}
var states_stack: Array[int] = []
var active: bool = true


func _ready() -> void:
	states_map = {
		BattleUnitStates.IDLE: "idle",
		BattleUnitStates.SEEK_TARGET: "seek_target",
		BattleUnitStates.MOVE: "move",
		BattleUnitStates.ATTACK: "attack",
		BattleUnitStates.CAST: "cast",
		BattleUnitStates.TAKE_DAMAGE: "take_damage",
		BattleUnitStates.DEAD: "dead"
	}

	battle_unit = get_parent()
	print("battle_unit: ", battle_unit)
	change_state(initial_state)


func _physics_process(delta: float) -> void:
	if not active:
		return

	if current_state != -1:
		_state_logic(delta)

		var transition = _get_transition()
		if transition != -1:
			change_state(transition)


func change_state(new_state: int) -> void:
	if not active:
		return

	if current_state != new_state:
		previous_state = current_state
		current_state = new_state
		
		# 如果有前一个状态，则执行退出逻辑
		if previous_state != -1:
			_exit_state(previous_state, new_state)

		_enter_state(new_state, previous_state)

		state_changed.emit(previous_state, new_state)


# 压入状态到状态栈
func push_state(new_state: int) -> void:
	states_stack.push_back(current_state)
	change_state(new_state)


# 从状态栈弹出并恢复前一状态
func pop_state() -> void:
	if states_stack.size() > 0:
		change_state(states_stack.pop_back())


func _update_facing(direction: Vector2) -> void:
	if abs(direction.x) > 0.1:
		battle_unit.skin.flip_h = direction.x < 0


func _state_logic(delta: float) -> void:
	match current_state:
		BattleUnitStates.IDLE:
			_idle_logic(delta)
		BattleUnitStates.SEEK_TARGET:
			_seek_target_logic(delta)
		BattleUnitStates.MOVE:
			_move_logic(delta)
		BattleUnitStates.ATTACK:
			_attack_logic(delta)
		BattleUnitStates.CAST:
			_cast_logic(delta)
		BattleUnitStates.TAKE_DAMAGE:
			_take_damage_logic(delta)
		BattleUnitStates.DEAD:
			_dead_logic(delta)


func _get_transition() -> int:
	match current_state:
		BattleUnitStates.IDLE:
			if battle_unit.target_unit:
				return BattleUnitStates.SEEK_TARGET
		BattleUnitStates.SEEK_TARGET:
			if battle_unit.target_unit and _is_in_attack_range():
				return BattleUnitStates.ATTACK
			elif battle_unit.current_path.size() > 0:
				return BattleUnitStates.MOVE
		BattleUnitStates.MOVE:
			if battle_unit.current_path.is_empty():
				if battle_unit.target_unit and _is_in_attack_range():
					return BattleUnitStates.ATTACK
				else:
					return BattleUnitStates.IDLE
		BattleUnitStates.ATTACK:
			if not battle_unit.target_unit or not _is_in_attack_range():
				return BattleUnitStates.SEEK_TARGET
		BattleUnitStates.TAKE_DAMAGE:
			# 受伤后返回之前的状态
			if states_stack.size() > 0:
				return states_stack.pop_back()
			else:
				return BattleUnitStates.IDLE

	return -1


func _enter_state(new_state: int, _old_state: int) -> void:
	match new_state:
		BattleUnitStates.IDLE:
			battle_unit.anim_player.play("idle")
		BattleUnitStates.MOVE:
			battle_unit.anim_player.play("move")
		BattleUnitStates.ATTACK:
			battle_unit.anim_player.play("attack")
		BattleUnitStates.CAST:
			battle_unit.anim_player.play("cast")
		BattleUnitStates.TAKE_DAMAGE:
			battle_unit.anim_player.play("take_damage")
		BattleUnitStates.DEAD:
			battle_unit.anim_player.play("dead")


func _exit_state(_old_state: int, _new_state: int) -> void:
	match _old_state:
		BattleUnitStates.MOVE:
			battle_unit.anim_player.play("RESET")
		BattleUnitStates.ATTACK:
			battle_unit.anim_player.play("RESET")
		BattleUnitStates.CAST:
			battle_unit.anim_player.play("RESET")
		BattleUnitStates.TAKE_DAMAGE:
			battle_unit.anim_player.play("RESET")
		BattleUnitStates.DEAD:
			battle_unit.anim_player.play("RESET")


func _idle_logic(_delta: float) -> void:
	pass


func _seek_target_logic(_delta: float) -> void:
	if not battle_unit.target_unit:
		battle_unit.find_target()
	else:
		battle_unit.move_to_target()


func _move_logic(_delta: float) -> void:
	if battle_unit.current_path.size() > 1:
		var direction = battle_unit.target_position - battle_unit.global_position
		_update_facing(direction)
		
		var distance = battle_unit.global_position.distance_to(battle_unit.target_position)
		if distance < 5.0: # 当接近目标点时视为已到达
			battle_unit.global_position = battle_unit.target_position
			battle_unit.current_path.clear()
		else:
			var move_direction = direction.normalized()
			battle_unit.position += move_direction * battle_unit.move_speed * _delta


func _attack_logic(_delta: float) -> void:
	if battle_unit.attack_cd <= 0:
		battle_unit.perform_attack()
		
	# 确保单位面向目标
	if battle_unit.target_unit:
		var direction = battle_unit.target_unit.global_position - battle_unit.global_position
		_update_facing(direction)


func _cast_logic(_delta: float) -> void:
	# 类似攻击逻辑，但用于技能释放
	if battle_unit.target_unit:
		var direction = battle_unit.target_unit.global_position - battle_unit.global_position
		_update_facing(direction)


func _take_damage_logic(_delta: float) -> void:
	# 受伤动画播放完毕后会通过动画信号恢复状态
	pass


func _dead_logic(_delta: float) -> void:
	# 单位死亡，可能需要在动画结束后处理清理工作
	battle_unit.active = false


func _is_in_attack_range() -> bool:
	return battle_unit.is_in_attack_range()


func _is_in_cast_range() -> bool:
	return battle_unit.is_in_cast_range()
