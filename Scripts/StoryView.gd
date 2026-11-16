extends Control
## Story mode map, built from Data/story_worlds.json (the worlds of the progression web).
##
## Tiers run left to right. A tier is one world or a pair of worlds (drawn one above
## the other); it opens when every world of the tier before it is finished, and a
## pair can be played in either order. Inside a world the puzzles open one at a time,
## easiest first, the boss last. Drag, scroll or use the arrow keys to move along.
##
## Progress is Background's list of beaten story puzzles, keyed by each puzzle's id
## (a scene path, "url:<date>" or "story:<name>"); old saves keyed by scene path
## carry over. Dev: `-- --story-unlock-all` opens every puzzle; `--story-scroll=<px>` starts
## scrolled that far, `--story-hover=<n>` shows puzzle n's card,
## `--story-hover-world=<id>` a world's card (for screenshots).

const DATA_PATH := "res://Data/story_worlds.json"
const FONT_BOLD: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf")
const FONT_MEDIUM: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf")
const SKULL_TEXTURE: Texture2D = preload("res://Assets/Textures/white-skull.png")
const LOCK_TEXTURE: Texture2D = preload("res://Assets/Textures/lock.png")

const DISC_RADIUS := 20.0       # a puzzle's disc
const RING_WIDTH := 3.0
const NODE_STEP := 48.0         # distance between puzzles along a world's path
const ZIGZAG := 13.0            # puzzles alternate this far above/below the world's line
const BLOB_PAD := 20.0          # world shape around its puzzles
const TIER_GAP := 120.0         # between one tier's worlds and the next
const PAIR_OFFSET := 96.0       # a pair's worlds sit this far above/below the middle
const MAP_TOP := 56.0           # below the Main Menu button
const MAP_MARGIN := 70.0        # empty space before the first and after the last tier
const DRAG_THRESHOLD := 6.0

const COLOR_DISC := Color("#ffce4e")
const COLOR_DISC_LOCKED := Color("#6b6658")
const COLOR_RING := Color("#9aa3a6")
const COLOR_RING_DONE := Color("#36b24a")
const COLOR_RING_OPEN := Color("#ffffff")
const COLOR_INK := Color("#3b2a12")
const COLOR_ROAD := Color("#c9a94a")
const COLOR_LABEL := Color("#ffffff")
const COLOR_LABEL_NUM := Color("#ffce4e")
const COLOR_OUTLINE := Color("#1d2b30")
const COLOR_BONE := Color("#d8d0bc")      # a finished world's outline
const DIFFICULTY_NAMES := ["Very Easy", "Easy", "Medium", "Hard", "Very Hard"]

enum State { LOCKED, OPEN, DONE }

@export var show_all: bool = false
@onready var audio_handler = $"/root/AudioHandler"
@onready var background = $"/root/Background"
@onready var map: Control = $Map

var tiers: Array = []                 # [[world id, ...], ...]
var worlds: Dictionary = {}           # world id -> world data (+ "tier", "number", "nodes", "hull", "color")
var world_order: Array = []           # world ids, in tier order
var nodes: Array = []                 # one Dictionary per puzzle: entry, world, index, pos, texture, initials
var map_width: float = 0.0
var scroll_x: float = 0.0
var hovered: int = -1
var hovered_world: String = ""      # the world under the mouse when no puzzle is
var pressing: bool = false
var dragging: bool = false
var press_position := Vector2.ZERO
var press_scroll := 0.0
var highlight_node: int = -1          # the puzzle opened by the last win (pops in)
var highlight_time: float = 0.0
var pulse_time: float = 0.0
var hover_card: PanelContainer
# "World complete" sequence (see _play_world_complete).
var world_reveal: Dictionary = {}     # world id -> 0..1 while it unlocks (absent = shown as it is)
var sequence_running: bool = false
var anim_clock: float = 0.0           # seconds, for the animations below
var node_blink: Dictionary = {}       # node -> clock time it blinks (a new world's puzzles, one by one)

