extends Node
class_name TemplateRegistry

## Singleton registry for effect templates
## Manages both templates and raw CardEffects

static var _instance: TemplateRegistry = null

var templates: Dictionary = {}  # template_name -> EffectTemplate
var template_list: Array[EffectTemplate] = []

static func get_instance() -> TemplateRegistry:
	if _instance == null:
		_instance = TemplateRegistry.new()
		_instance._initialize()
	return _instance

func _initialize() -> void:
	_register_builtin_templates()

func _register_builtin_templates() -> void:
	"""Register all built-in effect templates"""
	# Damage templates
	register_template(DamageTemplate.new())
	register_template(EnergyBasedDamageTemplate.new())
	register_template(HealthBasedDamageTemplate.new())
	register_template(EnergyConditionDamageTemplate.new())
	register_template(DiscardPileBasedDamageTemplate.new())

	# Buff templates
	register_template(BuffTemplate.new())
	register_template(RemoveBuffsTemplate.new())
	register_template(BuffWithHealthTemplate.new())

	# Healing templates
	register_template(HealTemplate.new())
	register_template(HealDamageTemplate.new())
	register_template(HealEnemyTemplate.new())

	# Energy templates
	register_template(GainEnergyTemplate.new())
	register_template(LoseEnergyTemplate.new())

	# Card manipulation templates
	register_template(DrawTemplate.new())
	register_template(DiscardTemplate.new())
	register_template(CreateCardTemplate.new())
	register_template(TrashTemplate.new())
	register_template(TrashChooseTemplate.new())
	register_template(PickToCreateTemplate.new())

	# Health templates
	register_template(ReduceHealthTemplate.new())

func register_template(template: EffectTemplate) -> void:
	"""Register a template"""
	templates[template.template_name] = template
	template_list.append(template)

func get_template(template_name: String) -> EffectTemplate:
	"""Get a template by name"""
	if templates.has(template_name):
		return templates[template_name]
	return null

func get_all_templates() -> Array[EffectTemplate]:
	"""Get all registered templates"""
	return template_list

func get_templates_by_category(category: String) -> Array[EffectTemplate]:
	"""Get all templates in a category"""
	var result: Array[EffectTemplate] = []
	for template in template_list:
		if template.category == category:
			result.append(template)
	return result

func get_categories() -> Array[String]:
	"""Get all unique categories"""
	var categories: Array[String] = []
	for template in template_list:
		if not categories.has(template.category):
			categories.append(template.category)
	return categories

func create_effect_from_template(template_name: String, config: Dictionary = {}) -> CardEffect:
	"""Create a configured CardEffect from a template"""
	var template = get_template(template_name)
	if template == null:
		push_error("TemplateRegistry: Template not found: %s" % template_name)
		return null

	# Clone template with config
	var configured_template = template.clone_with_config(config)
	return configured_template.create_effect()
