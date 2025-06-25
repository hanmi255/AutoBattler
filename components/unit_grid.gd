class_name UnitGrid
extends Node2D

signal unit_grid_changed

# NOTE: x为列，y为行
@export var size: Vector2

var units: Dictionary

func _ready():
	for i in int(size.x):
		for j in int(size.y):
			units[Vector2i(i, j)] = null


func add_unit(tile: Vector2i, unit: Node) -> void:
	units[tile] = unit
	unit_grid_changed.emit()


func is_tile_occupied(tile: Vector2i) -> bool:
	return units.has(tile)


func is_grid_full() -> bool:
	return units.keys().all(is_tile_occupied)


func get_first_empty_tile() -> Vector2i:
	for tile in units.keys():
		if not is_tile_occupied(tile):
			return tile

	# 没有空闲瓦片
	return Vector2i(-1, -1)


func get_all_units() -> Array[Unit]:
	var units_array: Array[Unit] = []

	for unit in units.values():
		if unit != null:
			units_array.append(unit)

	return units_array
