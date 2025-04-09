extends ProgressBar
var health_bar_base_position: Vector2


func fade_and_die():
	var tween = create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()

func shake_health_bar():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", health_bar_base_position + Vector2(6, 5), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", health_bar_base_position - Vector2(6, 5), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", health_bar_base_position, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
