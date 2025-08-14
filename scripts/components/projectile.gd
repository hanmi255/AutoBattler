class_name Projectile
extends Area2D

signal hit_target(target: BattleUnit)
signal missed

@export var speed: float = 200.0
@export var damage: int = 0
@export var max_distance: float = 300.0

var target: BattleUnit
var start_position: Vector2
var direction: Vector2
var traveled_distance: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	start_position = global_position


func setup(from_position: Vector2, target_unit: BattleUnit, projectile_damage: int) -> void:
	global_position = from_position
	target = target_unit
	damage = projectile_damage
	
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		# 旋转精灵以面向目标
		sprite.rotation = direction.angle()
	else:
		# 如果目标无效，直接销毁
		queue_free()


func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		missed.emit()
		queue_free()
		return
	
	# 更新方向以追踪移动的目标
	var target_direction = (target.global_position - global_position).normalized()
	direction = direction.lerp(target_direction, 0.1)  # 轻微的追踪效果
	
	# 移动投射物
	var movement = direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()
	
	# 检查是否超出最大距离
	if traveled_distance > max_distance:
		missed.emit()
		queue_free()
		return
	
	# 检查是否到达目标附近
	if global_position.distance_to(target.global_position) < 16.0:
		_hit_target()


func _on_area_entered(area: Area2D) -> void:
	# 检查是否击中目标的HurtBox
	if area is HurtBox and area.get_parent() == target:
		_hit_target()


func _hit_target() -> void:
	if target and is_instance_valid(target):
		hit_target.emit(target)
	queue_free()
