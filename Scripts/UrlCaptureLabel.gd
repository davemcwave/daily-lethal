extends RichTextLabel
class_name URLCapturer

var puzzle_date: String = ""

func _ready():
	var path_name = JavaScriptBridge.eval("window.location.pathname")
	if path_name != null and path_name != "":
		puzzle_date = path_name.split("/")[-2]

func has_puzzle_date() -> bool:
	return puzzle_date != null and puzzle_date != "" and "-" in puzzle_date
	
func get_puzzle_date() -> String:
	return puzzle_date
