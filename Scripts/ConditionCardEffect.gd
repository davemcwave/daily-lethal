extends CardEffect
class_name ConditionCardEffect

@export_enum("Health", "Energy", "CardsPlayed", "DicardPile") var condition_object: String = "Health"
@export var threshold_amount: int = 3
@export_enum("LessThan", "GreaterThan", "EqualTo") var condition: String = "LessThan"

@onready var health: Health = scene.get_node("Health")
@onready var energy: Energy = scene.get_node("Energy")
@onready var cards_played: CardsPlayed = scene.get_node("CardsPlayed")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

	
	
func set_threshold_amount(new_threshold_amount: int) -> void:
	threshold_amount = new_threshold_amount
	
func apply() -> void:
	var condition_function: Callable
	if condition_object == "Health":
		condition_function = health.get_health
	elif condition_object == "Energy":
		condition_function = energy.get_energy_amount
	elif condition_object == "CardsPlayed":
		condition_function = cards_played.get_cards_played_count
	elif condition_object == "DiscardPile":
		condition_function = discard_panel.get_card_count
	
	var child_card_effect: CardEffect = get_child(0)
	if (
		(condition == "LessThan" and condition_function.call() < threshold_amount) or \
		(condition == "GreaterThan" and condition_function.call() > threshold_amount) or \
		(condition == "EqualTo" and condition_function.call() == threshold_amount)
	):
		child_card_effect.apply()
