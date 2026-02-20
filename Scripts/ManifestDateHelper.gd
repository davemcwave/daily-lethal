extends Object
class_name ManifestDateHelper

static var _dates: Array = []
static var _is_loaded := false

static func get_next_date(current_date: String) -> String:
	_ensure_loaded()
	if _dates.is_empty():
		return ""
	for date_string in _dates:
		var date_value: String = String(date_string)
		if current_date.is_empty():
			return date_value
		if date_value > current_date:
			return date_value
	return ""

static func get_previous_date(current_date: String) -> String:
	_ensure_loaded()
	if _dates.is_empty() or current_date.is_empty():
		return ""
	for i in range(_dates.size() - 1, -1, -1):
		var date_value: String = String(_dates[i])
		if date_value < current_date:
			return date_value
	return ""

static func _ensure_loaded() -> void:
	if _is_loaded:
		return
	_is_loaded = true
	var file := FileAccess.open("res://manifest.json", FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data = json.get_data()
	if data is Dictionary and data.has("puzzles"):
		for entry in data["puzzles"]:
			if entry is Dictionary and entry.has("id"):
				_dates.append(String(entry["id"]))
	_dates.sort()
