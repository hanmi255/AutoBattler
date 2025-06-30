class_name UnitSpawner
extends Node

signal unit_spawned(unit: Unit)

@export var bench: PlayArea
@export var game_area: PlayArea

@onready var unit_spawner: SceneSpawner = $SceneSpawner


func _get_first_available_area() -> PlayArea:
	return bench if not bench.unit_grid.is_grid_full() else (game_area if not game_area.unit_grid.is_grid_full() else null)


func spawn_unit(unit: UnitStats) -> void:
	var area := _get_first_available_area()

	## TODO throw a popup error message if no area is available
	assert(area, "No area available to add unit")

	var new_unit := unit_spawner.spawn_scene(area.unit_grid) as Unit
	var tile := area.unit_grid.get_first_empty_tile()
	area.unit_grid.add_unit_to_tile(new_unit, tile)

	new_unit.global_position = area.get_global_from_tile(tile) - Arena.HALF_CELL_SIZE
	new_unit.stats = unit
	
	unit_spawned.emit(new_unit)
