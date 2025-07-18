class_name UnitCard
extends Button

signal unit_bought(unit: UnitStats)

const HOVER_BORDER_COLOR := Color("fafa82")

@export var player_stats: PlayerStats
@export var unit_stats: UnitStats: set = _set_unit_stats
@export var buy_card_sound: AudioStream

@onready var traits_label: Label = %TraitsLabel
@onready var bottom_panel: Panel = $BottomPanel
@onready var unit_name_label: Label = %UnitNameLabel
@onready var gold_cost_label: Label = %GoldCostLabel
@onready var border_panel: Panel = $BorderPanel
@onready var unit_icon: TextureRect = $UnitIcon
@onready var empty_placeholder: Panel = $EmptyPlaceholder
@onready var bottom_sb: StyleBoxFlat = bottom_panel.get_theme_stylebox("panel")
@onready var border_sb: StyleBoxFlat = border_panel.get_theme_stylebox("panel")

var bought := false
var border_color: Color


func _ready() -> void:
	player_stats.changed.connect(_on_player_stats_changed)
	_on_player_stats_changed()


func _on_player_stats_changed() -> void:
	if not unit_stats:
		return

	var has_enough_gold := player_stats.gold >= unit_stats.gold_cost
	disabled = not has_enough_gold

	## 可以购买或者已经购买(显示空白占用格)时设置不透明
	if has_enough_gold or bought:
		modulate = Color(Color.WHITE, 1.0)
	## 否则设置半透明表示不可点击
	else:
		modulate = Color(Color.WHITE, 0.5)


func _set_unit_stats(value: UnitStats) -> void:
	unit_stats = value
	
	if not is_instance_valid(empty_placeholder):
		return

	if not unit_stats:
		empty_placeholder.show()
		disabled = true
		bought = true
		return

	border_color = UnitStats.RARITY_COLORS[unit_stats.rarity]
	border_sb.border_color = border_color
	bottom_sb.bg_color = border_color
	traits_label.text = "\n".join(Trait.get_trait_names(unit_stats.traits))
	unit_name_label.text = unit_stats.name
	gold_cost_label.text = str(unit_stats.gold_cost)
	unit_icon.texture.region.position = Vector2(unit_stats.skin_coordinates) * Arena.CELL_SIZE


func _on_pressed() -> void:
	if bought:
		return

	## 购买后显示空白占用格
	bought = true
	empty_placeholder.show()
	player_stats.gold -= unit_stats.gold_cost
	unit_bought.emit(unit_stats)
	SFXPlayer.play(buy_card_sound)


func _on_mouse_entered() -> void:
	if not disabled:
		border_sb.border_color = HOVER_BORDER_COLOR

func _on_mouse_exited() -> void:
	border_sb.border_color = border_color
