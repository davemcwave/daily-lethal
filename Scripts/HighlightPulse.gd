extends RefCounted
class_name HighlightPulse
## The "this will be used" highlight for status boxes (buffs, debuffs) while an
## attack card is hovered: a gold glow and a gentle pulse.

const GLOW := Color(1.35, 1.2, 0.6)  # above 1.0 brightens: reads as a gold glow
const PULSE_SCALE := Vector2(1.08, 1.08)
const PULSE_SECONDS := 0.6

## Starts or stops the pulse on a control; returns the tween to keep (or null).
static func set_pulsing(control: Control, current: Tween, on: bool) -> Tween:
	if current != null and current.is_valid():
		current.kill()
	control.scale = Vector2.ONE
	if not on or not control.is_inside_tree():
		return null
	control.pivot_offset = control.size / 2.0
	var tween := control.create_tween().set_loops()
	tween.tween_property(control, "scale", PULSE_SCALE, PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(control, "scale", Vector2.ONE, PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
	return tween
