extends Node2D


@onready var player = $Player/CharacterBody2D
@onready var playerSleights = $Player/SleightManager
@onready var boss = $BossEnemy
@onready var card_manager = player.get_card_manager()
@onready var card_slot = $CanvasLayer/CardSlotRoot
@onready var mana_label = $CanvasLayer/ManaLabel
@onready var mana_bar = $CanvasLayer/ManaBar
@onready var healthbar = $CanvasLayer/PlayerStatsUI/HealthBar
@onready var Actualhealthbarhehe = $CanvasLayer/PlayerHpBar
@onready var SpeedTimer = $CanvasLayer/SpeedTimer
@onready var BlinkTimer = $CanvasLayer/SpeedTimer/BlinkTimer
@onready var BossHPBar = $CanvasLayer/EnemyHPBar
@onready var loading_screen = $CanvasLayer/LoadingScreen
@onready var BossPatternManager = $BossEnemy/PatternManager
@onready var RestartLabel = $CanvasLayer/RestartLabel
@onready var BGMStart = $BGMStart
@onready var BGMloop = $BGMLoop
@onready var dash_charges = $Player/CharacterBody2D.dash_charges

var blink_tween: Tween = null
var is_label_visible := true
var can_restart := false
var boss_timer_active := false
var boss_fight_time := 0.0


func _ready():
	loading_screen.visible = true
	loading_screen.position = Vector2(0, 0)
	Actualhealthbarhehe.max_value = player.maxhealth
	BGMStart.play()
	BGMStart.finished.connect(_on_BGMSstart_finished)
	await get_tree().create_timer(0.5).timeout  
	var tween = create_tween()
	tween.tween_property(loading_screen, "position", Vector2(0, -loading_screen.size.y), 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	await tween.finished
	
	loading_screen.visible = false
	BossPatternManager.start_patterns()
	start_boss_timer()
	card_manager.card_drawn.connect(card_slot.show_card)
	card_slot.show_card(card_manager.current_card)
	boss.connect("boss_died", self._on_boss_defeated)
	BossPatternManager.connect("target_attacks", self._on_boss_target_attack)
	player.connect("player_died", self._on_player_died)
	
func _on_boss_target_attack():
	pass
	#$Target.visible = true
	#$Target.play()
	
	
	
	
func _on_BGMSstart_finished():
	BGMloop.play()

func _on_player_died():
	$FinalHit.play()
	for audio in [$BGMStart, $BGMLoop]:
		if audio.playing:
			var fade = create_tween()
			fade.tween_property(audio, "volume_db", -40, 1.0)  # Fade to -40dB over 1 second
			fade.set_trans(Tween.TRANS_SINE)
			fade.set_ease(Tween.EASE_OUT)
			
	BGMloop.stop()
	BGMStart.stop()
	
	player.speed = 100
	player.dash_speed = 0

	var bgm_fade = create_tween()
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0

	Actualhealthbarhehe.fade_and_die()

	var screen_slide = $CanvasLayer/ScreenFade
	$Switch.play()
	screen_slide.visible = true
	screen_slide.position = Vector2(0, get_viewport_rect().size.y)

	var tween = create_tween()
	tween.tween_property(screen_slide, "position", Vector2(0, 0), 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished
	await get_tree().change_scene_to_file("res://scenes/game_over.tscn")



func _process(delta):
	$Target.global_position = player.global_position
	if player:
		mana_label.text = "MANA: [ %.2f / %.2f ]" % [player.mana, player.max_mana]
		mana_bar.max_value = player.max_mana
		mana_bar.value = player.mana
		Actualhealthbarhehe.max_value = player.maxhealth
		Actualhealthbarhehe.value = player.health
		
		var percent = clamp(float(player.health) / float(player.maxhealth) * 100.0, 0.0, 100.0)
		healthbar.text = "[<3] %d %%" % int(percent)
		
		if player.is_grazed:
			mana_label.text += " [+ GRAZE +]"
		else:
			mana_label.text = "MANA: [ %.2f / %.2f ]" % [player.mana, player.max_mana]

		
	if boss_timer_active:
		boss_fight_time += delta
		update_timer_label()
	if can_restart and Input.is_action_just_pressed("enter"):
		$Switch.play()
		var viewport_size = get_viewport_rect().size
		loading_screen.position = Vector2(0, viewport_size.y)  # Start just below screen
		loading_screen.visible = true

		var tween = create_tween()
		var slide_duration = 0.2
		var target_pos = Vector2(0, 0)

		tween.tween_property(loading_screen, "position", target_pos, slide_duration)\
			.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		await tween.finished

		await get_tree().create_timer(0.5).timeout  

		Engine.time_scale = 1.0  
		get_tree().reload_current_scene()
	if !boss:
		$Warning.visible = false
		$Target.visible = false
		


func start_boss_timer():
	boss_timer_active = true
	boss_fight_time = 0.0

func _on_boss_defeated():
	player.is_invincible = true
	$Warning.stop()
	$Warning.visible = false
	$FinalHit.play()

	for audio in [$BGMStart, $BGMLoop]:
		if audio.playing:
			var fade = create_tween()
			fade.tween_property(audio, "volume_db", -40, 1.0)
			fade.set_trans(Tween.TRANS_SINE)
			fade.set_ease(Tween.EASE_OUT)

	stop_boss_timer()
	$Warning.visible = false


func stop_boss_timer():
	boss_timer_active = false
	start_blinking_timer_label()
	can_restart = true
	RestartLabel.visible = true

func start_blinking_timer_label():
	BlinkTimer.start()
	
func _on_BlinkTimer_timeout():
	is_label_visible = !is_label_visible
	SpeedTimer.visible = is_label_visible

func update_timer_label():
	var total_ms = int(boss_fight_time * 100)
	var minutes = total_ms / 6000
	var seconds = (total_ms / 100) % 60
	var milliseconds = total_ms % 100

	var time_string = "%02d : %02d : %02d" % [minutes, seconds, milliseconds]
	SpeedTimer.text = time_string 
