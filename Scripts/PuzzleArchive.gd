class_name PuzzleArchive
## Released daily puzzles for the desktop game (the Puzzle Archive and the main menu's Daily).
##
## The list ships in Data/puzzle_archive.json (Tools/build_puzzle_archive.py); puzzles released
## after the build are fetched from playlethal.fun's custom-redirects.json and added.

const DATA_PATH := "res://Data/puzzle_archive.json"
const REMOTE_PUZZLES_URL := "https://playlethal.fun/custom-redirects.json"
const RELEASE_UTC_OFFSET_HOURS := -4  # dailies release at midnight US Eastern (manifest "release_at")

static var _card_names: Dictionary = {}

## Today's daily date, "YYYY-MM-DD" (US Eastern).
static func today() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) + RELEASE_UTC_OFFSET_HOURS * 3600)

## The bundled puzzles released by today.
static func load_bundled() -> Array:
	var puzzles: Array = []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if parsed is Dictionary:
		var day := today()
		for entry in parsed.get("puzzles", []):
			if str(entry.get("date", "")) <= day:
				puzzles.append(entry)
	return puzzles

## Adds puzzles released after this build (fetched from the website) to `puzzles`. Returns how
## many were added (0 when offline). `parent` hosts the HTTP request.
static func fetch_newer(parent: Node, puzzles: Array, timeout: float = 8.0) -> int:
	var request := HTTPRequest.new()
	request.timeout = timeout
	parent.add_child(request)
	if request.request(REMOTE_PUZZLES_URL) != OK:
		request.queue_free()
		return 0
	var response: Array = await request.request_completed  # [result, code, headers, body]
	request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return 0
	var redirects = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if not redirects is Dictionary:
		return 0
	var known := {}
	for entry in puzzles:
		known[entry["date"]] = true
	var day := today()
	var added := 0
	for date in redirects:
		var key := str(date)
		if key.length() == 10 and key <= day and not known.has(key):
			var entry := entry_from_search(key, str(redirects[date]))
			if not entry.is_empty():
				puzzles.append(entry)
				added += 1
	return added

## Today's puzzle, else the most recent one released before it ({} if none).
static func daily(puzzles: Array) -> Dictionary:
	var best: Dictionary = {}
	for entry in puzzles:
		if best.is_empty() or str(entry["date"]) > str(best["date"]):
			best = entry
	return best

## An archive entry from a URL puzzle ("?cards=<base64>&php=&pnrg=&ehp=&enemy_name=&author=&enemy_buffs=").
static func entry_from_search(date: String, search_text: String) -> Dictionary:
	var params := {}
	for pair in search_text.trim_prefix("?").split("&"):
		var parts := pair.split("=", true, 1)
		if parts.size() == 2:
			params[parts[0]] = parts[1].uri_decode().replace("+", " ")
	if not params.has("cards"):
		return {}
	var cards: Array = []
	for part in Marshalls.base64_to_utf8(str(params["cards"])).uri_decode().split(","):
		var key := part.strip_edges().to_lower().replace("-card.png", "").replace("-", "")
		if not key.is_empty():
			cards.append(card_name(key))
	var statuses: Array = []
	for buff in str(params.get("enemy_buffs", "")).split(",", false):
		statuses.append(buff.split(":")[0])
	return {"id": "daily:" + date, "date": date, "enemy": str(params.get("enemy_name", "?")), "author": str(params.get("author", "")),
			"skulls": 3, "cards": cards, "php": int(params.get("php", 3)), "energy": int(params.get("pnrg", 5)),
			"ehp": int(params.get("ehp", 10)), "statuses": statuses, "search": search_text}

## "partingshot" -> "Parting Shot", read from the card's scene.
static func card_name(key: String) -> String:
	if _card_names.is_empty():
		for file in DirAccess.get_files_at("res://Scenes/"):
			if file.ends_with("Card.tscn"):
				_card_names[file.trim_suffix("Card.tscn").to_lower()] = "file:" + file
	var known: String = str(_card_names.get(key, ""))
	if known.begins_with("file:"):
		var text := FileAccess.get_file_as_string("res://Scenes/" + known.trim_prefix("file:"))
		var at := text.find("card_name = \"")
		if at != -1:
			var start := at + "card_name = \"".length()
			_card_names[key] = text.substr(start, text.find("\"", start) - start)
			return _card_names[key]
	elif not known.is_empty():
		return known
	return key.capitalize()
