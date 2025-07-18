class_name UnitCombiner
extends Node

@export var buffer_timer: Timer
@export var combine_sound: AudioStream

var queued_updates := 0
var tween: Tween


func _ready() -> void:
	buffer_timer.timeout.connect(_on_buffer_timer_timeout)


func queue_unit_combiner_update() -> void:
	buffer_timer.start()


func _update_unit_combinations(tier: int) -> void:
	var groups := _group_units_in_tier_by_name(tier)
	var triplets: Array[Array] = _get_triplets_for_groups(groups)

	## 没有可以合并的单元就直接返回
	if triplets.is_empty():
		_on_units_combined(tier)
		return

	tween = create_tween()

	for combination in triplets:
		tween.tween_callback(_combine_units.bind(combination[0], combination[1], combination[2]))
		tween.tween_interval(UnitAnim.COMBINE_ANIM_LENGTH)

	tween.finished.connect(_on_units_combined.bind(tier), CONNECT_ONE_SHOT)


func _combine_units(unit1: Unit, unit2: Unit, unit3: Unit):
	unit1.stats.tier += 1
	unit2.remove_from_group("units")
	unit3.remove_from_group("units")
	unit2.anim.play_combine_anim(unit1.global_position + Arena.QUARTER_CELL_SIZE)
	unit3.anim.play_combine_anim(unit1.global_position + Arena.QUARTER_CELL_SIZE)
	SFXPlayer.play(combine_sound)


"""
返回一个由名字和等级筛选的单元组字典

参数:
    tier (int): 要筛选的单元等级

返回值:
    Dictionary: 键为单元名称(String)，值为对应等级的单元实例列表(Array[Unit])
        示例: {"Archer": [unit1, unit2, unit3]}

功能流程说明:
1. 获取场景树中所有"units"组的单元
2. 过滤出指定tier的单元
3. 按单元名称进行分组
"""
func _group_units_in_tier_by_name(tier: int) -> Dictionary:
	var units := get_tree().get_nodes_in_group("units")
	var filtered_units := units.filter(
		func(unit: Unit):
			return unit.stats.tier == tier
	)

	var unit_groups := {}

	for unit: Unit in filtered_units:
		if unit_groups.has(unit.stats.name):
			unit_groups[unit.stats.name].append(unit)
		else:
			unit_groups[unit.stats.name] = [unit]

	return unit_groups


"""
将单位组拆分为三元组组合

参数:
    unit_groups (Dictionary): 单位名称到单位实例数组的映射字典
        示例: {"Archer": [unit1, unit2, unit3, unit4]}

返回值:
    Array[Array]: 二维数组，每个子数组包含3个单位组成的组合
        示例: [[unit1, unit2, unit3], [unit4]]（当数量不足3个时保留单个）
"""
func _get_triplets_for_groups(unit_groups: Dictionary) -> Array[Array]:
	var triplets: Array[Array] = []

	for unit_name in unit_groups:
		# 遍历每个单位类型及其对应的单位列表
		var current_units: Array = unit_groups[unit_name]
		while current_units.size() >= 3:
			# 每次提取前3个单位组成组合
			var combination := [current_units[0], current_units[1], current_units[2]]
			triplets.append(combination)
			current_units = current_units.slice(3)

	return triplets


func _on_buffer_timer_timeout() -> void:
	queued_updates += 1

	if not tween or not tween.is_running():
		_update_unit_combinations(1)


func _on_units_combined(tier: int) -> void:
	if tier == 1:
		_update_unit_combinations(2)
	else:
		queued_updates -= 1

		if queued_updates >= 1:
			_update_unit_combinations(1)
