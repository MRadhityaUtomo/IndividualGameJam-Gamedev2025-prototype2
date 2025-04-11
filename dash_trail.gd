extends Node2D


# DashBurst.gd (attached to root of the scene)
func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D.connect("animation_finished", self._on_anim_finished)

func _on_anim_finished(anim_name):
	queue_free()
