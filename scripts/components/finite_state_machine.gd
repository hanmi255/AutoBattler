class_name FiniteStateMachine
extends Node

@export var debug_label: Label

var state: State


func change_state(new_state: State) -> void:
	if state != null:
		state.exit()

	if new_state != null:
		debug_label.text = new_state.get_script().get_global_name()
		new_state.enter()

	state = new_state