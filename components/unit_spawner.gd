class_name UnitSpawner
extends Node

signal unit_spawned(unit: Unit)

const UNIT = preload("res://scenes/unit/unit.tscn")

@export var bench: PlayArea
@export var game_area: PlayArea


func _get_first_available_area() -> PlayArea:
	return bench if not bench.unit_grid.is_grid_full() else (game_area if not game_area.unit_grid.is_grid_full() else null)


func spawn_unit(unit: UnitStats) -> void:
	var area := _get_first_available_area()

	## TODO throw a popup error message if no area is available
	assert(area, "No area available to add unit")

	var unit_instance = UNIT.instantiate()
	var tile := area.unit_grid.get_first_empty_tile()
	area.unit_grid.add_child(unit_instance)
	area.unit_grid.add_unit_to_tile(unit_instance, tile)

	unit_instance.global_position = area.get_global_from_tile(tile) - Arena.HALF_CELL_SIZE
	unit_instance.stats = unit
	
	unit_spawned.emit(unit_instance)
