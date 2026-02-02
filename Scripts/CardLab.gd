extends Control

@onready var background = $"/root/Background"
@onready var effects_vbox_container: VBoxContainer = $EffectLibraryPanel/ScrollContainer/VBoxContainer
@onready var selected_effects_container: VBoxContainer = $SelectedEffectsPanel/ScrollContainer/VBoxContainer
@onready var config_panel: EffectConfigPanel = $EffectConfigPanel
@onready var card_preview_container: Panel = $CardPreviewPanel/CardContainer
@onready var card_name_edit: LineEdit = $ActionsPanel/VBoxContainer/CardNameEdit
@onready var save_button: Button = $ActionsPanel/VBoxContainer/SaveButton
@onready var load_button: Button = $ActionsPanel/VBoxContainer/LoadButton
@onready var preview_title_label: RichTextLabel = $CardPreviewPanel/CardContainer/PreviewCard/TitlePanel/TitleLabel
@onready var preview_desc_label: RichTextLabel = $CardPreviewPanel/CardContainer/PreviewCard/DescriptionPanel/DescriptionLabel

var selected_effects: Array[SelectedEffectItem] = []
var current_selected_item: SelectedEffectItem = null
var effect_library_buttons: Dictionary = {}
var template_registry: TemplateRegistry

func _ready() -> void:
	template_registry = TemplateRegistry.get_instance()
	populate_effects()
	save_button.connect("pressed", _on_save_button_pressed)
	load_button.connect("pressed", _on_load_button_pressed)
	card_name_edit.connect("text_changed", _on_card_name_changed)
	config_panel.connect("config_value_changed", _on_config_changed)

	# Static card preview is already in the scene, just update it
	update_card_preview()

func populate_effects() -> void:
	# Add all templates to the effect library
	for template in template_registry.get_all_templates():
		var template_name = template.get_effect_name()
		var effect_item_button: EffectItemButton = load("res://Scenes/EffectItemButton.tscn").instantiate()
		effect_item_button.set_effect_name(template_name)
		effect_item_button.connect("pressed", _on_template_library_button_pressed.bind(effect_item_button, template))
		effects_vbox_container.add_child(effect_item_button)
		effect_library_buttons[template_name] = effect_item_button

func _on_template_library_button_pressed(button: EffectItemButton, template: EffectTemplate) -> void:
	# Add template-based effect to selected effects if checkbox is now checked
	if button.checkbox.is_pressed():
		add_template_to_selected(template)
	else:
		remove_template_from_selected(template)



func add_template_to_selected(template: EffectTemplate) -> void:
	# Create a default-configured effect from the template
	var card_effect: CardEffect = template.create_effect()
	var selected_item: SelectedEffectItem = load("res://Scenes/SelectedEffectItem.tscn").instantiate()

	# Connect signals before adding to tree
	selected_item.connect("move_up_pressed", _on_effect_move_up)
	selected_item.connect("move_down_pressed", _on_effect_move_down)
	selected_item.connect("remove_pressed", _on_effect_remove)
	selected_item.connect("selected", _on_effect_item_selected)

	# Wrap in MarginContainer for left/right spacing
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_right", 8)

	# Add to tree first so @onready variables are initialized
	selected_effects_container.add_child(margin_container)
	margin_container.add_child(selected_item)

	# Set the effect data with template reference
	selected_item.set_effect(card_effect, {})
	selected_item.set_meta("template", template)  # Store template for later config
	selected_effects.append(selected_item)

	update_card_preview()

func remove_template_from_selected(template: EffectTemplate) -> void:
	var template_name: String = template.get_effect_name()

	for item in selected_effects:
		if item.get_effect().get_effect_name() == template_name:
			selected_effects.erase(item)
			var margin_container = item.get_parent()
			if margin_container:
				margin_container.queue_free()
			else:
				item.queue_free()
			break

	update_card_preview()

func _on_effect_move_up(item: SelectedEffectItem) -> void:
	var index = selected_effects.find(item)
	if index > 0:
		# Swap in array
		var temp = selected_effects[index - 1]
		selected_effects[index - 1] = selected_effects[index]
		selected_effects[index] = temp

		# Reorder in UI
		selected_effects_container.move_child(item, index - 1)
		update_card_preview()

func _on_effect_move_down(item: SelectedEffectItem) -> void:
	var index = selected_effects.find(item)
	if index < selected_effects.size() - 1:
		# Swap in array
		var temp = selected_effects[index + 1]
		selected_effects[index + 1] = selected_effects[index]
		selected_effects[index] = temp

		# Reorder in UI
		selected_effects_container.move_child(item, index + 1)
		update_card_preview()

