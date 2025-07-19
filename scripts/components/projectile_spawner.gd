class_name ProjectileSpawner
extends Node

const PROJECTILE_SCENE = preload("res://scenes/projectile/projectile.tscn")

@export var spawn_offset: Vector2 = Vector2(0, -8)  # 投射物生成偏移


func spawn_projectile(from_unit: BattleUnit, target_unit: BattleUnit, damage: int) -> Projectile:
	var projectile = PROJECTILE_SCENE.instantiate() as Projectile
	
	# 将投射物添加到场景树中
	var battle_scene = from_unit.get_tree().current_scene
	battle_scene.add_child(projectile)
	
	# 设置投射物参数
	var spawn_position = from_unit.global_position + spawn_offset
	projectile.setup(spawn_position, target_unit, damage)
	
	return projectile
