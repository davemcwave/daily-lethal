extends CardEffectPanel

@onready var buff_option_menu = $BuffOptionMenu
@onready var background = $"/root/Background"
func _ready():
	populate_options()
	
func populate_options() -> void:
	for buff_scene in background.get_all_buff_scenes():
		var buff: Buff = buff_scene.instantiate()
		buff_option_menu.add_item(buff.get_buff_name())
	
	
