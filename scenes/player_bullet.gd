extends Node2D

var speed: float
var damage: int
var player: Node = null


func _ready() -> void:
	player = get_tree().get_root().get_node("TestScene/Player/CharacterBody2D")  # Adjust this path
	player.connect("player_died", self.fade_and_die)

func _physics_process(delta: float):
	position -= transform.y * speed * delta
	if not get_viewport_rect().grow(100).has_point(global_position):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.name == ("BossEnemy"):  # Use group for flexibility
		if body.has_method("take_damage"):
			body.take_damage(damage)  # Or pass a damage value
		queue_free()
		
func fade_and_die():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
