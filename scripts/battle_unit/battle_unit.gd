class_name BattleUnit
extends Area2D

@export var stats: UnitStats: set = set_stats
@export var move_speed: float = 30.0

@onready var skin: PackedSprite2D = $Skin
@onready var health_bar := $HealthBar
@onready var mana_bar := $ManaBar
@onready var tier_icon: TierIcon = $TierIcon
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var unit_state_machine: UnitStateMachine = $UnitStateMachine

var current_path: Array[Vector2] = []
var target_position: Vector2 = Vector2.ZERO
var target_unit: BattleUnit = null
var attack_cd: float = 0.0
var attack_range: float = 60.0
var cast_range: float = 150.0
var current_health: float = 0.0
var current_mana: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	health_bar.max_value = stats.max_health
	mana_bar.max_value = stats.max_mana

	if stats:
		current_health = stats.max_health
		current_mana = stats.max_mana
		health_bar.value = current_health
		mana_bar.value = current_mana

	call_deferred("find_target")


func _process(delta: float) -> void:
	if attack_cd > 0:
		attack_cd -= delta


func set_stats(value: UnitStats) -> void:
	if value == null or not is_instance_valid(tier_icon):
		return

	stats = value

	stats = value.duplicate()
	collision_layer = stats.team + 1
	
	skin.texture = UnitStats.TEAM_SPRITE_SHEET[stats.team]
	skin.coordinates = stats.skin_coordinates
	skin.flip_h = stats.team == stats.Team.PLAYER
	tier_icon.stats = stats


func find_target() -> void:
	# 确保有效的单位和团队
	if not stats or is_dead:
		return

	var target_group = "enemy_units" if stats.team == UnitStats.Team.PLAYER else "player_units"
	var potential_targets = get_tree().get_nodes_in_group(target_group)

	if potential_targets.size() > 0:
		# 寻找最近的目标
		var closest_distance = INF
		var closest_target = null

		for potential_target in potential_targets:
			if potential_target.is_dead:
				continue

			var distance = global_position.distance_to(potential_target.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_target = potential_target

		if closest_target:
			target_unit = closest_target

	# 如果没有找到目标，每隔一段时间重试
	if not target_unit:
		await get_tree().create_timer(1.0).timeout
		find_target()


func move_to_target() -> void:
	if target_unit:
		target_position = UnitNavigation.get_next_position(self, target_unit)
		if target_position != Vector2(-1, -1):
			current_path = [global_position, target_position]
		else:
			current_path = []


func is_in_attack_range() -> bool:
	if not target_unit:
		return false
	return global_position.distance_to(target_unit.global_position) <= attack_range


func is_in_cast_range() -> bool:
	if not target_unit:
		return false
	return global_position.distance_to(target_unit.global_position) <= cast_range


func take_damage(damage: float) -> void:
	if is_dead:
		return

	current_health -= damage
	health_bar.value = current_health
	
	if current_health <= 0:
		is_dead = true
		unit_state_machine.change_state(UnitStateMachine.BattleUnitStates.DEAD)
	else:
		unit_state_machine.change_state(UnitStateMachine.BattleUnitStates.TAKE_DAMAGE)


func perform_attack() -> void:
	if target_unit and not target_unit.is_dead:
		target_unit.take_damage(stats.attack_damage)
	attack_cd = stats.attack_cd
