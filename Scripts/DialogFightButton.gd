extends Button

@export var shake_strength: float = 1.0   # pixels
@export var shake_speed: float = 1.0     # shake frequency

var _shaking: bool = false
var _original_pos: Vector2
var _rng := RandomNumberGenerator.new()
var _time_accum: float = 0.0

func _ready() -> void:
	_rng.randomize()
	_original_pos = position
	start_shake()

func _process(delta: float) -> void:
	if _shaking:
		_time_accum += delta
		var offset := Vector2(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		).normalized() * shake_strength * sin(_time_accum * shake_speed)
		position = _original_pos + offset
	else:
		position = _original_pos

func start_shake() -> void:
	_shaking = true
	_time_accum = 0.0

func stop_shake() -> void:
	_shaking = false
	position = _original_pos
