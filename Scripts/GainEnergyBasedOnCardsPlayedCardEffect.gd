extends GainEnergyCardEffect
class_name GainEnergyBasedOnCardsPlayedCardEffect

@onready var cards_played: CardsPlayed = get_tree().get_root().get_node("Scene/CardsPlayed")

func set_additional_energy_amount(new_additional_energy_amount: int) -> void:
	additional_energy_amount = new_additional_energy_amount
	
func get_additional_energy_amount() -> int:
	return additional_energy_amount
	
func apply() -> void:
	#print("cards_played.get_cards_played_count(): %d" % cards_played.get_cards_played_count())
	set_additional_energy_amount(cards_played.get_cards_played_count())
	energy.add_energy(additional_energy_amount)
