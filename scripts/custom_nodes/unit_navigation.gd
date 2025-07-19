extends Node

signal path_calculated(points: Array[Vector2i], moving_unit: BattleUnit)
signal chase_deadlock_detected(moving_unit: BattleUnit, target_unit: BattleUnit)

const DEADLOCK_DETECTION_HISTORY := 4 # 用于检测死锁的位置历史记录数量

var battle_grid: UnitGrid
var game_area: PlayArea
var astar_grid: AStarGrid2D
var full_grid_region: Rect2i

# 用于跟踪每个单位的位置历史，防止追逐死锁
var unit_position_history: Dictionary = {}


func initialize(grid: UnitGrid, area: PlayArea) -> void:
	battle_grid = grid
	game_area = area
	
	full_grid_region = Rect2i(Vector2i.ZERO, battle_grid.size)
	astar_grid = AStarGrid2D.new()
	astar_grid.region = full_grid_region
	astar_grid.cell_size = Arena.CELL_SIZE
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # 禁用斜向移动，单位只能上下左右移动
	astar_grid.update()
	battle_grid.unit_grid_changed.connect(update_occupied_tiles)


func update_occupied_tiles() -> void:
	astar_grid.fill_solid_region(full_grid_region, false)
	for id: Vector2i in battle_grid.get_all_occupied_tiles():
		astar_grid.set_point_solid(id)


# 当单位死亡或离开战场时调用
func clear_unit_history(unit: BattleUnit) -> void:
	var unit_id = unit.get_instance_id()
	if unit_id in unit_position_history:
		unit_position_history.erase(unit_id)


func get_next_position(moving_unit: BattleUnit, target_unit: BattleUnit) -> Vector2:
	var unit_tile := game_area.get_tile_from_global(moving_unit.global_position)
	var target_tile := game_area.get_tile_from_global(target_unit.global_position)

	# 更新单位位置历史
	_update_unit_position_history(moving_unit, unit_tile)

	# 检测追逐死锁
	if _is_unit_in_chase_deadlock(moving_unit):
		# 尝试使用替代路径解决死锁
		var alternative_position = _get_alternative_position(moving_unit, target_unit)
		if alternative_position != Vector2(-1, -1):
			print("deadlock alternative position")
			return alternative_position
		else:
			# 无法找到替代路径，发出死锁信号
			chase_deadlock_detected.emit(moving_unit, target_unit)
			return Vector2(-1, -1)

	# 确保网格状态是最新的（防止竞态条件）
	update_occupied_tiles()

	# 第1步：临时将单位当前位置设为可通行，以便计算从当前位置出发的路径
	astar_grid.set_point_solid(unit_tile, false)
	var path := astar_grid.get_id_path(unit_tile, target_tile, true)
	path_calculated.emit(path, moving_unit)

	# 第2步：当无法移动（没有可到达的相邻格子）时，保持在原位并恢复该位置为不可通行
	if path.size() == 1 and path[0] == unit_tile:
		astar_grid.set_point_solid(unit_tile, true)
		return Vector2(-1, -1) # 返回无效坐标表示无法移动

	# 第3步：有有效路径时，确保只移动到相邻的格子
	var next_tile := path[1] # 路径的第二个点是下一步要走的位置

	# 验证下一步是否是相邻的格子（只允许上下左右移动）
	var distance = unit_tile.distance_to(next_tile)
	if distance > 1.0:
		print("Warning: A* path contains non-adjacent step from %s to %s (distance: %f)" % [unit_tile, next_tile, distance])
		# 如果不是相邻格子，找到路径中第一个相邻的格子
		next_tile = _find_first_adjacent_tile_in_path(unit_tile, path)
		if next_tile == Vector2i(-1, -1):
			# 如果路径中没有相邻的格子，恢复原位置并返回无效坐标
			astar_grid.set_point_solid(unit_tile, true)
			return Vector2(-1, -1)

	battle_grid.remove_unit_from_tile(unit_tile)
	battle_grid.add_unit_to_tile(moving_unit, next_tile)
	astar_grid.set_point_solid(next_tile, true)

	return game_area.get_global_from_tile(next_tile) # 返回世界坐标供单位移动使用


func _update_unit_position_history(unit: BattleUnit, current_tile: Vector2i) -> void:
	var unit_id = unit.get_instance_id()

	if unit_id not in unit_position_history:
		unit_position_history[unit_id] = []

	var history = unit_position_history[unit_id] as Array[Vector2i]
	history.append(current_tile)

	# 保持历史记录在指定长度内
	if history.size() > DEADLOCK_DETECTION_HISTORY:
		history.pop_front()


func _is_unit_in_chase_deadlock(unit: BattleUnit) -> bool:
	var unit_id = unit.get_instance_id()

	if unit_id not in unit_position_history:
		return false

	var history = unit_position_history[unit_id] as Array[Vector2i]

	# 需要足够的历史记录才能检测死锁
	if history.size() < DEADLOCK_DETECTION_HISTORY:
		return false

	# 检查是否在最近几步中重复访问相同的位置
	var unique_positions = {}

	for pos in history:
		if pos in unique_positions:
			unique_positions[pos] += 1
		else:
			unique_positions[pos] = 1

	# 如果有位置被访问超过一次，说明可能陷入循环
	for count in unique_positions.values():
		if count > 1:
			return true

	return false


func _get_alternative_position(moving_unit: BattleUnit, target_unit: BattleUnit) -> Vector2:
	var unit_tile := game_area.get_tile_from_global(moving_unit.global_position)
	var target_tile := game_area.get_tile_from_global(target_unit.global_position)

	# 获取目标周围的相邻位置
	var adjacent_positions = _get_adjacent_positions(target_tile)

	# 找到最近的可到达的相邻位置
	var best_tile = Vector2i(-1, -1)
	var shortest_distance = INF

	for adj_tile in adjacent_positions:
		if battle_grid.is_tile_occupied(adj_tile):
			continue

		var distance = unit_tile.distance_to(adj_tile)
		if distance < shortest_distance:
			shortest_distance = distance
			best_tile = adj_tile

	# 如果找到了合适的位置，执行移动
	if best_tile != Vector2i(-1, -1):
		battle_grid.remove_unit_from_tile(unit_tile)
		battle_grid.add_unit_to_tile(moving_unit, best_tile)
		astar_grid.set_point_solid(best_tile, true)
		return game_area.get_global_from_tile(best_tile)

	return Vector2(-1, -1)


func _get_adjacent_positions(center: Vector2i) -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	for direction in directions:
		var adj_pos = center + direction
		# 检查是否在网格边界内
		if game_area.is_tile_in_bounds(adj_pos):
			adjacent.append(adj_pos)

	return adjacent


func _find_first_adjacent_tile_in_path(current_tile: Vector2i, path: Array[Vector2i]) -> Vector2i:
	for i in range(1, path.size()):
		var tile = path[i]
		var distance = current_tile.distance_to(tile)
		if distance <= 1.0:
			# 确保是真正的相邻格子（上下左右，不包括对角线）
			var diff = tile - current_tile
			if abs(diff.x) + abs(diff.y) == 1:
				return tile

	return Vector2i(-1, -1) # 没有找到相邻的格子
