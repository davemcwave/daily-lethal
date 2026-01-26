extends Node
#class_name CardInteractionTester

@export var active: bool = false
@export var time_scale_speed: float = 5.0
@export var card_play_delay_seconds: float = 0.5
@export var test_puzzle_path: String = "res://Scenes/Puzzles/TestPuzzle.scn"
@export var test_cases_folder: String = "res://Resources/TestCases/"
@export var test_cases: Array[CardTestCase] = []
@export var auto_load_from_folder: bool = true
@export var pause_after_all_tests: bool = false  # Global pause option

var current_test_index: int = 0
var test_display_label: RichTextLabel = null
var tests_passed: int = 0
var tests_failed: int = 0
var continue_button: Button = null
var waiting_for_continue: bool = false

func _ready() -> void:
	if active:
		if auto_load_from_folder:
			load_test_cases_from_folder()
		truncate_file()

func load_test_cases_from_folder() -> void:
	var dir = DirAccess.open(test_cases_folder)
	if dir == null:
		push_error("Could not open test cases folder: %s" % test_cases_folder)
		return

	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".tres"):
			var resource_path = test_cases_folder + file
			var test_case = load(resource_path) as CardTestCase
			if test_case != null:
				test_cases.append(test_case)
				print("Loaded test case: %s" % test_case.test_name)
	dir.list_dir_end()

	print("Loaded %d test cases from folder" % test_cases.size())

func is_active() -> bool:
	return active

func get_test_puzzle() -> Puzzle:
	var puzzle: Puzzle = load(test_puzzle_path).instantiate()
	return puzzle

