class_name UnitMover
extends Node

@export var play_areas: Array[PlayArea]

func _ready():
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		setup_unit(unit)


func setup_unit(unit: Unit):
	unit.drag_and_drop.drag_started.connect(_on_unit_drag_started.bind(unit))
	unit.drag_and_drop.drag_canceled.connect(_on_unit_drag_canceled.bind(unit))
	unit.drag_and_drop.dropped.connect(_on_unit_dropped.bind(unit))


func _set_highlight(value: bool) -> void:
	for play_area: PlayArea in play_areas:
		play_area.tile_highlighter.enabled = value


func _get_play_area_for_pos(global: Vector2) -> int:
	var dropped_area_index = -1

	for i in play_areas.size():
		var tile = play_areas[i].get_tile_from_global(global)
		if play_areas[i].is_tile_in_bounds(tile):
			dropped_area_index = i
			break

	return dropped_area_index


func _reset_unit_to_start_pos(unit: Unit, start_pos: Vector2):
	var i := _get_play_area_for_pos(start_pos)
	var tile := play_areas[i].get_tile_from_global(start_pos)

	unit.reset_pos_after_dragging(start_pos)
	play_areas[i].unit_grid.add_unit_to_tile(unit, tile)


func _move_unit(unit: Unit, play_area: PlayArea, tile: Vector2i):
	play_area.unit_grid.add_unit_to_tile(unit, tile)
	
	# 减去0.5像素大小，使得单元格中心与格子中心重合
	unit.global_position = play_area.get_global_from_tile(tile) - Arena.HALF_CELL_SIZE
	unit.reparent(play_area.unit_grid)


func _on_unit_drag_started(unit: Unit):
	_set_highlight(true)

	var i := _get_play_area_for_pos(unit.global_position)
	if i > -1:
		var tile := play_areas[i].get_tile_from_global(unit.global_position)
		play_areas[i].unit_grid.remove_unit_from_tile(tile)


func _on_unit_drag_canceled(start_pos: Vector2, unit: Unit) -> void:
	_set_highlight(false)
	_reset_unit_to_start_pos(unit, start_pos)


func _on_unit_dropped(start_pos: Vector2, unit: Unit) -> void:
	_set_highlight(false)

	var old_area_index := _get_play_area_for_pos(start_pos)
	var new_area_index := _get_play_area_for_pos(unit.get_global_mouse_position())

	# 拖拽到非游戏区域时恢复原位置
	if new_area_index == -1:
		_reset_unit_to_start_pos(unit, start_pos)
		return

	var old_area := play_areas[old_area_index]
	var old_tile := old_area.get_tile_from_global(start_pos)
	var new_area := play_areas[new_area_index]
	var new_tile := new_area.get_hovered_tile()

	# 拖拽到非空闲网格时交换位置
	if new_area.unit_grid.is_tile_occupied(new_tile):
		var old_unit: Unit = new_area.unit_grid.units[new_tile]
		new_area.unit_grid.remove_unit_from_tile(new_tile)
		_move_unit(old_unit, old_area, old_tile)

	# 否则移动单元
	_move_unit(unit, new_area, new_tile)
