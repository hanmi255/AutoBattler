class_name FiniteStateMachine
extends Node

signal state_changed(new_state: State)

var state: State


func change_state(new_state: State) -> void:
	if state != null:
		state.exit()

	if new_state != null:
		new_state.enter()

	state = new_state
	state_changed.emit(state)