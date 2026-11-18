extends Control

const CHOICE_ICON_BUTTON_OFFSET = Vector2(-40.0, 10.0)
const OPTIONS_PANEL_SCENE = preload("res://Scenes/OptionsPanel.tscn")

@onready var buttons: Array[Button] = [$TutorialButton, $PlayButton, $CardLabButton, $DiscordButton, $OptionsButton]
@onready var choice_icon: TextureRect = $ChoiceIcon
@onready var audio_handler = $"/root/AudioHandler"

var options_panel: Control = null

func _ready() -> void:
	_liven_grim()
	_add_puzzles_button()
	if not $"/root/Background".card_lab_available():
		_hide_card_lab_button()
	for button: Button in buttons:
		button.connect('mouse_entered', _on_button_mouse_entered.bind(button))
		button.connect('mouse_exited', _on_button_mouse_exited.bind(button))

	_on_button_mouse_entered(buttons[0])

## Desktop: DAILY (today's puzzle, or the latest one) and PUZZLES (the Puzzle Archive) under
## PLAY, made from PLAY's look; the column of buttons is spaced tighter to fit them.
## Desktop menu: Play (the main action, larger), Daily, Library (Puzzles and Cards) and
## Card Lab. Options and Discord are small icons in the top-right corner; the Tutorial
## item is gone (Play shows it the first time, Options can replay it).
func _add_puzzles_button() -> void:
	if OS.has_feature("web"):
		return
	var play: Button = $PlayButton
	var daily := _menu_button_like(play, "DailyButton", "Daily", 0)
	daily.pressed.connect(_on_daily_pressed.bind(daily))
	var library := _menu_button_like(play, "LibraryButton", "Library", 30)
	library.pressed.connect(func(): get_tree().change_scene_to_file($"/root/Background".ARCHIVE_SCENE))
	buttons.insert(buttons.find(play) + 1, daily)
	buttons.insert(buttons.find(daily) + 1, library)
	var top: float = $TutorialButton.position.y - 4.0
	for hidden in [$TutorialButton, $DiscordButton, $OptionsButton]:
		hidden.hide()
		buttons.erase(hidden)
	# Quit, last (the desktop game; the web builds have no main menu).
	var quit := _menu_button_like(play, "QuitButton", "Quit", 0)
	quit.pressed.connect(func(): get_tree().quit())
	buttons.append(quit)
	# Play is the primary item: a larger label.
	var play_text: RichTextLabel = play.get_node("Text")
	play_text.add_theme_font_size_override("normal_font_size", 42)
	play_text.add_theme_font_size_override("bold_font_size", 42)
	play.size.y += 10
	var y := top
	for button in buttons:
		button.position.y = y
		y += 58.0 if button == play else 48.0
	_add_corner_icon("Options", _white(preload("res://Assets/Textures/settings.png")), _on_options_button_pressed, 0)
	_add_corner_icon("Discord", preload("res://Assets/Textures/Discord-Symbol-White.png"), _on_discord_button_pressed, 1)

## The icon in white (same shape), so it matches the Discord icon.
func _white(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, Color(1, 1, 1, image.get_pixel(x, y).a))
	return ImageTexture.create_from_image(image)

## A small icon button in the top-right corner (index 0 is rightmost).
func _add_corner_icon(label: String, texture: Texture2D, action: Callable, index: int) -> void:
	var icon := TextureButton.new()
	icon.name = label + "Icon"
	icon.texture_normal = texture
	icon.ignore_texture_size = true
	icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(26, 26)
	icon.size = Vector2(26, 26)
	icon.tooltip_text = label
	icon.modulate = Color(1, 1, 1, 0.65)
	icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	icon.position = Vector2(get_viewport_rect().size.x - 18 - 26 - index * 40, 18)
	icon.mouse_entered.connect(func(): icon.modulate = Color(1, 1, 1, 1))
	icon.mouse_exited.connect(func(): icon.modulate = Color(1, 1, 1, 0.65))
	icon.pressed.connect(action)
	add_child(icon)

func _menu_button_like(model: Button, button_name: String, label: String, extra_width: float) -> Button:
	var button: Button = model.duplicate(Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_USE_INSTANTIATION)
	button.name = button_name
	button.get_node("Text").text = "[shake rate=2.0 level=2 connected=1]%s[/shake]" % label
	button.size.x += extra_width
	add_child(button)
	return button

## Today's daily, or the most recent one if today's isn't out (fetching newer ones first).
func _on_daily_pressed(button: Button) -> void:
	var label: RichTextLabel = button.get_node("Text")
	label.text = "[shake rate=2.0 level=2 connected=1]Loading...[/shake]"
	button.disabled = true
	var puzzles := PuzzleArchive.load_bundled()
	await PuzzleArchive.fetch_newer(self, puzzles, 5.0)
	var entry := PuzzleArchive.daily(puzzles)
	if entry.is_empty():
		label.text = "[shake rate=2.0 level=2 connected=1]Daily[/shake]"
		button.disabled = false
		return
	var background = $"/root/Background"
	background.archive_queue = []
	background.start_archive_puzzle(entry)

