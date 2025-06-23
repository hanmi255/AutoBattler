@tool
class_name Unit
extends Area2D

@export var stats: UnitsStats: set = set_stats

@onready var skin: Sprite2D = $Skin
@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar

func set_stats(value: UnitsStats) -> void:
    if value == null:
        return
    stats = value

    if not is_node_ready():
        await ready
    
    skin.region_rect.position = Vector2(stats.skin_coordinates) * Arena.CELL_SIZE