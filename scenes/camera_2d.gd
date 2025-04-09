extends Camera2D

var shake_amount = 0.0
var shake_decay = 1.5  # higher = faster decay
var shake_strength = 5.0  # max offset in pixels

func _process(delta):
	if shake_amount > 0:
		shake_amount -= shake_decay * delta
		offset = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_strength * shake_amount
	else:
		offset = Vector2.ZERO

func shake(intensity: float):
	shake_amount = clamp(shake_amount + intensity, 0, 1.0)
