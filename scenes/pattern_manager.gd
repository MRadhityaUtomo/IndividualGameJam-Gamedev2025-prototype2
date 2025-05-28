extends Node2D

@onready var shoot_point = $"../ShootPoint"
@onready var cards = $"../CardManager"
@onready var Boss = $".."
@onready var centerspawn = $"../CenterSpawnPoint"



var pattern_timer := 0.0
var pattern_interval := 1.5
var is_reloading := false
var used_cards := 0
var active_locks: Array[String] = []
var queued_patterns: Array[CardResource] = []
var patterns_enabled := false  



func _process(delta):
	if not patterns_enabled or is_reloading:
		return

	pattern_timer -= delta
	if pattern_timer <= 0:
		start_next_pattern()
		pattern_timer = pattern_interval

func start_patterns():
	patterns_enabled = true

func start_next_pattern():
	print(queued_patterns)
	# Try to run queued pattern
	for i in queued_patterns.size():
		var queued_card = queued_patterns[i]
		if can_run_pattern(queued_card.lock_tags):
			queued_patterns.remove_at(i)
			await run_card_pattern(queued_card)
			return

	# If no cards in deck and nothing runnable is in the queue, then reload
	if cards.deck.size() == 0 and not is_reloading:
		is_reloading = true
		print("PatternManager: Reloading cards...")
		await get_tree().create_timer(2.0).timeout
		cards.reload_deck()
		is_reloading = false
		return

	# Otherwise, draw a new card
	cards.draw_card()
	var card = cards.current_card
	if not card:
		return

	if not can_run_pattern(card.lock_tags):
		queued_patterns.append(card)
		print("Queued due to lock:", card.card_name)
		return

	await run_card_pattern(card)

signal target_attacks
func run_card_pattern(card: CardResource) -> void:
	used_cards += 1
	print("PatternManager: Used %s cards" % used_cards)
	print("card name: " + card.card_name)

	#if card.pattern_type == "BURST":
		#_show_burst_preview(card)
	
	if card.card_name == "cannon" or card.pattern_type == "CROSS_SPIN" or card.pattern_type == "DASHBURST":
		$"../../Warning".position = Boss.global_position
		$"../../Warning".visible = true
		$"../../Warning".play()
		
	if card.card_name == "dashnburst":
		emit_signal("target_attacks")
		$"../../Target".visible = true
		$"../../Target".play()
		$"../Sprites/Sprite2D".speed_scale = 3
		$"../Sprites/Thrusters".speed_scale = 3

	await get_tree().create_timer(card.start_delay).timeout
	
	$"../../Warning".visible = false
	$"../../Warning".stop()
	#_hide_burst_preview()  
	add_locks(card.lock_tags)
	match card.pattern_type:
		"BURST":
			await fire_burst_pattern(card)
		"SPIRAL":
			await fire_spiral_pattern(card)
		"SPIN":
			await fire_spin_pattern(card)
		"ALTERNATE_RING":
			await fire_alternate_ring_pattern(card)
		"FLOWER":
			await fire_flower_pattern(card)
		"CROSS_SPIN":
			await fire_cross_spin_pattern(card)
		"SPREAD":
			await fire_spread_pattern(card)
		"DASHBURST":
			await fire_dashspiral_pattern(card)
		#"CONVERGE":
			#await fire_converge_circle_pattern(card)
		_:
			print("PatternManager: Unknown pattern type -", card.pattern_type)

	$"../../Target".visible = false
	$"../../Target".stop()
	remove_locks(card.lock_tags)

## Attack limit 
func can_run_pattern(lock_tags: Array[String]) -> bool:
	for tag in lock_tags:
		if tag in active_locks:
			return false
	return true

func add_locks(lock_tags: Array[String]) -> void:
	for tag in lock_tags:
		active_locks.append(tag)

func remove_locks(lock_tags: Array[String]) -> void:
	for tag in lock_tags:
		active_locks.erase(tag)
## Attack limit

func fire_burst_pattern(card):
	for i in range(card.bullet_count):
		var bullet = card.bullet_scene.instantiate()
		bullet.boss = Boss 
		bullet.global_position = shoot_point.global_position
		bullet.global_rotation = shoot_point.global_rotation
		bullet.speed = card.bullet_speed
		bullet.damage = card.bullet_damage
		get_tree().current_scene.add_child(bullet)

func _show_burst_preview(card):
	var line = shoot_point.get_node("PreFireLine")
	if not line:
		return
	line.visible = true
	var direction = (Boss.player.global_position - shoot_point.global_position).normalized()
	var length = 1000  
	line.points = [Vector2.ZERO, direction * length]

func _hide_burst_preview():
	var line = shoot_point.get_node("PreFireLine")
	if line:
		line.visible = false
		
## STILL BROKEN ATTACK
#func fire_converge_circle_pattern(card):
	#var player = Boss.player
	#if player == null:
		#return
#
	#var target_position = player.global_position
	#var bullet_count = card.bullet_count
	#var radius = card.orbit_radius  # how far around the player the bullets spawn
	#var converge_delay = card.convergence_delay
