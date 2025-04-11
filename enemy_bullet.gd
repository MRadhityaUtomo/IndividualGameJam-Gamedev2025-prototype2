extends Area2D

var speed: float
var damage: int
var isCross: bool
var boss: Node = null  # This will be set manually
var target_position: Vector2
var converging: bool = false
var velocity: Vector2 = Vector2.ZERO



func _ready():
	add_to_group("enemy_bullet")
	
	if get_tree().get_first_node_in_group("player_body") != null:
		var player = get_tree().get_first_node_in_group("player_body")
		if player.has_signal("player_died"):
			player.connect("player_died", Callable(self, "_on_player_died"))
			
func _on_player_died():
	set_process(false)
	set_physics_process(false)
	fade_and_die()
	
func _physics_process(delta: float):
	if converging:
		# stays still
		return
	
	if velocity != Vector2.ZERO:
		global_position += velocity * delta
	
	if not get_viewport_rect().grow(100).has_point(global_position) and isCross == false:
		queue_free()
	position -= transform.y * speed * delta
	if not get_viewport_rect().grow(100).has_point(global_position) and isCross == false:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player_body"):
		if body.has_method("take_damage") and not body.is_invincible:
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
