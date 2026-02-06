extends Panel

@onready var character_icon: TextureRect = $"Character Icon"
@onready var enemy_text: RichTextLabel = $EnemyText
@onready var author_text: RichTextLabel = $AuthorText
@onready var difficulty_text: RichTextLabel = $DifficultyText
@onready var difficulty_container: HBoxContainer = $DiffcultyContainer
@onready var difficulty_icon: TextureRect = $DiffcultyContainer/DifficultyIcon
@onready var background = $"/root/Background"

const DIFFICULTY_NAMES := {
	0: "Very Easy",
	1: "Easy",
	2: "Medium",
	3: "Hard",
	4: "Very Hard",
}

func populate(enemy_name: String, enemy_icon_texture: Texture2D) -> void:
	# Set enemy name
	enemy_text.set_text("[b]%s[/b]" % enemy_name)

	# Set character icon
	if enemy_icon_texture:
		character_icon.set_texture(enemy_icon_texture)

	# Set author
	var author = background.get_author_for_enemy(enemy_name)
	if author.is_empty():
		author_text.hide()
	else:
		author_text.show()
		author_text.set_text("by %s" % author)

	# Set difficulty
	var difficulty: int = background.get_difficulty_for_enemy(enemy_name)
	var difficulty_name: String = DIFFICULTY_NAMES.get(difficulty, "Medium")
	difficulty_text.set_text(difficulty_name)

	# Setup difficulty icons (1 for very easy, 5 for very hard)
	setup_difficulty_icons(difficulty)

func setup_difficulty_icons(difficulty: int) -> void:
	# Remove existing extra icons (keep first one)
	var children = difficulty_container.get_children()
	for i in range(children.size() - 1, 0, -1):
		children[i].queue_free()

	# VERY_EASY=0 -> 1 icon, EASY=1 -> 2 icons, etc.
	var icon_count: int = difficulty + 1

	# First icon is already there, add more if needed
	for i in range(icon_count - 1):
		var new_icon = difficulty_icon.duplicate()
		difficulty_container.add_child(new_icon)

func show_at_position(pos: Vector2) -> void:
	global_position = pos
	show()
