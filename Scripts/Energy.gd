extends TextureRect
class_name Energy

@export var energy_amount: int = 5
@onready var buffs_container: BuffsContainer = get_tree().get_root().get_node("Scene/BuffsContainer")
@onready var original_color: Color = self_modulate
const TEXT_TEMPLATE = "[center][b]%d[/b][/center]"
@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")

func _ready():
	update_energy_text()
	
func has_enough_energy(cost: int) -> bool:
	return cost <= energy_amount \
		or buffs_container.has_free_buff() \
		or buffs_container.get_discounted_cost(cost) <= energy_amount


func get_energy_amount() -> int:
	return energy_amount

func blink() -> void:
	self_modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	self_modulate = original_color

func set_energy(new_energy: int) -> void:
	energy_amount = new_energy
	update_energy_text()
	
func add_energy(additional_energy_amount: int) -> void:
	energy_amount += additional_energy_amount
	blink()
	update_energy_text()
	
func use_energy(cost: int, use_free_buff: bool = true) -> void:
	if buffs_container.has_free_buff() and use_free_buff:
		buffs_container.remove_free_buff()
	elif buffs_container.has_discount_buff():
		var discount_buff: DiscountBuff = buffs_container.get_discount_buff()
		var discount_amount: int = discount_buff.get_discount_amount()
		energy_amount -= (cost - discount_amount)
		buffs_container.remove_discount_buff()
	else:
		energy_amount -= cost
		
	blink()

	update_energy_text()
	
func update_energy_text() -> void:
	$EnergyAmountText.set_text(TEXT_TEMPLATE % energy_amount)


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text("Energy", "Amount to spend on cards, each card has its own energy cost")
		center_description.set_color(self_modulate)
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()
