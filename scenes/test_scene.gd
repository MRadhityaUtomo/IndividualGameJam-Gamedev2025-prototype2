extends Node2D


@onready var player = $Player/CharacterBody2D
@onready var boss = $BossEnemy
@onready var card_manager = player.get_card_manager()
@onready var card_slot = $CanvasLayer/CardSlotRoot
@onready var mana_label = $CanvasLayer/ManaLabel
@onready var mana_bar = $CanvasLayer/ManaBar
@onready var healthbar = $CanvasLayer/PlayerStatsUI/HealthBar
@onready var SpeedTimer = $CanvasLayer/SpeedTimer
@onready var BlinkTimer = $CanvasLayer/SpeedTimer/BlinkTimer
@onready var BossHPBar = $CanvasLayer/EnemyHPBar

var blink_tween: Tween = null
var is_label_visible := true



func _ready():
	start_boss_timer()
	card_manager.card_drawn.connect(card_slot.show_card)
	card_slot.show_card(card_manager.current_card)
	boss.connect("boss_died", self._on_boss_defeated)

func _process(delta):
	if player:
		mana_label.text = "Mana: " + str(round(player.mana)) + " / " + str(player.max_mana)
		mana_bar.max_value = player.max_mana
		mana_bar.value = player.mana
		
	if player:
		healthbar.text = "HP: " + str(round(player.health)) + " /100 "
		
	if boss_timer_active:
		boss_fight_time += delta
		update_timer_label()
		
var boss_timer_active := false
var boss_fight_time := 0.0

func start_boss_timer():
	boss_timer_active = true
	boss_fight_time = 0.0

func _on_boss_defeated():
	stop_boss_timer()

func stop_boss_timer():
	boss_timer_active = false
	start_blinking_timer_label()

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
	SpeedTimer.text = time_string  # adjust path if needed
