extends RichTextLabel
class_name URLCapturer

var puzzle_date: String = ""
var path_name
func _ready():
	path_name = JavaScriptBridge.eval("window.location.pathname")
	if path_name != null and path_name != "":
		puzzle_date = path_name.split("/")[-2]
	update_label()

func has_puzzle_date() -> bool:
	return puzzle_date != null and puzzle_date != "" and "-" in puzzle_date

func has_today() -> bool:
	return puzzle_date == "today"
	
func get_puzzle_date() -> String:
	return puzzle_date

func get_path_name() -> String:
	return path_name

func update_label() -> void:
	if path_name != null:
		$Label.set_text("[center][b]%s[/b][/center]" % path_name)