#
	#for i in range(bullet_count):
		#var angle = TAU * i / bullet_count
		#var spawn_pos = target_position + Vector2.RIGHT.rotated(angle) * radius
#
		#var bullet = card.bullet_scene.instantiate()
		#bullet.boss = Boss
		#bullet.damage = card.bullet_damage
		#bullet.speed = 0  # start stationary
		#bullet.global_position = spawn_pos
		#bullet.target_position = target_position  # we'll use this in the bullet script
		#bullet.converging = true  # custom flag to trigger convergence later
		#get_tree().current_scene.add_child(bullet)
#
	#await get_tree().create_timer(converge_delay).timeout
#
	#for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
		#if bullet.converging and bullet.has_method("start_converge"):
			#bullet.start_converge()


func fire_spread_pattern(card):
	var bullet_count = card.bullet_count
	var spread_angle = card.spread_angle
	var angle_step = spread_angle / max(1, bullet_count - 1)
	var start_angle = -spread_angle / 2.0

	for i in range(bullet_count):
		var angle_deg = start_angle + i * angle_step
		var angle_rad = deg_to_rad(angle_deg) + shoot_point.global_rotation 

		var bullet = card.bullet_scene.instantiate()
		bullet.boss = Boss
		bullet.global_position = shoot_point.global_position
		bullet.global_rotation = angle_rad
		bullet.speed = card.bullet_speed
		bullet.damage = card.bullet_damage
		get_tree().current_scene.add_child(bullet)



