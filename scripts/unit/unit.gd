@tool
class_name Unit
extends Area2D

@export var stats: UnitStats: set = set_stats

@onready var skin: Sprite2D = $Visuals/Skin
@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var drag_and_drop: DragAndDrop = $DragAndDrop
@onready var velocity_based_rotation: VelocityBasedRotation = $VelocityBasedRotation
@onready var outline_highlighter: OutlineHighlighter = $OutlineHighlighter


func _ready() -> void:
	if not Engine.is_editor_hint():
		drag_and_drop.drag_started.connect(_on_drag_started)
		drag_and_drop.drag_canceled.connect(_on_drag_canceled)


func set_stats(value: UnitStats) -> void:
	stats = value
	
	if value == null:
		return
	
	if not is_node_ready():
		await ready

	skin.region_rect.position = Vector2(stats.skin_coordinates) * Arena.CELL_SIZE

# 取消拖拽时，需要重置位置
func reset_pos_after_dragging(start_pos: Vector2) -> void:
	velocity_based_rotation.enabled = false
	global_position = start_pos


func _on_drag_started() -> void:
	velocity_based_rotation.enabled = true


func _on_drag_canceled(start_pos: Vector2) -> void:
	reset_pos_after_dragging(start_pos)


func _on_mouse_entered() -> void:
	if drag_and_drop.dragging:
		return
	
	outline_highlighter.highlight()
	z_index = 1


func _on_mouse_exited() -> void:
	if drag_and_drop.dragging:
		return
	
	outline_highlighter.clear_highlight()
	z_index = 0
