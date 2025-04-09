extends Node2D

var speed: float
var damage: int

func _physics_process(delta: float):
	position -= transform.y * speed * delta
	if not get_viewport_rect().grow(100).has_point(global_position):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.name == ("BossEnemy"):  # Use group for flexibility
		if body.has_method("take_damage"):
			body.take_damage(damage)  # Or pass a damage value
		queue_free()
