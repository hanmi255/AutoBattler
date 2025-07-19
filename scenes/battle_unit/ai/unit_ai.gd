class_name UnitAI
extends Node

@export var enabled: bool: set = _set_enabled
@export var actor: BattleUnit
@export var debug_label: Label

var fsm: FiniteStateMachine

func _ready() -> void:
	fsm = FiniteStateMachine.new()
	fsm.state_changed.connect(
		func(new_state: State):
			if not debug_label:
				return
			debug_label.text = new_state.get_script().get_global_name()
	)


func _physics_process(delta: float) -> void:
	if not enabled or not actor or not is_instance_valid(actor):
		return

	if not fsm or not fsm.state:
		return

	fsm.state.physics_process(delta)


func _process(delta: float) -> void:
	if not enabled or not actor or not is_instance_valid(actor):
		return

	if not fsm or not fsm.state:
		return

	fsm.state.process(delta)


func _set_enabled(value: bool) -> void:
	enabled = value

	if enabled:
		# 检查actor是否仍然有效
		if not actor or not is_instance_valid(actor):
			enabled = false
			return
		_start_chasing()
	else:
		# 清理当前状态
		if fsm and fsm.state:
			fsm.change_state(null)


func _start_chasing() -> void:
	var chase_state := ChaseState.new(actor)
	chase_state.stuck.connect(_on_chase_state_stuck, CONNECT_ONE_SHOT)
	chase_state.target_reached.connect(_on_chase_state_target_reached, CONNECT_ONE_SHOT)
	fsm.change_state(chase_state)

	chase_state.chase()


func _on_chase_state_stuck() -> void:
	var stuck_state := StuckState.new(actor)
	stuck_state.time_out.connect(_start_chasing, CONNECT_ONE_SHOT)
	fsm.change_state(stuck_state)


func _on_chase_state_target_reached(target: BattleUnit) -> void:
	var auto_attack_state := AutoAttackState.new(actor, target)
	auto_attack_state.should_chase_new_target.connect(_start_chasing, CONNECT_ONE_SHOT)
	auto_attack_state.target_died.connect(_start_chasing, CONNECT_ONE_SHOT)
	fsm.change_state(auto_attack_state)