## No Card Lab on phones (see Background.card_lab_available): drop the button and
## move the buttons below it up into its place.
func _hide_card_lab_button() -> void:
	var lab: Button = $CardLabButton
	var at := buttons.find(lab)
	var gap: float = buttons[at + 1].position.y - lab.position.y
	for i in range(at + 1, buttons.size()):
		buttons[i].position.y -= gap
	lab.visible = false
	buttons.erase(lab)

func _on_button_mouse_entered(button: Button) -> void:
	var button_label: RichTextLabel = button.get_node('Text')
	button_label.set_text('[b]%s[/b]' % button_label.get_text())
	choice_icon.set_global_position(button.get_global_position() + CHOICE_ICON_BUTTON_OFFSET)
	audio_handler.play_sfx('HitSFX', 0.75, -15)

func _on_button_mouse_exited(button: Button) -> void:
	var button_label: RichTextLabel = button.get_node('Text')
	button_label.set_text(button_label.get_text().replace("[b]", "").replace("[/b]", ""))

func _on_tutorial_button_pressed():
	$"/root/Background".set_tutorial_seen()
	$"/root/Background".set_show_tutorial(true)
	$"/root/Background".set_from_story_view(true)
	$"/root/Background".set_puzzle_scene("res://Scenes/Puzzles/Tutorial-Puzzle.tscn")
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.tscn")


## Play: the story map, after the tutorial the first time (it ends on the story map).
func _on_play_button_pressed():
	if not $"/root/Background".tutorial_seen:
		_on_tutorial_button_pressed()
		return
	$"/root/Background".set_show_tutorial(false)
	get_tree().change_scene_to_file("res://Scenes/StoryView.tscn")


func _on_card_lab_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Builder/CardBuilder.tscn")


func _on_discord_button_pressed():
	OS.shell_open("https://discord.gg/2sev8HA9sd")


func _on_options_button_pressed():
	if options_panel != null:
		return

	options_panel = OPTIONS_PANEL_SCENE.instantiate()
	options_panel.closed.connect(_on_options_panel_closed)
	add_child(options_panel)

func _on_options_panel_closed() -> void:
	options_panel = null

# ---------------------------------------------------------------- Grim

## Where Grim's head and his green eye are on the 960 x 540 menu (the art is one image).
const GRIM_HEAD := Vector2(735, 300)
const GRIM_EYE := Vector2(695, 295)  # an oval about 11 x 19 px (measured from the art)

## The background art (SplashArt): a soft green glow behind his head so the hood stands out
## from the dark background, a slow breathing bob and sway, and a pulse of light on his eye.
func _liven_grim() -> void:
	var art: TextureRect = get_node_or_null("SplashArt")
	if art == null:
		return
	# The glow, under the art.
	var glow := TextureRect.new()
	glow.texture = _radial_texture(Color(0.25, 0.75, 0.35, 0.30))
	glow.size = Vector2(640, 640)
	glow.position = GRIM_HEAD - glow.size / 2.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	move_child(glow, art.get_index())
	var glow_pulse := glow.create_tween().set_loops()
	glow_pulse.tween_property(glow, "modulate:a", 0.65, 3.0).set_trans(Tween.TRANS_SINE)
	glow_pulse.tween_property(glow, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	# Breathing: a small rise and fall, and a slower slight sway around the bottom of the hood.
	art.pivot_offset = Vector2(GRIM_HEAD.x - art.position.x, art.size.y)
	var rest_y := art.position.y
	var bob := art.create_tween().set_loops()
	bob.tween_property(art, "position:y", rest_y - 4.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(art, "position:y", rest_y, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var sway := art.create_tween().set_loops()
	sway.tween_property(art, "rotation_degrees", 0.6, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(art, "rotation_degrees", -0.6, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# The eye: a little light on it (part of the art, so it moves with him).
	var eye := TextureRect.new()
	eye.texture = _radial_texture(Color(0.45, 1.0, 0.45, 0.9))
	eye.size = Vector2(18, 28)  # a little larger than the eye, the same oval shape
	eye.position = GRIM_EYE - art.position - eye.size / 2.0
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	eye.material = add
	eye.use_parent_material = false
	art.add_child(eye)
	var eye_pulse := eye.create_tween().set_loops()
	eye_pulse.tween_property(eye, "modulate:a", 0.25, 1.4).set_trans(Tween.TRANS_SINE)
	eye_pulse.tween_property(eye, "modulate:a", 0.9, 1.4).set_trans(Tween.TRANS_SINE)

## A round soft light: the color in the middle, fading to nothing at the edge.
func _radial_texture(color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0.0))
	gradient.add_point(0.45, Color(color, color.a * 0.45))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture
