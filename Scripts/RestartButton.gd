extends Button

@onready var attempts_container = get_parent().get_node("AttemptsGridContainer")
@onready var scene = get_parent()
func _on_pressed():
	attempts_container.verify_solution()
	await attempts_container.verified_solution
	scene.save_attempt()
	
	get_tree().reload_current_scene()