func _ready() -> void:
	background.set_from_story_view(true)
	background.leave_story_puzzle()
	if "--story-unlock-all" in OS.get_cmdline_user_args():
		show_all = true
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.draw.connect(_draw_map)
	_load_data()
	_layout()
	_build_hover_card()
	_focus_on_progress()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--story-scroll="):
			_set_scroll(float(arg.trim_prefix("--story-scroll=")))
		elif arg.begins_with("--story-hover="):  # show the card of puzzle N (0 = first)
			_set_hovered.call_deferred(int(arg.trim_prefix("--story-hover=")))
		elif arg.begins_with("--story-hover-world="):  # show a world's card (its id, e.g. grow)
			_show_world_card.call_deferred(arg.trim_prefix("--story-hover-world="))
		elif arg.begins_with("--story-demo-complete="):  # play the "world complete" sequence for a world id
			_demo_world_complete.call_deferred(arg.trim_prefix("--story-demo-complete="))
	_announce_unlock()
	set_process(true)

# ---------------------------------------------------------------- data and state

func _load_data() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary:
		push_error("Story data missing or broken: " + DATA_PATH)
		return
	tiers = parsed.get("tiers", [])
	for world in parsed.get("worlds", []):
		worlds[world["id"]] = world
	var number := 1
	for t in tiers.size():
		for world_id in tiers[t]:
			var world: Dictionary = worlds[world_id]
			world["tier"] = t
			world["number"] = number
			number += 1
			world_order.append(world_id)

var demo_done: Array = []  # dev preview only: puzzle ids treated as beaten (never saved)

func _is_done(entry: Dictionary) -> bool:
	return background.is_story_puzzle_completed(str(entry["id"])) or str(entry["id"]) in demo_done

func _world_done(world_id: String) -> bool:
	for entry in worlds[world_id]["puzzles"]:
		if not _is_done(entry):
			return false
	return true

func _tier_open(t: int) -> bool:
	if show_all or t <= 0:
		return true
	for world_id in tiers[t - 1]:
		if not _world_done(world_id):
			return false
	return true

func _world_open(world_id: String) -> bool:
	return _tier_open(int(worlds[world_id]["tier"]))

func _state(n: int) -> int:
	var node: Dictionary = nodes[n]
	if _is_done(node["entry"]):
		return State.DONE
	if not _world_open(node["world"]):
		return State.LOCKED
	if show_all or node["index"] == 0:
		return State.OPEN
	var previous: Dictionary = worlds[node["world"]]["puzzles"][node["index"] - 1]
	return State.OPEN if _is_done(previous) else State.LOCKED

# ---------------------------------------------------------------- layout

func _layout() -> void:
	var middle := MAP_TOP + (size.y - MAP_TOP) / 2.0 if size.y > 0 else 300.0
	var x := MAP_MARGIN
	for t in tiers.size():
		var tier: Array = tiers[t]
		var tier_width := 0.0
		for world_id in tier:
			tier_width = maxf(tier_width, (worlds[world_id]["puzzles"].size() - 1) * NODE_STEP)
		for k in tier.size():
			var world: Dictionary = worlds[tier[k]]
			var count: int = world["puzzles"].size()
			var width := (count - 1) * NODE_STEP
			var y := middle if tier.size() == 1 else middle + (PAIR_OFFSET if k == 1 else -PAIR_OFFSET)
			var start_x := x + (tier_width - width) / 2.0
			var world_nodes: Array = []
			for i in count:
				var entry: Dictionary = world["puzzles"][i]
				var pos := Vector2(start_x + i * NODE_STEP, y + (ZIGZAG if i % 2 == 1 else -ZIGZAG))
				if count == 1:
					pos.y = y
				world_nodes.append(nodes.size())
				nodes.append({"entry": entry, "world": tier[k], "index": i, "pos": pos,
							  "texture": _enemy_texture(entry), "initials": _initials(str(entry["enemy"]))})
			world["nodes"] = world_nodes
			world["hull"] = _blob_points(world_nodes)
			world["label_rect"] = _label_rect(world)
			world["color"] = Color.from_hsv(fmod(world["number"] * 47.0 + 190.0, 360.0) / 360.0, 0.45, 0.55, 0.22)
		x += tier_width + TIER_GAP
	map_width = x - TIER_GAP + MAP_MARGIN
	map.size = Vector2(map_width, size.y)

