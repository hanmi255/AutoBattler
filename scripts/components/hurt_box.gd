@icon("res://assets/icons/hurt_box_icon.svg")
class_name HurtBox
extends Area2D

signal hurt(damage: int)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(hit_box: Area2D) -> void:
	if not hit_box is HitBox:
		return

	hurt.emit((hit_box as HitBox).damage)