func fire_cross_spin_pattern(card: CardResource) -> void:
	var group: Node2D = Node2D.new()
	group.global_position = centerspawn.global_position
	group.scale = Vector2.ZERO
	get_tree().current_scene.add_child(group)

	var arm_count: int = max(1, card.bullet_count)  
	var bullets_per_arm: int = 24
	var spacing: float = card.per_arm_dist  
	var angle_step: float = TAU / float(arm_count)  

	for arm_index: int in arm_count:
		var direction: Vector2 = Vector2.RIGHT.rotated(angle_step * arm_index)
		for i: int in range(1, bullets_per_arm + 1):
			var bullet: Node2D = card.bullet_scene.instantiate()
			bullet.boss = Boss
			bullet.isCross = true
			bullet.position = direction * spacing * i
			bullet.speed = 0
			bullet.damage = card.bullet_damage
			group.add_child(bullet)

	var intro_tween: Tween = create_tween()
	intro_tween.tween_property(group, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	await intro_tween.finished

	await get_tree().create_timer(card.start_delay).timeout

	var duration: float = card.cross_spin_duration
	var spin_rate: float = card.cross_spin_speed
	var elapsed: float = 0.0

	while elapsed < duration:
		if not is_inside_tree():
			break
		await get_tree().process_frame
		var delta: float = get_process_delta_time()
		if delta == 0.0:
			break
		group.rotation += deg_to_rad(spin_rate * delta)
		elapsed += delta

	var exit_tween: Tween = create_tween()
	exit_tween.tween_property(group, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(group, "modulate:a", 0.0, 0.2)
	await exit_tween.finished

	group.queue_free()


func fire_spiral_pattern(card):
	await get_tree().create_timer(card.start_delay).timeout
	var count = card.bullet_count
	for i in range(count):
		var bullet = card.bullet_scene.instantiate()
		bullet.boss = Boss 
		var angle = i * (360 / count)
		bullet.global_position = shoot_point.global_position
		bullet.global_rotation = deg_to_rad(angle)
		bullet.speed = card.bullet_speed
		bullet.damage = card.bullet_damage
		get_tree().current_scene.add_child(bullet)

### UAS ASSIGNMENT ###
#### MAKE THE BOSS MOVE. THE BOSS WILL MOVE TO THE TARGET DIRECTION OF THE CURRENT PLAYER POSITION BEFORE FIRING (IN THIS CASE I USED THE SPIRAL PATTERN BECAUSE IT'S INSTANT AND SIMPLE)
signal spiral
func fire_dashspiral_pattern(card):
	# GET THE PLAYER POSITION
	Boss.target_direction = Boss.player.global_position
	Boss.spiral = true
	emit_signal("spiral") # SPAWN INDICATOR ON MAIN SCENE
	$"../../Target".visible = false
	$"../../Target".stop()
	var dash_speed = 700.0
	var arrival_threshold = 4.0 

	# DASH
	while Boss.global_position.distance_to(Boss.target_direction) > arrival_threshold:
		var dir = (Boss.target_direction - Boss.global_position).normalized()
		Boss.velocity = dir * dash_speed
		Boss.move_and_slide()
		if Boss.cam and Boss.cam.has_method("shake"):
			Boss.cam.shake(0.2) 
		await get_tree().create_timer(0.001).timeout
	
	$"../Sprites/Sprite2D".speed_scale = 1
	$"../Sprites/Thrusters".speed_scale = 1
	var count = card.bullet_count
	$"../smash".play()
	$"../smash2".play()
	
	# SHOOT SPIRAL PATTERN FROM NEW POSITION 
	for i in range(count):
		var bullet = card.bullet_scene.instantiate()
		bullet.boss = Boss 
		var angle = i * (360 / count)
		bullet.global_position = $"../CenterSpawnPoint".global_position
		bullet.global_rotation = deg_to_rad(angle)
		bullet.speed = card.bullet_speed
		bullet.damage = card.bullet_damage
		get_tree().current_scene.add_child(bullet)
	Boss.velocity = Vector2.ZERO
	Boss.spiral = false

#signal spiral
#func fire_dashspiral_pattern(card):
	#Boss.target_direction = Boss.player.global_position
	#Boss.tracking_enabled = false
	#Boss.spiral = true
	#emit_signal("spiral")
	#$"../../Target".visible = false
	#$"../../Target".stop()
	#var dash_speed = 700.0
	#var arrival_threshold = 4.0  # Distance where we stop the dash
#
	#while Boss.global_position.distance_to(Boss.target_direction) > arrival_threshold:
		#var dir = (Boss.target_direction - Boss.global_position).normalized()
		#Boss.velocity = dir * dash_speed
		#Boss.move_and_slide()
		#await get_tree().create_timer(0.01).timeout
#
	## Snap to exact target pos if needed (optional)
	## Boss.global_position = Boss.target_direction
	#$"../Sprites/Sprite2D".speed_scale = 1
	#$"../Sprites/Thrusters".speed_scale = 1
	#Boss.velocity = Vector2.ZERO
	#Boss.tracking_enabled = true
	#Boss.spiral = false
#
	#var count = card.bullet_count
	#for i in range(count):
		#var bullet = card.bullet_scene.instantiate()
		#bullet.boss = Boss 
		#var angle = i * (360 / count)
		#bullet.global_position = Boss.shoot_point.global_position
		#bullet.global_rotation = deg_to_rad(angle)
		#bullet.speed = card.bullet_speed
		#bullet.damage = card.bullet_damage
		#get_tree().current_scene.add_child(bullet)



#signal spiral
#func fire_spiral_pattern(card):
	#Boss.target_direction = Boss.player.global_position
	#emit_signal("spiral")
	#await get_tree().create_timer(1).timeout
	#var count = card.bullet_count
	#for i in range(count):
		#var bullet = card.bullet_scene.instantiate()
		#bullet.boss = Boss 
		#var angle = i * (360 / count)
		#bullet.global_position = shoot_point.global_position
		#bullet.global_rotation = deg_to_rad(angle)
		#bullet.speed = card.bullet_speed
		#bullet.damage = card.bullet_damage
		#get_tree().current_scene.add_child(bullet)
	#Boss.spiral = false
	
func fire_alternate_ring_pattern(card):
	var total_waves: int = 10  # Number of alternating waves
	var count: int = card.bullet_count
	var angle_step: float = 360.0 / float(count)
	var offset: float = 0.0

	for wave in range(total_waves):
		for i in range(count):
			var angle: float = deg_to_rad(i * angle_step + offset)
			var bullet = card.bullet_scene.instantiate()
			bullet.boss = Boss 
			bullet.global_position = shoot_point.global_position
			bullet.global_rotation = angle
			bullet.speed = card.bullet_speed
			bullet.damage = card.bullet_damage
			get_tree().current_scene.add_child(bullet)

		offset = angle_step / 2.0 if offset == 0.0 else 0.0
		await get_tree().create_timer(card.fire_delay).timeout

func fire_flower_pattern(card):
	var waves: int = 20
	var count: int = card.bullet_count
	var angle_step: float = 360.0 / float(count)
	var rotation_offset: float = 0.0 

	for wave in range(waves):
		for i in range(count):
			var angle: float = deg_to_rad(i * angle_step + rotation_offset)
			var bullet = card.bullet_scene.instantiate()
			bullet.boss = Boss 
			bullet.global_position = shoot_point.global_position
			bullet.global_rotation = angle
			bullet.speed = card.bullet_speed
			bullet.damage = card.bullet_damage
			get_tree().current_scene.add_child(bullet)

		rotation_offset += angle_step / 3.0  
		await get_tree().create_timer(card.fire_delay).timeout
	

func fire_spin_pattern(card):
	var normal_speed = Boss.speed
	Boss.speed = 0 
	var duration := 6.0 
	var elapsed := 0.0
	var spin_angle := 0.0

	while elapsed < duration:
		var base_angle = deg_to_rad(spin_angle)

		for i in range(card.bullet_count):
			var angle = base_angle + deg_to_rad(card.spread_angle) * i
			var bullet = card.bullet_scene.instantiate()
			bullet.boss = Boss 
			get_tree().current_scene.add_child(bullet)

			bullet.global_position = shoot_point.global_position
			bullet.global_rotation = angle
			bullet.speed = card.bullet_speed
			bullet.damage = card.bullet_damage

		spin_angle += 15  
		await get_tree().create_timer(card.fire_delay).timeout
		elapsed += card.fire_delay
	Boss.speed = normal_speed