func create_test_display() -> void:
	var scene: Scene = get_tree().get_root().get_node('Scene')
	var canvas_layer = scene.get_node('CanvasLayer')

	# Create a panel for background
	var panel = PanelContainer.new()
	panel.name = "TestDisplayPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(10, 10)
	panel.size = Vector2(400, 350)

	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.border_color = Color(1, 1, 1, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	# Create a VBox to hold label and button
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Create the label
	test_display_label = RichTextLabel.new()
	test_display_label.name = "TestDisplayLabel"
	test_display_label.bbcode_enabled = true
	test_display_label.fit_content = true
	test_display_label.scroll_active = false
	test_display_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	test_display_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Create the continue button
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	button_style.set_corner_radius_all(4)
	button_style.set_content_margin_all(8)
	continue_button.add_theme_stylebox_override("normal", button_style)

	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	button_hover.set_corner_radius_all(4)
	button_hover.set_content_margin_all(8)
	continue_button.add_theme_stylebox_override("hover", button_hover)

	vbox.add_child(test_display_label)
	vbox.add_child(continue_button)
	panel.add_child(vbox)
	canvas_layer.add_child(panel)

	update_display("Initializing tests...", "", "")

func _on_continue_pressed() -> void:
	waiting_for_continue = false
	continue_button.visible = false

func show_continue_button() -> void:
	if continue_button != null:
		continue_button.visible = true
		waiting_for_continue = true

func wait_for_continue() -> void:
	# Pause time scale while waiting
	Engine.set_time_scale(1.0)
	while waiting_for_continue:
		await get_tree().process_frame
	Engine.set_time_scale(time_scale_speed)

func update_display(test_info: String, criteria: String, result: String) -> void:
	if test_display_label == null:
		return

	var text = "[b][color=yellow]== CARD INTERACTION TESTER ==[/color][/b]\n\n"
	text += "[b]Test %d / %d[/b]\n" % [current_test_index, test_cases.size()]
	text += "[color=cyan]%s[/color]\n\n" % test_info

	if criteria != "":
		text += "[b]Criteria:[/b]\n%s\n\n" % criteria

	if result != "":
		text += "[b]Result:[/b] %s\n\n" % result

	text += "[color=green]Passed: %d[/color] | [color=red]Failed: %d[/color]" % [tests_passed, tests_failed]

	test_display_label.text = text

func get_criteria_text(test: CardTestCase) -> String:
	var criteria_parts: Array[String] = []

	if test.expected_hand_count >= 0:
		criteria_parts.append("  Hand count: %d" % test.expected_hand_count)
	if test.expected_discard_count >= 0:
		criteria_parts.append("  Discard count: %d" % test.expected_discard_count)
	if test.expected_buff_count >= 0:
		criteria_parts.append("  Buff count: %d" % test.expected_buff_count)
	if test.expected_enemy_health >= 0:
		criteria_parts.append("  Enemy health: %d" % test.expected_enemy_health)
	if test.expected_energy >= 0:
		criteria_parts.append("  Energy: %d" % test.expected_energy)

	return "\n".join(criteria_parts)

func remove_test_display() -> void:
	if test_display_label != null:
		var panel = test_display_label.get_parent()
		if panel != null:
			panel.queue_free()
		test_display_label = null

func run_all_tests() -> void:
	Engine.set_time_scale(time_scale_speed)
	tests_passed = 0
	tests_failed = 0
	current_test_index = 0

	create_test_display()

	for test in test_cases:
		current_test_index += 1
		await run_test(test)
		await get_tree().create_timer(1.0).timeout

	update_display("ALL TESTS COMPLETE", "", "[color=yellow]Final Score: %d/%d[/color]" % [tests_passed, test_cases.size()])

	Engine.set_time_scale(1.0)
	print("=== ALL TESTS COMPLETE ===")

	# Keep display visible for a few seconds
	await get_tree().create_timer(5.0).timeout
	remove_test_display()

func setup_test_environment(test: CardTestCase) -> void:
	var scene: Scene = get_tree().get_root().get_node('Scene')
	var hand: Hand = scene.get_node('HandScrollContainer/Hand')
	var energy: Energy = scene.get_node('Energy')
	var discard_panel: DiscardPanel = scene.get_node('DiscardPanel')
	var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")

	# Clear existing hand
	for card in hand.get_cards():
		card.queue_free()
	await get_tree().process_frame

	# Clear discard pile
	for card in discard_panel.get_cards():
		card.queue_free()
	discard_panel.update_discard_count()
	await get_tree().process_frame

	# Clear buffs
	buffs_container.remove_all_buffs()

	# Set energy
	energy.set_energy(test.starting_energy)

	# Add test cards to hand
	for card_scene in test.cards_in_hand:
		var card: Card = card_scene.instantiate()
		card.set_state(Card.State.InHand)
		hand.add_child(card)

	await get_tree().process_frame
	hand.reorder_cards_by_x_position()

func run_test(test: CardTestCase) -> void:
	print("=== Running Test: %s ===" % test.test_name)

	var criteria_text = get_criteria_text(test)
	update_display(test.test_name, criteria_text, "[color=yellow]Running...[/color]")

	# Setup the test environment
	await setup_test_environment(test)

	var scene: Scene = get_tree().get_root().get_node('Scene')
	var hand: Hand = scene.get_node('HandScrollContainer/Hand')
	var energy: Energy = scene.get_node('Energy')
	var discard_panel: DiscardPanel = scene.get_node('DiscardPanel')
	var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
	var cards_choose_area: CardsChooseArea = scene.get_node('CanvasLayer/CardsChooseArea')
	var enemy: Enemy = scene.get_node('Enemy')

	# Play each card in the test sequence
	for card_scene in test.cards_to_play:
		var card: Card = card_scene.instantiate()

		if cards_choose_area.visible:
			play_card_in_choose_area(cards_choose_area, card)
		else:
			play_card(card)

		# Wait for buffs to finish animating
		while buffs_container.is_animating():
			await get_tree().create_timer(card_play_delay_seconds).timeout

		await get_tree().create_timer(card_play_delay_seconds).timeout

	# Wait a bit for all effects to resolve
	await get_tree().create_timer(1.0).timeout

	# Verify expected outcomes
	var passed = true
	var failure_reasons: Array[String] = []

	if test.expected_hand_count >= 0:
		var actual_hand_count = hand.get_cards().size()
		if actual_hand_count != test.expected_hand_count:
			passed = false
			failure_reasons.append("Hand: expected %d, got %d" % [test.expected_hand_count, actual_hand_count])

	if test.expected_discard_count >= 0:
		var actual_discard_count = discard_panel.get_card_count()
		if actual_discard_count != test.expected_discard_count:
			passed = false
			failure_reasons.append("Discard: expected %d, got %d" % [test.expected_discard_count, actual_discard_count])

	if test.expected_buff_count >= 0:
		var actual_buff_count = buffs_container.get_buff_count()
		if actual_buff_count != test.expected_buff_count:
			passed = false
			failure_reasons.append("Buffs: expected %d, got %d" % [test.expected_buff_count, actual_buff_count])

	if test.expected_enemy_health >= 0:
		var actual_enemy_health = enemy.get_health()
		if actual_enemy_health != test.expected_enemy_health:
			passed = false
			failure_reasons.append("Health: expected %d, got %d" % [test.expected_enemy_health, actual_enemy_health])

	if test.expected_energy >= 0:
		var actual_energy = energy.get_energy_amount()
		if actual_energy != test.expected_energy:
			passed = false
			failure_reasons.append("Energy: expected %d, got %d" % [test.expected_energy, actual_energy])

	# Update display and log result
	if passed:
		tests_passed += 1
		update_display(test.test_name, criteria_text, "[color=green][b]PASS[/b][/color]")
		write_result_to_file("%s: PASS" % test.test_name)
		print("%s: PASS" % test.test_name)
	else:
		tests_failed += 1
		var reason = "\n  ".join(failure_reasons)
		update_display(test.test_name, criteria_text, "[color=red][b]FAIL[/b][/color]\n  %s" % reason)
		write_result_to_file("%s: FAIL - %s" % [test.test_name, ", ".join(failure_reasons)])
		print("%s: FAIL - %s" % [test.test_name, ", ".join(failure_reasons)])

	# Wait for manual review if enabled (per-test or global)
	if test.pause_after_test or pause_after_all_tests:
		show_continue_button()
		await wait_for_continue()

func play_card(card: Card) -> void:
	var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
	for current_card: Card in hand.get_cards():
		if current_card.get_card_name() == card.get_card_name() and current_card.can_play_for_resolver():
			current_card.play()
			return

func play_card_in_choose_area(cards_choose_area: CardsChooseArea, card: Card) -> void:
	var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
	for current_card: Card in hand.get_cards():
		if current_card.get_card_name() == card.get_card_name():
			cards_choose_area.apply_action(current_card)
			cards_choose_area.close()
			return

func truncate_file():
	var path = "res://card-interaction-test-results.txt"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.close()
		print("Test results file cleared.")

func write_result_to_file(message: String):
	var path = "res://card-interaction-test-results.txt"

	if not FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.WRITE)
		f.close()

	var file = FileAccess.open(path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(message)
		file.close()
		print("Logged: %s" % message)
	else:
		push_error("Failed to open test results file.")
