extends RichTextLabel
class_name URLCapturer

var puzzle_date: String = ""
var path_name
var search
var card_list = ""
func _ready():
	path_name = JavaScriptBridge.eval("window.location.pathname")
	search = JavaScriptBridge.eval("window.location.search")

	if path_name != null and path_name != "":
		puzzle_date = search.split("?puzzle_date=")[-1].split("&")[0]
		#puzzle_date = path_name.split("/")[-2]
		
	#update_label()

func has_puzzle_date() -> bool:
	#var puzzle_date_from_search = get_puzzle_date_from_search() 
	#return puzzle_date_from_search != null and "-" in puzzle_date_from_search
	return puzzle_date != null and puzzle_date != "" and "-" in puzzle_date

func has_today() -> bool:
	return puzzle_date == "today"
	
func is_test_puzzle() -> bool:
	return search != null and "?cards=" in search

func get_player_energy_from_test_puzzle() -> int:
	return int(search.split("&pnrg=")[-1].split("&")[0])
	
func get_player_health_from_test_puzzle() -> int:
	return int(search.split("&php=")[-1].split("&")[0])
	
func get_energy_health_from_test_puzzle() -> int:
	return int(search.split("&ehp=")[-1].split("&")[0])
	
func get_enemy_name_from_test_puzzle() -> String:
	return "Enemy" #search.split("&enm=")[-1].split("&")[0]
	
func get_cards_from_test_puzzle() -> Array:
	var cards: Array = []
	#set_text("[center][b]%s[/b][/center]" % search)

	var base64_encoded_card_list = search.split("?cards=")[-1].split("&")[0]
	var card_list_url_decoded = base64_encoded_card_list.uri_decode()
	var card_list_base64_decoded = Marshalls.base64_to_utf8(card_list_url_decoded)
	card_list = card_list_base64_decoded
	var card_string = card_list_base64_decoded.uri_decode()
	var card_path_strings = card_string.split(",")
	var card_scene_paths = []
	for card_path_string: String in card_path_strings:
		# card_path_string = "lunge-card.PNG"
		var card_path_no_png: String = card_path_string.replace(".PNG", "")
		var card_path_two_words = card_path_no_png.split("-")
		var card_first_word = card_path_two_words[0].capitalize()
		var card_second_word = card_path_two_words[1].capitalize()
		var card_scene_path = "res://Scenes/%s%s.scn" % [card_first_word, card_second_word]
		var card_packed_scene = load(card_scene_path)
		
		card_scene_paths.append(card_scene_path)
		cards.append(card_packed_scene)
		#set_text("[center][b]%s[/b][/center]" % ",".join(card_scene_paths))
		
	#update_label()
	
	return cards

	
func get_puzzle_date() -> String:
	return puzzle_date

func get_path_name() -> String:
	return path_name

func update_label() -> void:
	if path_name == null:
		path_name = "NULL"
	
	set_text("""
		[center][b]
		path_name: %s
		search: %s
		puzzle_date: %s
		card_list: %s
		[/b][/center]
	""" % [path_name, search, puzzle_date, card_list])
