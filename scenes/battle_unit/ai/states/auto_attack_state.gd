class_name AutoAttackState
extends State

const ProjectileSpawner_PREFAB = preload("res://scripts/components/projectile_spawner.gd")

signal attack_completed
signal target_died
signal should_chase_new_target

var actor_unit: BattleUnit
var target: BattleUnit
var attack_timer: float = 0.0
var is_attacking: bool = false

func _init(new_actor: Node, current_target: BattleUnit) -> void:
	actor = new_actor
	target = current_target


func enter() -> void:
	actor_unit = actor as BattleUnit
	attack_timer = 0.0
	is_attacking = false

	# 连接目标死亡信号
	if target and is_instance_valid(target):
		target.stats.health_reached_zero.connect(_on_target_died, CONNECT_ONE_SHOT)


func exit() -> void:
	# 断开信号连接
	if target and is_instance_valid(target):
		if target.stats.health_reached_zero.is_connected(_on_target_died):
			target.stats.health_reached_zero.disconnect(_on_target_died)


func process(delta: float) -> void:
	# 检查actor_unit是否仍然有效
	if not actor_unit or not is_instance_valid(actor_unit):
		should_chase_new_target.emit()
		return

	if not target or not is_instance_valid(target):
		should_chase_new_target.emit()
		return

	# 检查目标是否还在攻击范围内
	var distance = actor_unit.global_position.distance_to(target.global_position)
	var attack_range = _get_attack_range()

	if distance > attack_range:
		should_chase_new_target.emit()
		return

	# 攻击计时器
	attack_timer += delta
	var time_between_attacks = actor_unit.stats.get_time_between_attacks()

	if attack_timer >= time_between_attacks and not is_attacking:
		_perform_attack()


func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return

	# 检查actor_unit是否仍然有效
	if not actor_unit or not is_instance_valid(actor_unit):
		should_chase_new_target.emit()
		return

	is_attacking = true
	attack_timer = 0.0

	# 面向目标
	_face_target()

	# 播放攻击动画
	if actor_unit.animation_player.has_animation("attack"):
		actor_unit.animation_player.play("attack")
		# 等待动画完成后执行伤害
		actor_unit.animation_player.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)
	else:
		# 如果没有攻击动画，直接执行伤害
		_deal_damage()


func _face_target() -> void:
	# 检查对象有效性
	if not actor_unit or not is_instance_valid(actor_unit) or not target or not is_instance_valid(target):
		return

	# 让单位面向目标
	var direction = target.global_position - actor_unit.global_position
	if direction.x < 0:
		actor_unit.skin.flip_h = true
	else:
		actor_unit.skin.flip_h = false


func _deal_damage() -> void:
	if not target or not is_instance_valid(target):
		is_attacking = false
		return

	# 检查actor_unit是否仍然有效
	if not actor_unit or not is_instance_valid(actor_unit):
		is_attacking = false
		should_chase_new_target.emit()
		return

	var damage = _calculate_damage()
	if damage <= 0:
		is_attacking = false
		return

	# 根据攻击类型处理伤害
	if actor_unit.stats.is_melee():
		_deal_melee_damage(damage)
	else:
		_deal_ranged_damage(damage)

	# 增加攻击者蓝量
	_add_mana_on_attack()

	is_attacking = false
	attack_completed.emit()


func _calculate_damage() -> int:
	# 检查actor_unit是否仍然有效
	if not actor_unit or not is_instance_valid(actor_unit) or not actor_unit.stats:
		print("Waning: actor_unit is invalid in _calculate_damage, returning 0 damage")
		return 0

	var base_damage = actor_unit.stats.get_attack_damage()

	# TODO: 添加暴击、特质加成等计算
	# var critical_chance = 0.25
	# var is_critical = randf() < critical_chance
	# if is_critical:
	#     base_damage *= 2

	return base_damage


func _deal_melee_damage(damage: int) -> void:
	# 近战攻击：激活HitBox一小段时间
	actor_unit.hit_box.damage = damage
	actor_unit.hit_box.visible = true
	actor_unit.hit_box.monitoring = true

	# 连接HitBox信号
	if not actor_unit.hit_box.hit.is_connected(_on_melee_hit):
		actor_unit.hit_box.hit.connect(_on_melee_hit, CONNECT_ONE_SHOT)

	# 短暂延迟后禁用HitBox
	actor_unit.get_tree().create_timer(0.1).timeout.connect(_disable_hit_box)


func _deal_ranged_damage(damage: int) -> void:
	# 远程攻击创建投射物
	var projectile_spawner = ProjectileSpawner_PREFAB.new()
	var projectile = projectile_spawner.spawn_projectile(actor_unit, target, damage)

	# 连接投射物信号
	projectile.hit_target.connect(_on_projectile_hit_target)
	projectile.missed.connect(_on_projectile_missed)


func _apply_damage_to_target(damage: int) -> void:
	if not target or not is_instance_valid(target):
		return

	# 检查actor_unit是否仍然有效
	if not actor_unit or not is_instance_valid(actor_unit):
		return

	# 计算护甲减免
	var final_damage = _calculate_armor_reduction(damage)

	# 调试输出
	print("%s attacks %s for %d damage (reduced from %d by armor)" % [
		actor_unit.stats.name, target.stats.name, final_damage, damage
	])

	# 应用伤害
	target.stats.health -= final_damage

	# 播放受击动画
	if target.animation_player.has_animation("take_damage"):
		target.animation_player.play("take_damage")

	# 给目标增加蓝量
	_add_mana_on_hurt(target, final_damage)


func _calculate_armor_reduction(damage: int) -> int:
	var armor = target.stats.armor
	var damage_reduction = armor / (armor + 100.0)
	var final_damage = damage * (1.0 - damage_reduction)
	return max(1, int(final_damage)) # 至少造成1点伤害


func _add_mana_on_attack() -> void:
	if not actor_unit or not is_instance_valid(actor_unit):
		return

	if actor_unit.stats.max_mana > 0:
		actor_unit.stats.mana += int(UnitStats.MANA_PER_ATTACK)


func _add_mana_on_hurt(hurt_unit: BattleUnit, damage: int) -> void:
	if hurt_unit.stats.max_mana > 0:
		# 受击获得的蓝量与受到的伤害成正比
		var mana_gain = damage * 0.5
		hurt_unit.stats.mana += int(mana_gain)


func _get_attack_range() -> float:
	# 攻击范围比检测范围稍小，避免单位在边缘来回切换状态
	return 35.0 # 与ChaseState中的ATTACK_RANGE保持一致


func _on_attack_animation_finished(_anim_name: String) -> void:
	_deal_damage()


func _on_target_died() -> void:
	target_died.emit()
	should_chase_new_target.emit()


func _on_projectile_hit_target(hit_target: BattleUnit) -> void:
	if hit_target == target:
		var damage = _calculate_damage()
		_apply_damage_to_target(damage)


func _on_projectile_missed() -> void:
	# 投射物未命中，继续攻击
	pass


func _on_melee_hit() -> void:
	# 检查actor_unit是否仍然有效
	if not actor_unit or not is_instance_valid(actor_unit):
		return

	# 近战攻击命中，直接造成伤害
	var damage = actor_unit.hit_box.damage
	_apply_damage_to_target(damage)


func _disable_hit_box() -> void:
	if actor_unit and is_instance_valid(actor_unit):
		actor_unit.hit_box.visible = false
		actor_unit.hit_box.monitoring = false
