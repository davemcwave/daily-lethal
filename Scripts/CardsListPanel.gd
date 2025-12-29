extends Panel

@onready var card_list_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var edit_card_panel: EditCardPanel = $"../EditCardPanel"
@onready var card_preview_panel: CardEditorCardPreviewPanel = $"../CardPreviewPanel"

func _ready():
	call_deferred("populate_card_list")
	
func get_card_scenes() -> Array:
	var card_scenes: Array = []
	var dir = DirAccess.open("res://Scenes/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "": break
		if file.ends_with("Card.scn"):
			var scene_path = "res://Scenes/" + file
			#var scene = load(scene_path)
			card_scenes.append(scene_path)
	dir.list_dir_end()
	return card_scenes

func populate_card_list() -> void:
	# Populate all permanent cards.
	var card_scenes: Array = get_card_scenes()
	for card_scene in card_scenes:
		var object = load(card_scene).instantiate()
		
		if not (object is Card):
			continue
			
		var card: Card = load(card_scene).instantiate()
		var card_select_button: CardSelectButton = load("res://Scenes/CardSelectButton.scn").instantiate()
		card_select_button.set_card(card)
		card_list_container.add_child(card_select_button)
		card_select_button.connect('pressed', _on_card_select_button_pressed.bind(card_select_button))
		
	# @TODO Populate custom made cards.
	
func _on_card_select_button_pressed(card_select_button: CardSelectButton) -> void:
	edit_card_panel.display_card_info(card_select_button.get_card())
	card_preview_panel.display_card_info(card_select_button.get_card())
