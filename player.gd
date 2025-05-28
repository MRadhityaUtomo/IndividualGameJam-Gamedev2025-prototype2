extends CharacterBody2D

@export var speed: float = 310.0
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.1
@export var max_dash_charges: int = 3
@export var dash_cooldown: float = 1.3
@export var maxhealth: int = 100
@export var health: int = maxhealth

@onready var player = $".." #Marker2D
@onready var spawnpos = $PlayerBulletSpawn #Marker2D
@onready var card_system = $"../CardManager"
@onready var healthbar = $"../../CanvasLayer/PlayerHpBar"
@onready var sleight_manager = $"../SleightManager"
@onready var graze_zone = $GraceZone
@onready var hitbox = $HurtArea/CollisionShape2D
@onready var reload_bar = $"../../CanvasLayer/ReloadBar"
@onready var healthLabel = $"../../CanvasLayer/PlayerStatsUI/HealthBar"
@onready var dash_bars := [
	$"../../CanvasLayer/PlayerStatsUI/DashUI/dashcharge1",
	$"../../CanvasLayer/PlayerStatsUI/DashUI/dashcharge2",
	$"../../CanvasLayer/PlayerStatsUI/DashUI/dashcharge3"
]
@onready var muzzleflash = $muzzleflash
@onready var sprite = $SpritesNode
@onready var boss = $"../../BossEnemy"

var original_modulate := Color(1, 1, 1)  
var is_dashing: bool = false
var dash_time: float = 0.0
var dash_charges: int = max_dash_charges
var dash_cooldown_timer: float = 0.0
var grazing_bullets: int = 0
var graze_mana_rate: float = 50.0  
var is_invincible: bool = false

var is_reloading: bool = false
var reload_timer: float = 0.0
var reload_duration: float = 1.0
var fade_tween: Tween

var graze_cooldown: float = 0.0 
var graze_timer := 0.0
var is_grazed := false

const normal_mana_regen = 10.0
var mana: float = 100.0
var max_mana: float = 100.0
var mana_regen_rate: float = normal_mana_regen  

signal sleight_triggered(card_names: Array)


var bullet = preload("res://scenes/player_bullet.tscn")
var DashBurst = preload("res://scenes/dash_trail.tscn")
var canshoot = true

func get_sleight_manager():
	return sleight_manager

func get_card_manager():
	return card_system

func _physics_process(delta: float) -> void:
	var screen_rect = get_viewport_rect()
	var margin = 50
	global_position.x = clamp(global_position.x, screen_rect.position.x + margin, screen_rect.position.x + screen_rect.size.x - margin)
	global_position.y = clamp(global_position.y, screen_rect.position.y + margin, screen_rect.position.y + screen_rect.size.y - margin)

	look_at(get_global_mouse_position())
	rotation_degrees += 92.5

	var direction = Vector2.ZERO
	if Input.is_action_pressed("d"):
		direction.x += 1
	if Input.is_action_pressed("a"):
		direction.x -= 1
	if Input.is_action_pressed("s"):
		direction.y += 1
	if Input.is_action_pressed("w"):
		direction.y -= 1
	
	direction = direction.normalized()
	
	if Input.is_action_just_pressed("space") and not is_dashing and dash_charges > 0:
		$dashfx.play()
		is_dashing = true
		dash_time = dash_duration
		dash_charges -= 1
		dash_cooldown_timer = dash_cooldown 
		update_dash_ui() 

		# Spawn burst at the current position (dash start)
		var burst = DashBurst.instantiate()
		get_tree().current_scene.add_child(burst)
		burst.global_position = global_position
		burst.rotation = direction.angle() - 92.5
	if is_dashing:
		hitbox.disabled = true
		velocity = direction * dash_speed
		dash_time -= delta
		if dash_time <= 0:
			is_dashing = false
			await get_tree().create_timer(0.2).timeout
			hitbox.disabled = false
			update_dash_ui() 
	else:
		velocity = direction * speed
	
	if dash_charges < max_dash_charges:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			dash_charges += 1
			dash_cooldown_timer = dash_cooldown
	
	move_and_slide()

func _on_shootspeed_timeout() -> void:
	canshoot = true

