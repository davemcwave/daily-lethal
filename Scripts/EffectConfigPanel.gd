extends Panel
class_name EffectConfigPanel

@onready var title_label: RichTextLabel = $TitleLabel
@onready var close_button: Button = $CloseButton
@onready var config_container: VBoxContainer = $ScrollContainer/VBoxContainer

var current_item: SelectedEffectItem = null

signal config_value_changed()

func _ready() -> void:
	close_button.connect("pressed", _on_close_button_pressed)

func _on_close_button_pressed() -> void:
	hide_config()

func show_config_for_effect(item: SelectedEffectItem) -> void:
	current_item = item
	clear_config()

	var effect: CardEffect = item.get_effect()
	var effect_data: Dictionary = item.get_effect_data()

	# Set panel title
	title_label.text = "[center][b]Configure: %s[/b][/center]" % effect.get_effect_name()

	# Add effect name label
	var effect_title_label = RichTextLabel.new()
	effect_title_label.bbcode_enabled = true
	effect_title_label.text = "[center][b]%s[/b][/center]" % effect.get_effect_name()
	effect_title_label.fit_content = true
	effect_title_label.scroll_active = false
	effect_title_label.custom_minimum_size = Vector2(0, 30)
	config_container.add_child(effect_title_label)

	# Check if this effect has a template
	if item.has_meta("template"):
		var template: EffectTemplate = item.get_meta("template")
		create_template_config_fields(template, effect_data)
	else:
		# Fall back to auto-generating from exported properties
		var property_list = effect.get_property_list()
		for property in property_list:
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_EDITOR:
				create_config_field(property, effect, effect_data)

	# Show the panel
	visible = true

func clear_config() -> void:
	for child in config_container.get_children():
		child.queue_free()

func hide_config() -> void:
	clear_config()
	visible = false
	current_item = null

func create_template_config_fields(template: EffectTemplate, effect_data: Dictionary) -> void:
	"""Create UI fields based on template parameters"""
	for param in template.get_parameters():
		# Add label
		var label = Label.new()
		label.text = param.display_name + ":"
		config_container.add_child(label)

		# Add description if available
		if not param.description.is_empty():
			var desc_label = Label.new()
			desc_label.text = param.description
			desc_label.add_theme_font_size_override("font_size", 10)
			desc_label.modulate = Color(0.7, 0.7, 0.7)
			config_container.add_child(desc_label)

		# Create UI control based on parameter type
		match param.parameter_type:
			EffectParameter.ParameterType.INT:
				var spinbox = SpinBox.new()
				spinbox.min_value = param.min_value
				spinbox.max_value = param.max_value
				spinbox.step = param.step
				var value = effect_data.get(param.parameter_name, param.default_value)
				spinbox.value = value if value != null else param.default_value
				spinbox.connect("value_changed", _on_template_value_changed.bind(param.parameter_name))
				config_container.add_child(spinbox)

			EffectParameter.ParameterType.FLOAT:
				var spinbox = SpinBox.new()
				spinbox.min_value = param.min_value
				spinbox.max_value = param.max_value
				spinbox.step = param.step
				var value = effect_data.get(param.parameter_name, param.default_value)
				spinbox.value = value if value != null else param.default_value
				spinbox.connect("value_changed", _on_template_value_changed.bind(param.parameter_name))
				config_container.add_child(spinbox)

			EffectParameter.ParameterType.BOOL:
				var checkbox = CheckBox.new()
				var value = effect_data.get(param.parameter_name, param.default_value)
				checkbox.button_pressed = value if value != null else param.default_value
				checkbox.connect("toggled", _on_template_bool_changed.bind(param.parameter_name))
				config_container.add_child(checkbox)

			EffectParameter.ParameterType.STRING:
				var line_edit = LineEdit.new()
				var value = effect_data.get(param.parameter_name, param.default_value)
				line_edit.text = str(value) if value != null else str(param.default_value)
				line_edit.connect("text_changed", _on_template_text_changed.bind(param.parameter_name))
				config_container.add_child(line_edit)

			EffectParameter.ParameterType.ENUM, \
			EffectParameter.ParameterType.BUFF_TYPE, \
			EffectParameter.ParameterType.TARGET_TYPE:
				var option_button = OptionButton.new()
				var options = param.get_available_options()
				for option in options:
					option_button.add_item(option)
				var value = effect_data.get(param.parameter_name, param.default_value)
				# Set selected based on value
				if value is int:
					option_button.selected = value
				elif value is String:
					var idx = options.find(value)
					if idx >= 0:
						option_button.selected = idx
				option_button.connect("item_selected", _on_template_option_selected.bind(param.parameter_name))
				config_container.add_child(option_button)

