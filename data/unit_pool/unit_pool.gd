class_name UnitPool
extends Resource

@export var available_units: Array[UnitStats]

var unit_pool: Array[UnitStats]


func generate_unit_pool() -> void:
	unit_pool = []

	for unit: UnitStats in available_units:
		for i in unit.pool_count:
			unit_pool.append(unit)


func get_random_unit_by_rarity(rarity: UnitStats.Rarity) -> UnitStats:
	var units := unit_pool.filter(
		func(unit: UnitStats) -> bool:
			return unit.rarity == rarity
	)

	if units.is_empty():
		return null

	var picked_random_unit: UnitStats = units.pick_random()
	unit_pool.erase(picked_random_unit)
	return picked_random_unit


func add_unit_to_pool(unit: UnitStats) -> void:
	## 将高阶单位分解为低阶单位再添加到池中
	var combined_count = unit.get_combined_unit_count()
	unit = unit.duplicate()
	unit.tier = 1

	for i in combined_count:
		unit_pool.append(unit)