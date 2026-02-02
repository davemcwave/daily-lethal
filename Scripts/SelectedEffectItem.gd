extends Panel
class_name SelectedEffectItem

signal move_up_pressed(item: SelectedEffectItem)
signal move_down_pressed(item: SelectedEffectItem)
signal remove_pressed(item: SelectedEffectItem)
signal selected(item: SelectedEffectItem)

var card_effect: CardEffect = null
var effect_data: Dictionary = {}

@onready var label: RichTextLabel = $HBoxContainer/Label
@onready var move_up_button: Button = $HBoxContainer/MoveUpButton
@onready var move_down_button: Button = $HBoxContainer/MoveDownButton
@onready var remove_button: Button = $HBoxContainer/RemoveButton

func _ready() -> void:
	move_up_button.connect("pressed", _on_move_up_pressed)
	move_down_button.connect("pressed", _on_move_down_pressed)
	remove_button.connect("pressed", _on_remove_pressed)
	connect("gui_input", _on_gui_input)

func set_effect(effect: CardEffect, data: Dictionary = {}) -> void:
	card_effect = effect
	effect_data = data
	label.set_text("[b]%s[/b]" % effect.get_effect_name())

func get_effect() -> CardEffect:
	return card_effect

func get_effect_data() -> Dictionary:
	return effect_data

func set_effect_data(data: Dictionary) -> void:
	effect_data = data

func highlight() -> void:
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func unhighlight() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_move_up_pressed() -> void:
	emit_signal("move_up_pressed", self)

func _on_move_down_pressed() -> void:
	emit_signal("move_down_pressed", self)

func _on_remove_pressed() -> void:
	emit_signal("remove_pressed", self)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("selected", self)