func create_config_field(property: Dictionary, effect: CardEffect, effect_data: Dictionary) -> void:
	var property_name: String = property.name
	var property_type: int = property.type

	# Skip common properties we don't want to configure
	if property_name in ["script", "effect_name", "effect_description", "effect_short_description", "effect_color", "effect_panel", "requires_player_input", "wait_for_effect_applied"]:
		return

	# Add label
	var label = Label.new()
	label.text = property_name.capitalize() + ":"
	config_container.add_child(label)

	# Create appropriate input field based on type
	match property_type:
		TYPE_INT:
			var spinbox = SpinBox.new()
			spinbox.min_value = -1000
			spinbox.max_value = 1000
			spinbox.step = 1
			var int_value = effect_data.get(property_name, effect.get(property_name))
			spinbox.value = int_value if int_value != null else 0
			spinbox.connect("value_changed", _on_config_value_changed.bind(property_name))
			config_container.add_child(spinbox)

		TYPE_FLOAT:
			var spinbox = SpinBox.new()
			spinbox.min_value = -1000.0
			spinbox.max_value = 1000.0
			spinbox.step = 0.1
			var float_value = effect_data.get(property_name, effect.get(property_name))
			spinbox.value = float_value if float_value != null else 0.0
			spinbox.connect("value_changed", _on_config_value_changed.bind(property_name))
			config_container.add_child(spinbox)

		TYPE_BOOL:
			var checkbox = CheckBox.new()
			var bool_value = effect_data.get(property_name, effect.get(property_name))
			checkbox.button_pressed = bool_value if bool_value != null else false
			checkbox.connect("toggled", _on_config_bool_changed.bind(property_name))
			config_container.add_child(checkbox)

		TYPE_STRING:
			var line_edit = LineEdit.new()
			var value = effect_data.get(property_name, effect.get(property_name))
			line_edit.text = str(value) if value != null else ""
			line_edit.connect("text_changed", _on_config_text_changed.bind(property_name))
			config_container.add_child(line_edit)

func _on_config_value_changed(value: float, property_name: String) -> void:
	if current_item == null:
		return

	var effect_data = current_item.get_effect_data()
	effect_data[property_name] = value
	current_item.set_effect_data(effect_data)
	config_value_changed.emit()

func _on_config_bool_changed(value: bool, property_name: String) -> void:
	if current_item == null:
		return

	var effect_data = current_item.get_effect_data()
	effect_data[property_name] = value
	current_item.set_effect_data(effect_data)
	config_value_changed.emit()

func _on_config_text_changed(value: String, property_name: String) -> void:
	if current_item == null:
		return

	var effect_data = current_item.get_effect_data()
	effect_data[property_name] = value
	current_item.set_effect_data(effect_data)
	config_value_changed.emit()

# Template-specific callbacks
func _on_template_value_changed(value: float, property_name: String) -> void:
	if current_item == null:
		return

	var effect_data = current_item.get_effect_data()
	effect_data[property_name] = value

	# Update template config if it exists
	if current_item.has_meta("template"):
		var template: EffectTemplate = current_item.get_meta("template")
		template.set_config_value(property_name, value)

	current_item.set_effect_data(effect_data)
	config_value_changed.emit()

func _on_template_bool_changed(value: bool, property_name: String) -> void:
	if current_item == null:
		return

	var effect_data = current_item.get_effect_data()
	effect_data[property_name] = value

	if current_item.has_meta("template"):
		var template: EffectTemplate = current_item.get_meta("template")
		template.set_config_value(property_name, value)

	current_item.set_effect_data(effect_data)
	config_value_changed.emit()

func _on_template_text_changed(value: String, property_name: String) -> void:
	if current_item == null:
		return

	var effect_data = current_item.get_effect_data()
	effect_data[property_name] = value

	if current_item.has_meta("template"):
		var template: EffectTemplate = current_item.get_meta("template")
		template.set_config_value(property_name, value)

	current_item.set_effect_data(effect_data)
	config_value_changed.emit()

func _on_template_option_selected(index: int, property_name: String) -> void:
	if current_item == null:
		return

	var effect_data = current_item.get_effect_data()
	effect_data[property_name] = index

	if current_item.has_meta("template"):
		var template: EffectTemplate = current_item.get_meta("template")
		template.set_config_value(property_name, index)

	current_item.set_effect_data(effect_data)
	config_value_changed.emit()
