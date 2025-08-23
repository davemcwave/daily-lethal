extends Camera2D
class_name CustomCamera

@export var decay = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(50, 25)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).
@export var max_trauma = 0.6
@export var enable_shake: bool = false

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

func add_trauma(amount):
	trauma = min(trauma + amount, max_trauma)

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()

#func _input(event):
	#if event.is_action_pressed("ui_accept"):
		#add_trauma(0.2)
		
func shake():
	if !enable_shake:
		return
		
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)
