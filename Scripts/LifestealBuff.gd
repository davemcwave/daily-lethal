extends Buff
class_name LifestealBuff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var hand = scene.get_node("Hand")
@onready var health: Health = scene.get_node("Health")

func activate() -> void:
	await get_tree().create_timer(0.25).timeout
	var last_card_effects: Array[CardEffect] = scene.get_last_card_effects()
	var did_lifesteal: bool = false
	for last_card_effect: CardEffect in last_card_effects:
		print("last card effect: %s" % last_card_effect.get_effect_name())
		if not last_card_effect is DamageCardEffect:
			continue
		
		var last_damage_card_effect: DamageCardEffect = last_card_effect
		health.add_health(last_damage_card_effect.get_damage_amount())
		did_lifesteal = true
		
	
	if did_lifesteal:
		super.activate()
		queue_free()
	
