extends Control

@onready var background = $"/root/Background"
@onready var effects_vbox_container: VBoxContainer = $EffectLibraryPanel/ScrollContainer/VBoxContainer
@onready var selected_effects_container: VBoxContainer = $SelectedEffectsPanel/ScrollContainer/VBoxContainer
@onready var config_dialog: AcceptDialog = $EffectConfigDialog
@onready var config_container: VBoxContainer = $EffectConfigDialog/ScrollContainer/VBoxContainer
@onready var card_preview_container: Panel = $CardPreviewPanel/CardContainer
@onready var card_name_edit: LineEdit = $ActionsPanel/VBoxContainer/CardNameEdit
@onready var save_button: Button = $ActionsPanel/VBoxContainer/SaveButton
@onready var load_button: Button = $ActionsPanel/VBoxContainer/LoadButton

var selected_effects: Array[SelectedEffectItem] = []
var current_selected_item: SelectedEffectItem = null
var effect_library_buttons: Dictionary = {}

func _ready() -> void:
	populate_effects()
	save_button.connect("pressed", _on_save_button_pressed)
	load_button.connect("pressed", _on_load_button_pressed)

func populate_effects() -> void:
	for card_effect_scene in background.get_all_card_effect_scenes():
		var card_effect: CardEffect = card_effect_scene.instantiate()
		var card_effect_name: String = card_effect.get_effect_name()

		if card_effect_name.is_empty():
			card_effect.queue_free()
			continue

		var effect_item_button: EffectItemButton = load("res://Scenes/EffectItemButton.tscn").instantiate()
		effect_item_button.set_effect_name(card_effect_name)
		effect_item_button.connect("pressed", _on_effect_library_button_pressed.bind(effect_item_button, card_effect_scene))
		effects_vbox_container.add_child(effect_item_button)
		effect_library_buttons[card_effect_name] = effect_item_button
		card_effect.queue_free()

func _on_effect_library_button_pressed(button: EffectItemButton, effect_scene: PackedScene) -> void:
	# Add effect to selected effects if checkbox is now checked
	if button.checkbox.is_pressed():
		add_effect_to_selected(effect_scene)
	else:
		remove_effect_from_selected(effect_scene)

func add_effect_to_selected(effect_scene: PackedScene) -> void:
	var card_effect: CardEffect = effect_scene.instantiate()
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

	# Now set the effect data (after @onready vars are ready)
	selected_item.set_effect(card_effect, {})
	selected_effects.append(selected_item)

	update_card_preview()

func remove_effect_from_selected(effect_scene: PackedScene) -> void:
	var card_effect: CardEffect = effect_scene.instantiate()
	var effect_name: String = card_effect.get_effect_name()
	card_effect.queue_free()

	for item in selected_effects:
		if item.get_effect().get_effect_name() == effect_name:
			selected_effects.erase(item)
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
		clear_config_panel()

	update_card_preview()

func _on_effect_item_selected(item: SelectedEffectItem) -> void:
	# Unhighlight previous selection
	if current_selected_item != null:
		current_selected_item.unhighlight()

	# Highlight new selection
	current_selected_item = item
	item.highlight()

	# Show configuration for this effect
	show_config_for_effect(item)

func show_config_for_effect(item: SelectedEffectItem) -> void:
	clear_config_panel()

	var effect: CardEffect = item.get_effect()
	var effect_data: Dictionary = item.get_effect_data()

	# Set dialog title
	config_dialog.title = "Configure: %s" % effect.get_effect_name()

	# Add title label
	var title_label = RichTextLabel.new()
	title_label.bbcode_enabled = true
	title_label.text = "[center][b]%s[/b][/center]" % effect.get_effect_name()
	title_label.fit_content = true
	title_label.scroll_active = false
	title_label.custom_minimum_size = Vector2(0, 30)
	config_container.add_child(title_label)

	# Get exported properties and create UI for them
	var property_list = effect.get_property_list()
	for property in property_list:
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_EDITOR:
			create_config_field(property, effect, effect_data, item)

	# Show the dialog
	config_dialog.popup_centered()

func create_config_field(property: Dictionary, effect: CardEffect, effect_data: Dictionary, item: SelectedEffectItem) -> void:
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
			spinbox.connect("value_changed", _on_config_value_changed.bind(property_name, item))
			config_container.add_child(spinbox)

		TYPE_FLOAT:
			var spinbox = SpinBox.new()
			spinbox.min_value = -1000.0
			spinbox.max_value = 1000.0
			spinbox.step = 0.1
			var float_value = effect_data.get(property_name, effect.get(property_name))
			spinbox.value = float_value if float_value != null else 0.0
			spinbox.connect("value_changed", _on_config_value_changed.bind(property_name, item))
			config_container.add_child(spinbox)

		TYPE_BOOL:
			var checkbox = CheckBox.new()
			var bool_value = effect_data.get(property_name, effect.get(property_name))
			checkbox.button_pressed = bool_value if bool_value != null else false
			checkbox.connect("toggled", _on_config_bool_changed.bind(property_name, item))
			config_container.add_child(checkbox)

		TYPE_STRING:
			var line_edit = LineEdit.new()
			var value = effect_data.get(property_name, effect.get(property_name))
			line_edit.text = str(value) if value != null else ""
			line_edit.connect("text_changed", _on_config_text_changed.bind(property_name, item))
			config_container.add_child(line_edit)

func _on_config_value_changed(value: float, property_name: String, item: SelectedEffectItem) -> void:
	var effect_data = item.get_effect_data()
	effect_data[property_name] = value
	item.set_effect_data(effect_data)
	update_card_preview()