func _on_effect_remove(item: SelectedEffectItem) -> void:
	# Uncheck the library checkbox
	var effect_name = item.get_effect().get_effect_name()
	if effect_library_buttons.has(effect_name):
		effect_library_buttons[effect_name].checkbox.set_pressed(false)

	selected_effects.erase(item)

	# Remove the MarginContainer parent
	var margin_container = item.get_parent()
	if margin_container:
		margin_container.queue_free()
	else:
		item.queue_free()

	if current_selected_item == item:
		current_selected_item = null
		config_panel.hide_config()

	update_card_preview()

func _on_effect_item_selected(item: SelectedEffectItem) -> void:
	# Unhighlight previous selection
	if current_selected_item != null:
		current_selected_item.unhighlight()

	# Highlight new selection
	current_selected_item = item
	item.highlight()

	# Show configuration for this effect
	config_panel.show_config_for_effect(item)

func _on_config_changed() -> void:
	update_card_preview()

func update_card_preview() -> void:
	# Update the title
	var card_name = card_name_edit.text if not card_name_edit.text.is_empty() else "Custom Card"
	preview_title_label.text = "[center]%s[/center]" % card_name

	# Build description from effects
	var description = ""
	if selected_effects.size() > 0:
		for item in selected_effects:
			var effect = item.get_effect()
			var effect_short_desc = effect.get_effect_short_description()
			if not effect_short_desc.is_empty():
				description += effect_short_desc + "\n"
			else:
				description += effect.get_effect_name() + "\n"
		preview_desc_label.text = "[center]%s[/center]" % description.strip_edges()
	else:
		preview_desc_label.text = "[center]Select effects to see card description[/center]"

func _on_card_name_changed(_new_text: String) -> void:
	update_card_preview()

func _on_save_button_pressed() -> void:
	var card_name = card_name_edit.text
	if card_name.is_empty():
		card_name = "CustomCard"

	# Create custom card resource
	var custom_card = CustomCardResource.new()
	custom_card.card_name = card_name
	custom_card.energy_cost = 1  # You can add a field for this later

	# Save each effect's configuration
	for item in selected_effects:
		var effect = item.get_effect()
		var effect_data = item.get_effect_data()
		custom_card.add_effect_config(effect.get_effect_name(), effect_data)

	# Save to file
	var file_path = "user://custom_cards/%s.tres" % card_name.to_lower().replace(" ", "_")

	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://custom_cards/"))

	var result = ResourceSaver.save(custom_card, file_path)
	if result == OK:
		print("Custom card saved successfully to: %s" % file_path)
	else:
		print("Failed to save custom card: %d" % result)

func _on_load_button_pressed() -> void:
	var card_name = card_name_edit.text
	if card_name.is_empty():
		print("Please enter a card name to load")
		return

	var file_path = "user://custom_cards/%s.tres" % card_name.to_lower().replace(" ", "_")

	if not FileAccess.file_exists(file_path):
		print("Custom card file not found: %s" % file_path)
		return

	var custom_card = load(file_path) as CustomCardResource
	if custom_card == null:
		print("Failed to load custom card")
		return

	# Clear current selection
	clear_all_effects()

	# Load effects from the resource
	for effect_config in custom_card.get_effect_configs():
		var effect_name = effect_config["effect_name"]
		var properties = effect_config["properties"]

		# Find the effect in the background
		var effect = background.get_card_effect_by_name(effect_name)
		if effect == null:
			print("Effect not found: %s" % effect_name)
			continue

		# Add effect to selected
		var selected_item: SelectedEffectItem = load("res://Scenes/SelectedEffectItem.tscn").instantiate()

		# Connect signals
		selected_item.connect("move_up_pressed", _on_effect_move_up)
		selected_item.connect("move_down_pressed", _on_effect_move_down)
		selected_item.connect("remove_pressed", _on_effect_remove)
		selected_item.connect("selected", _on_effect_item_selected)

		# Wrap in MarginContainer for left/right spacing
		var margin_container = MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", 8)
		margin_container.add_theme_constant_override("margin_right", 8)

		# Add to tree first so @onready variables are initialized
		selected_effects_container.add_child(margin_container)
		margin_container.add_child(selected_item)

		# Now set the effect data with loaded properties
		selected_item.set_effect(effect, properties)
		selected_effects.append(selected_item)

		# Check the checkbox in the library
		if effect_library_buttons.has(effect_name):
			effect_library_buttons[effect_name].checkbox.set_pressed(true)

	card_name_edit.text = custom_card.card_name
	update_card_preview()
	print("Custom card loaded successfully: %s" % custom_card.card_name)

func clear_all_effects() -> void:
	# Clear selected effects
	for item in selected_effects:
		var effect_name = item.get_effect().get_effect_name()
		if effect_library_buttons.has(effect_name):
			effect_library_buttons[effect_name].checkbox.set_pressed(false)

		# Remove the MarginContainer parent
		var margin_container = item.get_parent()
		if margin_container:
			margin_container.queue_free()
		else:
			item.queue_free()

	selected_effects.clear()
	current_selected_item = null
	config_panel.hide_config()
	update_card_preview()
