extends StaticBody2D

@onready var card_manager = $CardManager
@onready var shoot_point = $ShootPoint
@onready var player = $"../Player/CharacterBody2D"
@onready var sprite = $Sprite2D
@onready var hitbox = $CollisionShape2D
@onready var health_bar = $"../CanvasLayer/EnemyHPBar"
@onready var damage_bar = $"../CanvasLayer/EnemyHPBar/DamageBar"
@onready var damage_timer = $DamageBarTimer

@export var speed = 40
@export var max_health = 1200
@export var health = max_health

var is_reloading = false
var used: int
var original_modulate := Color(1, 1, 1)  
var health_bar_base_position: Vector2
signal boss_died

@onready var cam = $"../Camera2D"



func _ready():
	$"../Warning".visible = false
	original_modulate = sprite.modulate  
	health_bar.max_value = max_health
	health_bar.value = health
	damage_bar.max_value = max_health
	damage_bar.value = health
	health_bar_base_position = health_bar.position

func _physics_process(delta: float) -> void:
	#var direction = (player.global_position - global_position).normalized()
	#velocity = lerp(velocity, direction * speed, 8.5*delta)
	look_at(player.global_position)
	rotation_degrees += 92.5


func take_damage(amount: int):
	$TakeHit.play()
	show_hit_flash()
	var prev_health = health
	
	health -= amount
	health = clamp(health, 0, max_health)
	if health < prev_health:
		damage_timer.start()
		shake_health_bar() 
	
	health_bar.value = health
	if health <= 0:
		hitbox.disabled = true
		emit_signal("boss_died")
		trigger_death_effects()
		die()

func shake_health_bar():
	var tween = get_tree().create_tween()
	tween.tween_property(health_bar, "position", health_bar_base_position + Vector2(6, 5), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(health_bar, "position", health_bar_base_position - Vector2(6, 5), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(health_bar, "position", health_bar_base_position, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func die():
	Engine.time_scale = 0.25
	await get_tree().create_timer(0.8).timeout
	Engine.time_scale = 1.0
	health_bar.fade_and_die()
	queue_free()

func show_hit_flash():
	if cam and cam.has_method("shake"):
		cam.shake(0.2) 
	var flash_color = Color(100, 100, 100)
	sprite.modulate = flash_color

	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func trigger_death_effects():
	#death_shake()
	if cam and cam.has_method("shake"):
		cam.shake(1.0) 


func _on_damage_bar_timer_timeout() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(damage_bar, "value", health, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
