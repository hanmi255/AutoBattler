@icon("res://assets/icons/hit_box_icon.svg")
class_name HitBox
extends Area2D

signal hit

@export var damage: int


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(hurt_box: Area2D) -> void:
	if not hurt_box is HurtBox:
		return

	hit.emit()
