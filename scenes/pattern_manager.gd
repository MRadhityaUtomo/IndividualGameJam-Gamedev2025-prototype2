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



func _process(delta):
	if is_reloading:
		return

	pattern_timer -= delta
	if pattern_timer <= 0:
		start_next_pattern()
		pattern_timer = pattern_interval

func start_next_pattern():
	if cards.deck.size() == 0 and not is_reloading:
		is_reloading = true
		print("PatternManager: Reloading cards...")
		await get_tree().create_timer(3.0).timeout
		cards.reload_deck()
		is_reloading = false
		return

	# Try to run queued pattern first if any
	if queued_patterns.size() > 0:
		var queued_card = queued_patterns[0]
		if can_run_pattern(queued_card.lock_tags):
			queued_patterns.pop_front()
			await run_card_pattern(queued_card)
			return

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

	await get_tree().create_timer(card.start_delay).timeout
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


func fire_cross_spin_pattern(card):
	var group = Node2D.new()
	group.global_position = centerspawn.global_position
	group.scale = Vector2.ZERO  # Start hidden
	get_tree().current_scene.add_child(group)

	var directions = [
		Vector2(1, 0),
		Vector2(-1, 0),
		Vector2(0, 1),
		Vector2(0, -1)
	]

	var bullets_per_arm = 24
	var spacing = 100

	for dir in directions:
		for i in range(1, bullets_per_arm + 1):
			var bullet = card.bullet_scene.instantiate()
			bullet.boss = Boss
			bullet.isCross = true
			bullet.position = dir * spacing * i
			bullet.speed = 0
			bullet.damage = card.bullet_damage
			group.add_child(bullet)

	# Pop-in tween (then spin after)
	var intro_tween = create_tween()
	intro_tween.tween_property(group, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	await intro_tween.finished


	await get_tree().create_timer(0.3).timeout  # 👈 Extra pause before rotation starts

	# Spin begins
	var duration := 10.0
	var spin_rate := 45.0
	var elapsed := 0.0

	while elapsed < duration:
		if not is_inside_tree():
			break
		await get_tree().process_frame
		var delta = get_process_delta_time()
		if delta == 0:
			break  # failsafe
		group.rotation += deg_to_rad(spin_rate * delta)
		elapsed += delta

	# Exit animation
	var exit_tween = create_tween()
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

		# Alternate offset each wave
		offset = angle_step / 2.0 if offset == 0.0 else 0.0
		await get_tree().create_timer(card.fire_delay).timeout

func fire_flower_pattern(card):
	var waves: int = 15
	var count: int = card.bullet_count
	var angle_step: float = 360.0 / float(count)
	var rotation_offset: float = 0.0  # this will spiral the waves

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

		# Spiral effect: gradually rotate the whole ring each wave
		rotation_offset += angle_step / 3.0  # tweak for petal tightness
		await get_tree().create_timer(card.fire_delay).timeout
	

func fire_spin_pattern(card):
	var normal_speed = Boss.speed
	Boss.speed = 0 
	var duration := 6.0  # total time to keep spinning and firing
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

		spin_angle += 15  # degrees per burst
		await get_tree().create_timer(card.fire_delay).timeout
		elapsed += card.fire_delay
	Boss.speed = normal_speed