## Where the world's title ("WORLD n" and its name, plus the padlock) is drawn, for hovering.
func _label_rect(world: Dictionary) -> Rect2:
	var hull: PackedVector2Array = world["hull"]
	var top := INF
	for p in hull:
		top = minf(top, p.y)
	var center_x := 0.0
	for n in world["nodes"]:
		center_x += nodes[n]["pos"].x
	center_x /= world["nodes"].size()
	var width := FONT_BOLD.get_string_size(str(world["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 22.0
	return Rect2(center_x - width / 2.0 - 4.0, top - 32.0, width + 8.0, 30.0)

func _blob_points(world_nodes: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius := DISC_RADIUS + BLOB_PAD
	for n in world_nodes:
		var center: Vector2 = nodes[n]["pos"]
		for a in 24:
			points.append(center + Vector2.from_angle(TAU * a / 24.0) * radius)
	return Geometry2D.convex_hull(points)

func _enemy_texture(entry: Dictionary) -> Texture2D:
	if not entry.has("scene") or not ResourceLoader.exists(str(entry["scene"])):
		return null
	var puzzle = load(str(entry["scene"])).instantiate()
	var texture: Texture2D = puzzle.get_enemy_icon_texture() if puzzle.has_method("get_enemy_icon_texture") else null
	puzzle.free()
	return texture

func _initials(enemy_name: String) -> String:
	var letters := ""
	for word in enemy_name.replace(".", "").split(" ", false):
		if letters.length() < 2 and word[0] == word[0].to_upper():
			letters += word[0]
	return letters if not letters.is_empty() else enemy_name.left(1).to_upper()

func _focus_on_progress() -> void:
	# Center the puzzle just beaten, else the first one waiting to be played.
	var target := -1
	var last: String = background.get_last_completed_story_puzzle()
	for n in nodes.size():
		if not last.is_empty() and str(nodes[n]["entry"]["id"]) == last:
			target = n
			break
	if target == -1:
		for n in nodes.size():
			if _state(n) == State.OPEN:
				target = n
				break
	if target == -1:
		target = nodes.size() - 1
	if target >= 0:
		_set_scroll(nodes[target]["pos"].x - size.x / 2.0)

func _announce_unlock() -> void:
	var last: String = background.get_last_completed_story_puzzle()
	var was_new: bool = background.was_last_story_win_new()
	background.clear_last_completed_story_puzzle()
	if last.is_empty():
		return
	# Finishing a world for the first time gets its own sequence.
	for n in nodes.size():
		if str(nodes[n]["entry"]["id"]) == last and was_new and _world_done(nodes[n]["world"]):
			_play_world_complete.call_deferred(nodes[n]["world"])
			return
	for n in nodes.size():
		if str(nodes[n]["entry"]["id"]) == last:
			# The next puzzle of that world, or (if the world is finished) the first of each newly opened world.
			var world: Dictionary = worlds[nodes[n]["world"]]
			if nodes[n]["index"] + 1 < world["nodes"].size():
				highlight_node = world["nodes"][nodes[n]["index"] + 1]
			else:
				for m in nodes.size():
					if nodes[m]["index"] == 0 and _state(m) == State.OPEN and not _is_done(nodes[m]["entry"]) and worlds[nodes[m]["world"]]["tier"] == world["tier"] + 1:
						highlight_node = m
						break
			break
	if highlight_node != -1 and _state(highlight_node) == State.OPEN:
		highlight_time = 0.0
		audio_handler.play_sfx("DrawSFX")
	else:
		highlight_node = -1

# ---------------------------------------------------------------- drawing

func _process(delta: float) -> void:
	pulse_time += delta
	if highlight_node != -1:
		highlight_time += delta
	anim_clock += delta
	map.queue_redraw()

func _draw_map() -> void:
	_draw_roads()
	for world_id in world_order:
		_draw_world(world_id)
	for n in nodes.size():
		_draw_node(n)

func _draw_roads() -> void:
	# Every world of a tier leads to every world of the next one (a pair's lines cross).
	for t in range(tiers.size() - 1):
		var open := _tier_open(t + 1)
		var color := COLOR_ROAD if open else Color(COLOR_ROAD, 0.3)
		for from_id in tiers[t]:
			var from_nodes: Array = worlds[from_id]["nodes"]
			var start: Vector2 = nodes[from_nodes[-1]]["pos"] + Vector2(DISC_RADIUS + BLOB_PAD, 0)
			for to_id in tiers[t + 1]:
				var end: Vector2 = nodes[worlds[to_id]["nodes"][0]]["pos"] - Vector2(DISC_RADIUS + BLOB_PAD, 0)
				var bend := (end.x - start.x) * 0.45
				var curve := Curve2D.new()
				curve.add_point(start, Vector2.ZERO, Vector2(bend, 0))
				curve.add_point(end, Vector2(-bend, 0), Vector2.ZERO)
				var points := curve.tessellate(4, 3)
				map.draw_polyline(points, color, 2.5, true)

func _draw_world(world_id: String) -> void:
	var world: Dictionary = worlds[world_id]
	var open := _world_open(world_id)
	# While a world unlocks, it fades from the locked grey to its color.
	var reveal: float = world_reveal.get(world_id, 1.0 if open else 0.0)
	var locked_fill := Color(0.45, 0.47, 0.48, 0.12)
	var fill: Color = locked_fill.lerp(world["color"], reveal)
	var hull: PackedVector2Array = world["hull"]
	map.draw_colored_polygon(hull, fill)
	var outline := PackedVector2Array(hull)
	outline.append(hull[0])
	map.draw_polyline(outline, Color(fill, lerpf(0.3, 0.55, reveal)), 1.5, true)
	# The path through the world, in play order.
	var world_nodes: Array = world["nodes"]
	for i in range(world_nodes.size() - 1):
		var a: Vector2 = nodes[world_nodes[i]]["pos"]
		var b: Vector2 = nodes[world_nodes[i + 1]]["pos"]
		var done := _is_done(nodes[world_nodes[i]]["entry"])
		map.draw_line(a, b, Color(0, 0, 0, 0.55) if done else Color(0, 0, 0, 0.25), 3.0, true)
	# Label above the shape: "WORLD 7" (or FINALE) and the name.
	var top := INF
	for p in hull:
		top = minf(top, p.y)
	var center_x := 0.0
	for n in world_nodes:
		center_x += nodes[n]["pos"].x
	center_x /= world_nodes.size()
	var small := "FINALE" if world_id == "finale" else "WORLD %d" % world["number"]
	var alpha := lerpf(0.45, 1.0, reveal)
	_draw_text(Vector2(center_x, top - 20), small, FONT_BOLD, 9, Color(COLOR_LABEL_NUM, alpha))
	_draw_text(Vector2(center_x, top - 6), str(world["name"]), FONT_BOLD, 13, Color(COLOR_LABEL, alpha))
	if _world_done(world_id) and not world_reveal.has(world_id):
		# Reaped: a bone-white outline and a skull badge.
		map.draw_polyline(outline, Color(COLOR_BONE, 0.7), 2.0, true)
		var badge_x := center_x + FONT_BOLD.get_string_size(str(world["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x / 2.0 + 11.0
		_draw_done_badge(Vector2(badge_x, top - 11))
	if reveal < 1.0:
		# The padlock fades away as the world opens.
		var name_width := FONT_BOLD.get_string_size(str(world["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var lock_center := Vector2(center_x + name_width / 2.0 + 11, top - 11)
		map.draw_texture_rect(LOCK_TEXTURE, Rect2(lock_center - Vector2(7, 7), Vector2(14, 14)), false, Color(1, 1, 1, 0.6 * (1.0 - reveal)))

## A small skull on a dark disc: this world has been reaped.
func _draw_done_badge(center: Vector2, alpha: float = 1.0) -> void:
	if alpha <= 0.0:
		return
	map.draw_circle(center, 8.0, Color("#1f1f1f", alpha), true, -1.0, true)
	map.draw_texture_rect(SKULL_TEXTURE, Rect2(center - Vector2(6, 6), Vector2(12, 12)), false, Color(COLOR_BONE, alpha))

func _draw_node(n: int) -> void:
	var node: Dictionary = nodes[n]
	var state := _state(n)
	var center: Vector2 = node["pos"]
	var radius := DISC_RADIUS
	if n == highlight_node:
		# Pops in: grows past full size and settles.
		var t := clampf(highlight_time / 0.45, 0.0, 1.0)
		radius *= 1.0 + 0.35 * sin(t * PI)
	if n == hovered and state != State.LOCKED:
		radius *= 1.08
	var ring := COLOR_RING
	if state == State.DONE:
		ring = COLOR_RING_DONE
	elif state == State.OPEN:
		ring = COLOR_RING_OPEN.lerp(COLOR_DISC, 0.5 + 0.5 * sin(pulse_time * 4.0))
	elif state == State.LOCKED:
		ring = Color(0.25, 0.27, 0.28)
	map.draw_circle(center, radius + RING_WIDTH, ring, true, -1.0, true)
	var dim := Color(1, 1, 1, 1) if state != State.LOCKED else Color(0.42, 0.42, 0.42, 1)
	map.draw_circle(center, radius, COLOR_DISC if state != State.LOCKED else COLOR_DISC_LOCKED, true, -1.0, true)
	var texture: Texture2D = node["texture"]
	if state == State.LOCKED:
		# Not open yet: who it is stays a surprise (only its skulls show).
		_draw_text(center + Vector2(0, 6), "?", FONT_BOLD, 18, Color(0.2, 0.2, 0.2, 0.85), false)
	elif texture != null:
		map.draw_texture_rect(texture, Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, dim)
	else:
		_draw_text(center + Vector2(0, 5), node["initials"], FONT_BOLD, 14, COLOR_INK, false)
	# Skulls under the disc.
	var skulls: int = int(node["entry"].get("skulls", 1))
	var skull := 7.0
	var row := Vector2(center.x - skulls * skull / 2.0, center.y + radius + 1)
	for s in skulls:
		var rect := Rect2(row + Vector2(s * skull, 0), Vector2(skull, skull))
		map.draw_circle(rect.get_center(), skull / 2.0 + 0.5, Color("#1f1f1f"), true, -1.0, true)
		map.draw_texture_rect(SKULL_TEXTURE, rect.grow(-1.2), false, Color(0.83, 0.23, 0.25, 1.0 if state != State.LOCKED else 0.5))
	if node_blink.has(n):
		# A new world's puzzle blinks once as the world opens.
		var blink: float = (anim_clock - node_blink[n]) / 0.3
		if blink > 0.0 and blink < 1.0:
			map.draw_circle(center, radius + RING_WIDTH, Color(1, 1, 1, 0.55 * sin(blink * PI)), true, -1.0, true)

func _draw_text(pos: Vector2, text: String, font: Font, font_size: int, color: Color, outlined: bool = true) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(pos.x - width / 2.0, pos.y)
	if outlined:
		map.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(COLOR_OUTLINE, color.a))
	map.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

# ---------------------------------------------------------------- hover card

func _build_hover_card() -> void:
	hover_card = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.92)
	box.set_corner_radius_all(8)
	box.content_margin_left = 14
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	hover_card.add_theme_stylebox_override("panel", box)
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.z_index = 10
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.add_child(column)
	for part in [["World", FONT_BOLD, 10, COLOR_LABEL_NUM], ["Name", FONT_BOLD, 18, COLOR_LABEL],
				 ["Author", FONT_MEDIUM, 12, Color("#c8c8c8")], ["Difficulty", FONT_BOLD, 12, Color("#ef6b78")],
				 ["Status", FONT_MEDIUM, 12, Color("#9fe0b0")]]:
		var label := Label.new()
		label.name = part[0]
		label.add_theme_font_override("font", part[1])
		label.add_theme_font_size_override("font_size", part[2])
		label.add_theme_color_override("font_color", part[3])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if part[0] == "Difficulty":
			# Skulls, then the difficulty name.
			var row := HBoxContainer.new()
			row.name = "DifficultyRow"
			row.add_theme_constant_override("separation", 2)
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for s in 5:
				var skull := TextureRect.new()
				skull.texture = SKULL_TEXTURE
				skull.custom_minimum_size = Vector2(14, 14)
				skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				skull.self_modulate = Color(0.83, 0.23, 0.25)
				skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(skull)
			label.text = ""
			row.add_child(label)
			column.add_child(row)
			continue
		column.add_child(label)
	# A world's description (only on the world card).
	var idea := Label.new()
	idea.name = "Idea"
	idea.add_theme_font_override("font", FONT_MEDIUM)
	idea.add_theme_font_size_override("font_size", 12)
	idea.add_theme_color_override("font_color", Color("#e6e6e6"))
	idea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	idea.custom_minimum_size = Vector2(260, 0)
	idea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(idea)
	column.move_child(idea, column.get_node("Status").get_index())
	add_child(hover_card)
	hover_card.hide()

func _show_hover_card(n: int) -> void:
	var node: Dictionary = nodes[n]
	var entry: Dictionary = node["entry"]
	var world: Dictionary = worlds[node["world"]]
	var column := hover_card.get_child(0)
	var is_boss: bool = node["index"] == world["puzzles"].size() - 1
	column.get_node("World").text = "%s, BOSS" % str(world["name"]).to_upper() if is_boss else "%s, %d OF %d" % [str(world["name"]).to_upper(), node["index"] + 1, world["puzzles"].size()]
	var locked := _state(n) == State.LOCKED
	column.get_node("Idea").hide()
	column.get_node("DifficultyRow").show()
	column.get_node("Author").add_theme_color_override("font_color", Color("#c8c8c8"))
	column.get_node("Name").text = "???" if locked else str(entry["enemy"])
	var author := "" if locked else str(entry.get("author", ""))
	if author.is_empty() and entry.has("scene") and not locked:
		author = background.get_author_for_enemy(str(entry["enemy"]))
	column.get_node("Author").text = "by " + author if not author.is_empty() else ""
	column.get_node("Author").visible = not author.is_empty()
	var skulls: int = clampi(int(entry.get("skulls", 1)), 1, 5)
	var row: HBoxContainer = column.get_node("DifficultyRow")
	for s in 5:
		row.get_child(s).visible = s < skulls
	row.get_node("Difficulty").text = " " + DIFFICULTY_NAMES[skulls - 1]
	var status: Label = column.get_node("Status")
	status.show()  # the world card may have hidden it
	match _state(n):
		State.DONE:
			status.text = "Beaten"
			status.add_theme_color_override("font_color", Color("#9fe0b0"))
		State.OPEN:
			status.text = "Click to play"
			status.add_theme_color_override("font_color", Color("#ffce4e"))
		_:
			status.hide()  # locked: no "beat ... first" line, the "?" says enough
	hover_card.reset_size()
	var pos: Vector2 = map.position + node["pos"] + Vector2(DISC_RADIUS + 14, -hover_card.size.y / 2.0)
	if pos.x + hover_card.size.x > size.x - 8:
		pos.x = map.position.x + node["pos"].x - DISC_RADIUS - 14 - hover_card.size.x
	pos.y = clampf(pos.y, MAP_TOP, size.y - hover_card.size.y - 8)
	hover_card.position = pos
	hover_card.show()

func _show_world_card(world_id: String) -> void:
	var world: Dictionary = worlds[world_id]
	var column := hover_card.get_child(0)
	column.get_node("World").text = "FINALE" if world_id == "finale" else "WORLD %d" % world["number"]
	column.get_node("Name").text = str(world["name"])
	# New cards aren't listed: players meet them in the puzzles.
	column.get_node("Author").hide()
	column.get_node("DifficultyRow").hide()
	var idea: Label = column.get_node("Idea")
	idea.text = _world_story(world_id)
	idea.visible = not idea.text.is_empty()
	# The world card is just its number, name and story (no status line).
	column.get_node("Status").hide()
	hover_card.reset_size()
	# Under the world's shape, centered on it (kept on screen).
	var hull: PackedVector2Array = world["hull"]
	var bottom := -INF
	var left := INF
	var right := -INF
	for point in hull:
		bottom = maxf(bottom, point.y)
		left = minf(left, point.x)
		right = maxf(right, point.x)
	var pos := Vector2(map.position.x + (left + right) / 2.0 - hover_card.size.x / 2.0, bottom + 8)
	if pos.y + hover_card.size.y > size.y - 8:
		pos.y = hull[0].y - hover_card.size.y  # no room below: above it instead
		var top := INF
		for point in hull:
			top = minf(top, point.y)
		pos.y = top - 30 - hover_card.size.y
	pos.x = clampf(pos.x, 8, size.x - hover_card.size.x - 8)
	hover_card.position = pos
	hover_card.show()

# ---------------------------------------------------------------- input

func _set_scroll(value: float) -> void:
	scroll_x = clampf(value, 0.0, maxf(0.0, map_width - size.x))
	map.position.x = -scroll_x

func _node_at(screen_pos: Vector2) -> int:
	var local := screen_pos - map.position
	for n in nodes.size():
		if local.distance_to(nodes[n]["pos"]) <= DISC_RADIUS + RING_WIDTH:
			return n
	return -1

func _world_at(screen_pos: Vector2) -> String:
	var local := screen_pos - map.position
	for world_id in world_order:
		if Geometry2D.is_point_in_polygon(local, worlds[world_id]["hull"]) or worlds[world_id]["label_rect"].has_point(local):
			return world_id
	return ""

## What the mouse is over: a puzzle (its card), else a world (the world's card), else nothing.
func _update_hover(screen_pos: Vector2) -> void:
	var n := _node_at(screen_pos)
	if n != -1:
		hovered_world = ""
		_set_hovered(n)
		return
	_set_hovered(-1)
	var world_id := _world_at(screen_pos)
	if world_id == hovered_world:
		return
	hovered_world = world_id
	if world_id.is_empty():
		hover_card.hide()
	else:
		_show_world_card(world_id)

## Scrolling or dragging: hide whichever card is showing.
func _clear_hover() -> void:
	hovered_world = ""
	_set_hovered(-1)
	hover_card.hide()

func _set_hovered(n: int) -> void:
	if n == hovered:
		return
	hovered = n
	if n == -1:
		hover_card.hide()
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		_show_hover_card(n)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _state(n) != State.LOCKED else Control.CURSOR_ARROW

func _gui_input(event: InputEvent) -> void:
	if sequence_running:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				pressing = true
				dragging = false
				press_position = button.position
				press_scroll = scroll_x
			else:
				if pressing and not dragging:
					_open(_node_at(button.position))
				pressing = false
				dragging = false
		elif button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			_set_scroll(scroll_x + 70.0)
			_clear_hover()
		elif button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			_set_scroll(scroll_x - 70.0)
			_clear_hover()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if pressing and (dragging or motion.position.distance_to(press_position) > DRAG_THRESHOLD):
			dragging = true
			_set_scroll(press_scroll - (motion.position.x - press_position.x))
			_clear_hover()
		else:
			_update_hover(motion.position)

func _unhandled_input(event: InputEvent) -> void:
	if sequence_running:
		return
	if event.is_action_pressed("ui_right"):
		_set_scroll(scroll_x + 160.0)
	elif event.is_action_pressed("ui_left"):
		_set_scroll(scroll_x - 160.0)

func _open(n: int) -> void:
	if n == -1 or _state(n) == State.LOCKED:
		return
	audio_handler.play_sfx("DrawSFX")
	background.start_story_puzzle(nodes[n]["entry"])

# ---------------------------------------------------------------- world complete

func _wait_or_click(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds:
		await get_tree().process_frame
		if Input.is_action_just_pressed("skip_dialog"):
			return
		waited += get_process_delta_time()

## The world's story text (its "story" in the story file), else its design note.
func _world_story(world_id: String) -> String:
	var world: Dictionary = worlds[world_id]
	return str(world.get("story", world.get("idea", "")))

## Finishing a world opens the next tier (no popups): the map pans there, the new worlds'
## color comes in and each of their puzzles blinks once, in order. A finished world shows a
## bone-white outline and a skull badge.
func _play_world_complete(world_id: String) -> void:
	var world: Dictionary = worlds[world_id]
	var t: int = world["tier"]
	var opened: Array = tiers[t + 1] if t + 1 < tiers.size() and _tier_open(t + 1) else []
	if opened.is_empty():
		return
	sequence_running = true
	_clear_hover()
	for other_id in opened:
		world_reveal[other_id] = 0.0
	var target := 0.0
	for other_id in opened:
		target += _world_center_x(other_id)
	target /= opened.size()
	await _pan_to(target, 0.5)
	var reveal := create_tween().set_parallel(true)
	for other_id in opened:
		reveal.tween_method(func(v): world_reveal[other_id] = v, 0.0, 1.0, 0.4)
	await reveal.finished
	for other_id in opened:
		world_reveal.erase(other_id)
	audio_handler.play_sfx("DrawSFX", 0.7)
	var k := 0
	for other_id in opened:
		for n in worlds[other_id]["nodes"]:
			node_blink[n] = anim_clock + k * 0.08
			k += 1
	await _wait_or_click(0.3 + k * 0.08)
	node_blink.clear()
	highlight_node = worlds[opened[0]]["nodes"][0]
	highlight_time = 0.0
	sequence_running = false

func _world_center_x(world_id: String) -> float:
	var total := 0.0
	for n in worlds[world_id]["nodes"]:
		total += nodes[n]["pos"].x
	return total / worlds[world_id]["nodes"].size()

func _pan_to(x: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_scroll, scroll_x, x - size.x / 2.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

## Dev: --story-demo-complete=<world id> plays the sequence as if that world was just finished.
func _demo_world_complete(world_id: String) -> void:
	if worlds.has(world_id):
		# Treat that world as beaten (in memory only) so the whole sequence plays.
		for entry in worlds[world_id]["puzzles"]:
			demo_done.append(str(entry["id"]))
		_set_scroll(_world_center_x(world_id) - size.x / 2.0 - 300.0)
		_play_world_complete(world_id)

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
