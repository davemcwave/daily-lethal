extends RefCounted
class_name CardFactory
## Builds cards from data, and turns cards back into data.
##
## Card definition (the Card Lab's JSON format, extended):
##   {
##     "format": 1,
##     "name": "Slash", "energy": 1,
##     "description": "Deal 2 damage.",                      # static text, or
##     "description_template": "Deal {{effect0.damage_amount}} damage.",  # live text
##     "icon": "res://Assets/Textures/sword.png",            # or a Card Lab icon name
##     "color": "#002A8C",                                   # icon panel background
##     "gradient": ["#ff0000", "#0000ff"],                   # optional, 2+ colors
##     "effects": [<effect definition>, ...]                 # see EffectRegistry
##   }
## Card Lab links also use "colors": [primary, gradient stops...], still supported.
##
## Built-in cards and player-made cards go through the same code, so anything the
## game's own cards can do, a custom card can do.

const FORMAT := 1
const GENERIC_CARD_SCENE := "res://Scenes/Card.tscn"
const DEFAULT_COLOR := "#002A8C"
## Card-level settings copied as-is when present.
const CARD_SETTINGS := ["card_effect_delay", "break_effects_on_apply", "pay_cost_after_effects"]


## A new card (not yet in the tree) built on the generic Card scene.
## legacy_effect_builder handles effect types the registry doesn't know
## (the Card Lab's original "DamageCardEffect"-style entries); it may return a
## CardEffect, an Array of them, or null.
static func create_card(definition: Dictionary, legacy_effect_builder: Callable = Callable()) -> Card:
	var card: Card = load(GENERIC_CARD_SCENE).instantiate()
	apply_definition(card, definition, legacy_effect_builder)
	return card

static func apply_definition(card: Card, definition: Dictionary, legacy_effect_builder: Callable = Callable()) -> void:
	card.card_name = definition.get("name", "Custom Card")
	card.energy_cost = int(definition.get("energy", 1))
	var description_text: String = definition.get("description", "")
	var description_template: String = definition.get("description_template", description_text)
	card.set_description(description_text)
	for setting in CARD_SETTINGS:
		if definition.has(setting):
			card.set(setting, definition[setting])

	_apply_colors(card, definition)
	_apply_icon(card, str(definition.get("icon", "")))

	for effect_definition in definition.get("effects", []):
		_add_effect(card, effect_definition, legacy_effect_builder)

	card.set_description_template(description_template)

## The definition of a card instance (built-in or factory-made).
static func describe_card(card: Card) -> Dictionary:
	var definition := {
		"format": FORMAT,
		"name": card.card_name,
		"energy": card.energy_cost,
		"description": card.card_description,
	}
	var template := card.get_description_template()
	if not template.is_empty() and template != card.card_description:
		definition["description_template"] = template
	if card.card_effect_delay != 0.0:
		definition["card_effect_delay"] = card.card_effect_delay
	if card.break_effects_on_apply:
		definition["break_effects_on_apply"] = true
	if card.pay_cost_after_effects:
		definition["pay_cost_after_effects"] = true
	var icon := card.get_icon_texture()
	if icon != null and not icon.resource_path.is_empty():
		# "res://Assets/Textures/sword.png" -> "sword" (resolve_icon_path's short form).
		var icon_path := icon.resource_path
		if icon_path.begins_with("res://Assets/Textures/") and icon_path.ends_with(".png") and icon_path.get_file() == icon_path.trim_prefix("res://Assets/Textures/"):
			definition["icon"] = icon_path.get_file().get_basename()
		else:
			definition["icon"] = icon_path.trim_prefix("res://")
	definition["color"] = "#" + card.get_background_color().to_html(true)
	if card.has_gradient_background():
		var texture := card.get_gradient_background_texture()
		if texture != null and texture.gradient != null:
			var stops: Array = []
			for color in texture.gradient.colors:
				stops.append("#" + color.to_html(true))
			definition["gradient"] = stops
	var effects: Array = []
	for effect in card.card_effects:
		if effect != null:
			effects.append(EffectRegistry.describe_effect(effect))
	definition["effects"] = effects
	return definition


