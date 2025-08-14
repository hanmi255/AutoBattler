class_name UnitGrid
extends Node2D

signal unit_grid_changed

## NOTE: x为列，y为行
@export var size: Vector2

var units: Dictionary


func _ready():
	for i in int(size.x):
		for j in int(size.y):
			units[Vector2i(i, j)] = null


func add_unit_to_tile(unit: Node, tile: Vector2i) -> void:
	units[tile] = unit

	# 首先清理任何现有的连接到_on_unit_tree_exited的信号
	_cleanup_unit_signal_connections(unit)

	# 然后连接新的信号
	unit.tree_exited.connect(_on_unit_tree_exited.bind(unit, tile))

	unit_grid_changed.emit()


func remove_unit_from_tile(tile: Vector2i) -> void:
	var unit := units[tile] as Node
	if not unit:
		return

	# 清理信号连接
	_cleanup_unit_signal_connections(unit)

	units[tile] = null
	unit_grid_changed.emit()


func _cleanup_unit_signal_connections(unit: Node) -> void:
	if not unit or not is_instance_valid(unit):
		return

	# 获取所有连接并断开与_on_unit_tree_exited相关的连接
	var connections = unit.tree_exited.get_connections()
	for connection in connections:
		if connection.callable.get_method() == "_on_unit_tree_exited":
			unit.tree_exited.disconnect(connection.callable)


func is_tile_occupied(tile: Vector2i) -> bool:
	return units[tile] != null


func is_grid_full() -> bool:
	return units.keys().all(is_tile_occupied)


func get_first_empty_tile() -> Vector2i:
	for tile in units.keys():
		if not is_tile_occupied(tile):
			return tile

	## 没有空闲瓦片
	return Vector2i(-1, -1)


func get_all_units() -> Array[Unit]:
	var units_array: Array[Unit] = []

	for unit in units.values():
		if unit != null:
			units_array.append(unit)

	return units_array


func get_all_occupied_tiles() -> Array[Vector2i]:
	var tile_array: Array[Vector2i] = []

	for tile: Vector2i in units.keys():
		if units[tile]:
			tile_array.append(tile)

	return tile_array


func _on_unit_tree_exited(unit: Node, tile: Vector2i) -> void:
	# 检查单位是否仍然有效，避免访问已释放的对象
	if not unit or not is_instance_valid(unit):
		# 如果单位已经无效，直接清理网格
		units[tile] = null
		unit_grid_changed.emit()
		return

	if unit.is_queued_for_deletion():
		units[tile] = null
		unit_grid_changed.emit()
