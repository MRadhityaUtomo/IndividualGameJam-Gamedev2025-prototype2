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
	# Try to run queued pattern first
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


func run_card_pattern(card: CardResource) -> void:
	used_cards += 1
	print("PatternManager: Used %s cards" % used_cards)
	print("card name: " + card.card_name)

	#if card.pattern_type == "BURST":
		#_show_burst_preview(card)
	
	if card.pattern_type == "BURST" or card.pattern_type == "CROSS_SPIN":
		$"../../Warning".visible = true
		$"../../Warning".play()

	await get_tree().create_timer(card.start_delay).timeout

	#_hide_burst_preview()  
	add_locks(card.lock_tags)
	$"../../Warning".visible = false
	$"../../Warning".stop()
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
		#"CONVERGE":
			#await fire_converge_circle_pattern(card)
		_:
			print("PatternManager: Unknown pattern type -", card.pattern_type)

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
	#var original_speed = Boss.speed
	#var dash_speed = 900
	#var dash_duration = 0.4
	#Boss.speed = 10
	#await get_tree().create_timer(0.5).timeout
	## Move quickly toward player
	#Boss.speed = dash_speed
	#await get_tree().create_timer(dash_duration).timeout

	# Stop movement briefly before firing
	#Boss.speed = 0
	#await get_tree().create_timer(0.5).timeout  # Pause before firing (optional, adds tension)

	# Fire bullets in all directions
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
	## Resume normal movement
	#await get_tree().create_timer(1.4).timeout 
	#Boss.speed = original_speed

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
	var waves: int = 15
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