static func _add_effect(card: Card, effect_definition: Dictionary, legacy_effect_builder: Callable) -> void:
	var type: String = str(effect_definition.get("type", ""))
	if EffectRegistry.has_effect(type):
		var siblings: Array = []
		var effect := EffectRegistry.create_effect(effect_definition, siblings)
		# Effects this one refers to (e.g. a choice's options) sit beside it, in order.
		for sibling in siblings:
			card.add_child(sibling, true)
		if effect != null:
			card.add_child(effect, true)
			card.card_effects.append(effect)
		return
	if not legacy_effect_builder.is_valid():
		push_warning("CardFactory: unknown effect type '%s'" % type)
		return
	var built = legacy_effect_builder.call(effect_definition)
	var built_effects: Array = built if built is Array else [built]
	for effect in built_effects:
		if effect != null:
			card.add_child(effect)
			card.card_effects.append(effect)

static func _apply_colors(card: Card, definition: Dictionary) -> void:
	# Card Lab "colors": [primary, ...]; 2+ entries also make a gradient of all of them.
	var colors_array: Array = definition["colors"] if definition.get("colors") is Array else []
	var primary_hex: String = str(colors_array[0]) if colors_array.size() > 0 else str(definition.get("color", DEFAULT_COLOR))
	var gradient_hexes: Array = definition["gradient"] if definition.get("gradient") is Array else colors_array

	if not card.has_node("IconPanel"):
		return
	var icon_panel: Control = card.get_node("IconPanel")
	var style: StyleBox = icon_panel.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color.html(primary_hex)
	icon_panel.add_theme_stylebox_override("panel", style)

	if card.has_gradient_background():
		var old_gradient := card.get_node("IconPanel/GradientBackground")
		icon_panel.remove_child(old_gradient)
		old_gradient.queue_free()
	var gradient_colors := PackedColorArray()
	for entry in gradient_hexes:
		if entry is String and not String(entry).is_empty():
			gradient_colors.append(Color.html(entry))
	if gradient_colors.size() >= 2:
		card.add_gradient_background(gradient_colors)

const ICON_DIR := "res://Assets/"
const ICON_EXTENSIONS := ["png", "svg", "jpg", "jpeg", "webp"]

static func _apply_icon(card: Card, icon_value: String) -> void:
	if icon_value.is_empty() or not card.has_node("IconPanel/Icon"):
		return
	var path := resolve_icon_path(icon_value)
	# Card data can only use the game's own images: under res://Assets/, an image
	# type, no "..". Anything else keeps the card's default icon.
	if not path.begins_with(ICON_DIR) or path.contains("..") or not path.get_extension().to_lower() in ICON_EXTENSIONS \
			or not ResourceLoader.exists(path):
		push_warning("CardFactory: icon '%s' isn't one of the game's images; ignored" % icon_value)
		return
	var texture = load(path)
	if texture:
		card.get_node("IconPanel/Icon").set_texture(texture)

## Card Lab icon names ("sword", "Assets/Textures/sword.png", ...) to a res:// path.
static func resolve_icon_path(icon_value: String) -> String:
	if icon_value.begins_with("res://"):
		return icon_value
	if icon_value.begins_with("Assets/"):
		return "res://%s" % icon_value
	if icon_value.begins_with("../"):
		return "res://%s" % icon_value.substr(3)
	if icon_value.begins_with("./"):
		return "res://%s" % icon_value.substr(2)
	var normalized := icon_value
	var lower := normalized.to_lower()
	if not (lower.ends_with(".png") or lower.ends_with(".svg") or lower.ends_with(".jpg") \
		or lower.ends_with(".jpeg") or lower.ends_with(".webp") or lower.ends_with(".gif")):
		normalized += ".png"
	return "res://Assets/Textures/%s" % normalized
