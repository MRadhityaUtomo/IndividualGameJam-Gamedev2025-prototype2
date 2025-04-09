extends Area2D

var speed: float
var damage: int
var isCross: bool
var boss: Node = null  # This will be set manually



func _ready():
	add_to_group("enemy_bullet")
	
func _physics_process(delta: float):
	position -= transform.y * speed * delta
	if not get_viewport_rect().grow(100).has_point(global_position) and isCross == false:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player_body"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()

func _process(delta: float) -> void:
	if (boss == null or !is_instance_valid(boss)):
		fade_and_die()
		
func fade_and_die():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
