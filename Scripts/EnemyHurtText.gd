extends RichTextLabel

@export var offset: float = 100.0   # how far to move
@export var duration: float = 1.0  # seconds

func play_hurt_text(text: String, from_pos: Vector2):
	set_text(text)
	
	# Set starting position
	position = from_pos
	
	# Compute local X axis from current rotation
	var local_x := Vector2(cos(rotation), sin(rotation))
	
	# Target position is offset along local X
	var target_pos := position + local_x * offset
	
	# Tween position
	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, duration/2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Also fade out
	modulate.a = 1.0
	tween.tween_property(self, "modulate:a", 0.0, duration+1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Cleanup
	tween.finished.connect(queue_free)
#
#func _input(event):
	#if event.is_action_pressed("ui_accept"):
		#play_hurt_text("[b]oooouchhhh![/b]",position)
