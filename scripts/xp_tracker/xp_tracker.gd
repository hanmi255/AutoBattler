class_name XPTracker
extends VBoxContainer

@export var player_stats: PlayerStats

@onready var xp_progress: ProgressBar = $XPProgress
@onready var xp_label: Label = %XPLabel
@onready var level_label: Label = %LevelLabel


func _ready() -> void:
	player_stats.changed.connect(_on_player_stats_changed)
	_on_player_stats_changed()


func _on_player_stats_changed() -> void:
	if player_stats.level < 10:
		_set_xp_progress_value()
	else:
		_set_max_level_value()

	level_label.text = "Lv: %s" % player_stats.level


func _set_xp_progress_value() -> void:
	var xp_requirement:= player_stats.get_current_xp_requirement()
	xp_label.text = "%s/%s" % [player_stats.xp, xp_requirement]
	xp_progress.value = (player_stats.xp / float(xp_requirement)) * 100


func _set_max_level_value() -> void:
	xp_progress.value = 100
	xp_label.text = "Max Level"
