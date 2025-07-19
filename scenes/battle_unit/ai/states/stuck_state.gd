class_name StuckState
extends State

signal time_out

const STUCK_WAIT_TIME := 0.5

var elapsed := 0.0


func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= STUCK_WAIT_TIME:
		time_out.emit()
		elapsed = 0.0