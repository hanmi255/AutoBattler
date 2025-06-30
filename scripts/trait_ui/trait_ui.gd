class_name TraitUI
extends PanelContainer

@export var trait_data: Trait: set = _set_trait_data
@export var is_active: bool: set = _set_is_active


@onready var trait_icon: TextureRect = %TraitIcon
@onready var active_units_label: Label = %ActiveUnitsLabel
@onready var trait_level_labels: RichTextLabel = %TraitLevelLabels
@onready var trait_label: Label = %TraitLabel


func update(units: Array[Unit]) -> void:
	var unique_units := trait_data.get_unique_unit_count(units)
	active_units_label.text = str(unique_units)
	trait_level_labels.text = trait_data.get_levels_BBcode(unique_units)
	is_active = trait_data.is_active(unique_units)


func _set_trait_data(value: Trait) -> void:
	if value == null or not is_instance_valid(trait_label):
		return

	trait_data = value
	trait_icon.texture = trait_data.icon
	trait_label.text = trait_data.name


func _set_is_active(value: bool) -> void:
	is_active = value

	modulate.a = 1.0 if is_active else 0.5
