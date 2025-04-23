extends GridContainer

signal verified_solution

@onready var scene = get_parent()
@onready var background = get_node("/root/Background")

func _ready():
	verify_solutions()
	#for attempt_panel: Panel in get_children():
		#attempt_panel.add_theme_stylebox_override("panel", attempt_panel.get_theme_stylebox("panel").duplicate(DUPLICATE_USE_INSTANTIATION))
func verify_solutions() -> void:
	var solution: Array[String] = scene.get_solution()
	for attempt: Array[String] in background.get_attempts():
		var attempt_number: int = 0
		for i in range(len(solution)):
			var attempt_panel: Panel = get_child(i * attempt_number)
			if i >= attempt.size():
				attempt_panel.self_modulate = Color.RED
				continue
			var attempt_card_name: String = attempt[i]
			var solution_card_name: String = solution[i]
			
			if attempt_card_name == solution_card_name:
				attempt_panel.self_modulate = Color('59fc56')
			elif attempt_card_name != solution_card_name:
				attempt_panel.self_modulate = Color('fcbf56')
				
			await get_tree().create_timer(0.1).timeout
		attempt_number += 1
func verify_solution() -> void:
	var attempt: Array[String] = scene.get_attempt()
	var attempt_number: int = background.get_attempts().size() + 1
	var solution: Array[String] = scene.get_solution()
	
	for i in range(len(solution)):
		var attempt_panel: Panel = get_child(i * attempt_number)
		if i >= attempt.size():
			attempt_panel.self_modulate = Color.RED
			continue
		var attempt_card_name: String = attempt[i]
		var solution_card_name: String = solution[i]
		
		if attempt_card_name == solution_card_name:
			attempt_panel.self_modulate = Color('59fc56')
		elif attempt_card_name != solution_card_name:
			attempt_panel.self_modulate = Color('fcbf56')
			
		await get_tree().create_timer(0.1).timeout
		
	emit_signal('verified_solution')
