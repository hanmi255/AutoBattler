class_name BattleUnit
extends Area2D

@export var stats: UnitStats: set = set_stats

@onready var skin: PackedSprite2D = $Skin
@onready var detect_range: Area2D = $DetectRange
@onready var hurt_box: Area2D = $HurtBox
@onready var health_bar := $HealthBar
@onready var mana_bar := $ManaBar
@onready var tier_icon: TierIcon = $TierIcon
@onready var target_finder: Node = $TargetFinder
@onready var unit_ai: Node = $UnitAI
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)


func set_stats(value: UnitStats) -> void:
	if value == null or not is_instance_valid(tier_icon):
		return

	stats = value

	stats = value.duplicate()
	collision_layer = stats.team + 1
	hurt_box.collision_layer = stats.team + 1
	hurt_box.collision_mask = 2 - stats.team

	skin.texture = UnitStats.TEAM_SPRITE_SHEET[stats.team]
	skin.coordinates = stats.skin_coordinates
	skin.flip_h = stats.team == stats.Team.PLAYER
	detect_range.stats = stats
	health_bar.stats = stats
	mana_bar.stats = stats
	tier_icon.stats = stats

	stats.health_reached_zero.connect(queue_free)


func _on_hurt(damage: int) -> void:
	stats.health -= damage