func _on_config_bool_changed(value: bool, property_name: String, item: SelectedEffectItem) -> void:
	var effect_data = item.get_effect_data()
	effect_data[property_name] = value
	item.set_effect_data(effect_data)
	update_card_preview()

func _on_config_text_changed(value: String, property_name: String, item: SelectedEffectItem) -> void:
	var effect_data = item.get_effect_data()
	effect_data[property_name] = value
	item.set_effect_data(effect_data)
	update_card_preview()

func clear_config_panel() -> void:
	for child in config_container.get_children():
		child.queue_free()

func update_card_preview() -> void:
	# Clear previous preview
	for child in card_preview_container.get_children():
		child.queue_free()

	# Create a preview card
	if selected_effects.size() > 0:
		var preview_card = create_preview_card()
		card_preview_container.add_child(preview_card)

func create_preview_card() -> Panel:
	# Create custom card preview at 240x360 (no scaling needed)
	var card = Panel.new()
	card.custom_minimum_size = Vector2(240, 360)
	card.position = Vector2(48, 40)  # Centered in container

	# Card background style
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.433, 0.433, 0.433)
	card_style.border_width_left = 4
	card_style.border_width_top = 4
	card_style.border_width_right = 4
	card_style.border_width_bottom = 4
	card_style.border_color = Color.BLACK
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_right = 10
	card_style.corner_radius_bottom_left = 10
	card.add_theme_stylebox_override("panel", card_style)

	# Title Panel (card name)
	var title_panel = Panel.new()
	title_panel.position = Vector2(14, 16)
	title_panel.size = Vector2(212, 54)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.169, 0.169, 0.169)
	title_style.border_width_left = 4
	title_style.border_width_top = 4
	title_style.border_width_right = 4
	title_style.border_width_bottom = 4
	title_style.border_color = Color.BLACK
	title_panel.add_theme_stylebox_override("panel", title_style)

	var title_label = RichTextLabel.new()
	title_label.position = Vector2(54, 0)
	title_label.size = Vector2(158, 54)
	title_label.bbcode_enabled = true
	var card_name = card_name_edit.text if not card_name_edit.text.is_empty() else "Custom Card"
	title_label.text = "[center]%s[/center]" % card_name
	title_label.add_theme_font_override("normal_font", load("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf"))
	title_label.add_theme_font_override("bold_font", load("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf"))
	title_label.add_theme_font_size_override("normal_font_size", 20)
	title_label.scroll_active = false
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_panel.add_child(title_label)
	card.add_child(title_panel)

	# Energy Panel
	var energy_panel = Panel.new()
	energy_panel.position = Vector2(14, 16)
	energy_panel.size = Vector2(54, 54)
	var energy_style = StyleBoxFlat.new()
	energy_style.bg_color = Color(0.169, 0.169, 0.169)
	energy_style.border_width_left = 4
	energy_style.border_width_top = 4
	energy_style.border_width_right = 4
	energy_style.border_width_bottom = 4
	energy_style.border_color = Color.BLACK
	energy_panel.add_theme_stylebox_override("panel", energy_style)

	var energy_label = RichTextLabel.new()
	energy_label.position = Vector2(8, 0)
	energy_label.size = Vector2(12, 54)
	energy_label.bbcode_enabled = true
	energy_label.text = "[center]1[/center]"
	energy_label.add_theme_font_size_override("normal_font_size", 24)
	energy_label.scroll_active = false
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_panel.add_child(energy_label)

	var bolt_icon = TextureRect.new()
	bolt_icon.position = Vector2(20, 13)
	bolt_icon.size = Vector2(26, 28)
	bolt_icon.texture = load("res://Assets/Textures/bolt-white.png")
	bolt_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	energy_panel.add_child(bolt_icon)
	card.add_child(energy_panel)

	# Icon Panel
	var icon_panel = Panel.new()
	icon_panel.position = Vector2(14, 70)
	icon_panel.size = Vector2(212, 134)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.548, 0.002, 0.154)
	icon_style.border_width_left = 4
	icon_style.border_width_right = 4
	icon_style.border_width_bottom = 4
	icon_style.border_color = Color.BLACK
	icon_panel.add_theme_stylebox_override("panel", icon_style)

	var icon = TextureRect.new()
	icon.position = Vector2(43, 7)
	icon.size = Vector2(126, 120)
	icon.texture = load("res://Assets/Textures/sword.png")
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_panel.add_child(icon)
	card.add_child(icon_panel)

	# Description Panel
	var desc_panel = Panel.new()
	desc_panel.position = Vector2(14, 204)
	desc_panel.size = Vector2(212, 142)
	var desc_style = StyleBoxFlat.new()
	desc_style.bg_color = Color(0.169, 0.169, 0.169)
	desc_style.border_width_left = 4
	desc_style.border_width_right = 4
	desc_style.border_width_bottom = 4
	desc_style.border_color = Color.BLACK
	desc_panel.add_theme_stylebox_override("panel", desc_style)

	var desc_label = RichTextLabel.new()
	desc_label.position = Vector2(12, 0)
	desc_label.size = Vector2(188, 142)
	desc_label.bbcode_enabled = true

	# Build description from effects
	var description = ""
	for item in selected_effects:
		var effect = item.get_effect()
		var effect_short_desc = effect.get_effect_short_description()
		if not effect_short_desc.is_empty():
			description += effect_short_desc + "\n"
		else:
			description += effect.get_effect_name() + "\n"

	desc_label.text = "[center]%s[/center]" % description.strip_edges()
	desc_label.add_theme_font_override("normal_font", load("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf"))
	desc_label.add_theme_font_size_override("normal_font_size", 20)
	desc_label.scroll_active = false
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_panel.add_child(desc_label)
	card.add_child(desc_panel)

	return card

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
	clear_config_panel()
	update_card_preview()