func _process(delta):
	#$GraceZone/GraceZoneCollision.disabled = true
	$CollisionShape2D.disabled = true
	
	update_dash_ui() 
	if is_reloading:
		reload_timer += delta
		reload_bar.value = reload_timer / reload_duration
		if reload_timer >= reload_duration:
			card_system.reload_deck()
			is_reloading = false
			reload_bar.visible = false
		return  # skip input while reloading
	if graze_timer > 0:
		graze_timer -= delta
		
	if (sleight_manager.card_buffer.size() == 3):
		canshoot = false
	if Input.is_action_just_pressed("ui_down"):
		print(card_system.deck)
		
	mana = clamp(mana + mana_regen_rate * delta, 0, max_mana)
	
	if grazing_bullets > 0:
		is_grazed = true
		#$grazed.play()
		if !$AnimatedSprite2D.visible:
			$AnimatedSprite2D.visible = true
			$AnimatedSprite2D.modulate.a = 0.0
			$AnimatedSprite2D.play()

			if fade_tween:
				fade_tween.kill()
			fade_tween = create_tween()
			fade_tween.tween_property($AnimatedSprite2D, "modulate:a", 0.1, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		mana += graze_mana_rate * delta
		mana = clamp(mana, 0, max_mana)
	else:
		#$grazed.stop()
		is_grazed = false
		if $AnimatedSprite2D.visible:
			if fade_tween:
				fade_tween.kill()
			fade_tween = create_tween()
			fade_tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			fade_tween.finished
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.visible = false
		
		
	if Input.is_action_just_pressed("shoot") and canshoot:
		if card_system.current_card == null:
			$ReloadAudio.play()
			start_reload()
			return
		use_card()
	
	if Input.is_action_just_pressed("reload") and not is_reloading:
		$ReloadAudio.play()
		start_reload()
		
	if Input.is_action_just_pressed("store sleight"):
		if sleight_manager.card_buffer.size() != 3:
			$CardSleighted.play()
			store_card_for_sleight()
		else:
			sleight_manager.try_activate_sleight()
			
	elif Input.is_action_just_pressed("activate sleight"):
		sleight_manager.try_activate_sleight()
		
		
func _ready() -> void:
	update_dash_ui() 
	add_to_group("player_body")
	$HurtArea.add_to_group("player_hurtbox")
	sleight_manager.connect("sleight_triggered", Callable(self, "_on_sleight_triggered"))
	graze_zone.connect("area_entered", Callable(self, "_on_graze_area_entered"))
	graze_zone.connect("area_exited", Callable(self, "_on_graze_area_exited"))

func update_dash_ui():
	for i in range(max_dash_charges):
		if i < dash_charges:
			# Full charge
			dash_bars[i].value = 1.0
			dash_bars[i].modulate = Color.WHITE
		elif i == dash_charges:
			# Currently recharging this bar
			if dash_cooldown_timer > 0:
				var fill_amount = 1.0 - (dash_cooldown_timer / dash_cooldown)
				dash_bars[i].value = fill_amount
				dash_bars[i].modulate = Color(1, 1, 1, 0.5)
			else:
				dash_bars[i].value = 0.0
				dash_bars[i].modulate = Color(1, 1, 1, 0.3)
		else:
			# Not yet recharging
			dash_bars[i].value = 0.0
			dash_bars[i].modulate = Color(1, 1, 1, 0.3)

func start_reload():
	var current_deck_size = card_system.deck.size()
	var base_reload_time = 0.5
	var max_reload_time = 2.5

	var deck_ratio = float(current_deck_size) / float(card_system.deck_data.size())
	reload_duration = lerp(base_reload_time, max_reload_time, deck_ratio)
	is_reloading = true
	reload_bar.value = 0
	reload_bar.visible = true
	reload_timer = 0.0



func use_card():
	var card = card_system.current_card
	if card == null:
		print("No card available!")
		return
	
	if mana < card.mana_cost:
		return

	mana -= card.mana_cost
	if card.is_burst:
		fire_burst(card)
	else:
		fire_spread(card)
	card_system.draw_card()

	

func fire_burst(card):
	await get_tree().create_timer(0.01).timeout  
	for i in range(card.bullet_count):
		var bullet = card.bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.player = player
		bullet.global_position = spawnpos.global_position
		bullet.global_rotation = rotation
		bullet.speed = card.bullet_speed
		bullet.damage = card.bullet_damage
		muzzleflash.stop()
		muzzleflash.play()
		await get_tree().create_timer(card.fire_delay).timeout
		
func fire_spread(card):
	var base_angle = rotation
	var count = card.bullet_count
	var spread = card.spread_angle
	muzzleflash.stop()
	muzzleflash.play()
	for i in range(count):
		var angle_offset = spread * ((i - (count - 1) / 2.0) / max(1, count - 1))
		var bullet = card.bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.player = player
		bullet.global_position = spawnpos.global_position
		bullet.global_rotation = base_angle + deg_to_rad(angle_offset)
		bullet.speed = card.bullet_speed
		bullet.damage = card.bullet_damage

func store_card_for_sleight():
	var card = card_system.current_card
	if card == null:
		print("No card to store!")
		return
	
	if sleight_manager.card_buffer.size() == 3:
		print("full")
		return
	sleight_manager.add_card_to_buffer(card)
	card_system.draw_card()
	
func _on_sleight_triggered(card_names: Array):
	var combo = card_names.duplicate()
	combo.sort()

	#Check sleight combinations
	if combo == ["spread 3", "spread 3", "spread 3"].map(func(n): return n.to_lower()):
		fire_super_spread_burst(0, 0, 1, preload("res://card_sleights/sleight_combo1.tres"))
	
	if combo == ["spread 5", "spread 5", "spread 5"].map(func(n): return n.to_lower()):
		fire_super_spread_burst(1, 0.2, 8, preload("res://card_sleights/super_spread_big.tres"))
		
	if combo == ["burst shot", "burst shot", "burst shot"].map(func(n): return n.to_lower()):
		fire_burst_barrage(preload("res://card_sleights/burst_barrage.tres"))
		
	if combo == ["burst shot", "spread 3", "spread 5"].map(func(n): return n.to_lower()):
		fire_spirit_bomb(preload("res://card_sleights/spirit_bomb.tres"))
	canshoot = true
	
func fire_spirit_bomb(recipe: SleightRecipe):
	var bomb = recipe.bullet_scene.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = spawnpos.global_position
	bomb.global_rotation = rotation
	bomb.speed = recipe.bullet_speed
	bomb.damage = recipe.bullet_damage
	mana_regen_rate = 0
	await get_tree().create_timer(1).timeout 
	mana_regen_rate = normal_mana_regen


func fire_burst_barrage(recipe: SleightRecipe):
	var barrage_duration = 1.5  
	var fire_interval = 0.1     
	var end_time = Time.get_ticks_msec() / 1000.0 + barrage_duration
	var offset = 15
	var spread_degrees = 8  # max angle variation, adjust for wider/narrower spray

	mana_regen_rate = 0 
	while Time.get_ticks_msec() / 1000.0 < end_time:
		if health == 0:
			return
		for side in [-1, 1]:
			muzzleflash.stop()
			muzzleflash.play()
			var bullet = preload("res://scenes/player_bullet.tscn").instantiate()
			get_tree().current_scene.add_child(bullet)
			bullet.player = player
			var offset_pos = spawnpos.global_position + (spawnpos.transform.x.normalized() * offset * side)
			bullet.global_position = offset_pos

			# Add random spread in degrees converted to radians
			var spread_angle = deg_to_rad(randf_range(-spread_degrees, spread_degrees))
			bullet.global_rotation = rotation + spread_angle

			bullet.speed = recipe.bullet_speed 
			bullet.damage = recipe.bullet_damage
		await get_tree().create_timer(fire_interval).timeout
		
	await get_tree().create_timer(0.5).timeout
	mana_regen_rate = normal_mana_regen


func fire_super_spread_burst(mana_cooldown: float, delay_between_bursts: float, burst_count: int,recipe: SleightRecipe):
	var count = recipe.bullet_count
	var spread = recipe.spread_angle
	mana_regen_rate = 0
	for b in range(burst_count):
		if health == 0:
			return
		muzzleflash.stop()
		muzzleflash.play()
		for i in range(count):
			var angle_offset = spread * ((i - (count - 1) / 2.0) / max(1, count - 1))
			var bullet = recipe.bullet_scene.instantiate()
			get_tree().current_scene.add_child(bullet)
			bullet.player = player
			bullet.global_position = spawnpos.global_position
			bullet.global_rotation = rotation + deg_to_rad(angle_offset)
			bullet.speed = recipe.bullet_speed
			bullet.damage = recipe.bullet_damage
		await get_tree().create_timer(delay_between_bursts).timeout
	await get_tree().create_timer(mana_cooldown).timeout
	mana_regen_rate = normal_mana_regen


func _on_graze_area_entered(area):
	if area.is_in_group("enemy_bullet"):
		grazing_bullets += 1

func _on_graze_area_exited(area):
	if area.is_in_group("enemy_bullet"):
		grazing_bullets = max(0, grazing_bullets - 1)
		
func shake_sprite(duration := 0.2, intensity := 3.0):
	var original_position = sprite.position
	var time_passed = 0.0
	while time_passed < duration:
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		sprite.position = original_position + offset
		await get_tree().create_timer(0.02).timeout
		time_passed += 0.02
	sprite.position = original_position



signal player_died
func take_damage(amount: int):
	if is_invincible:
		return
	$Damaged.play()
	healthbar.shake_health_bar()
	shake_label(healthLabel, amount)
	show_hit_flash()
	shake_sprite()
	health -= amount
	if health <= 0:
		canshoot = false
		health = 0 
		sleight_manager.card_buffer.clear()
		await get_tree().create_timer(0.1).timeout
		emit_signal("player_died")
	else:
		start_invincibility(0.4) 
		
func shake_label(label: Label, damage: int):
	var tween := create_tween()
	var original_pos: Vector2 = label.position 
	
	var intensity: float = clamp(damage * 1.0, 4.0, 16.0)

	for i in range(4):
		var random_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(label, "position", original_pos + random_offset, 0.02).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(label, "position", original_pos, 0.02).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


		
func start_invincibility(duration: float):
	is_invincible = true
	hitbox.disabled = true
	await get_tree().create_timer(duration).timeout
	is_invincible = false
	hitbox.disabled = false

		
func show_hit_flash():
	var flash_color = Color(100, 100, 100)
	sprite.modulate = flash_color

	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
