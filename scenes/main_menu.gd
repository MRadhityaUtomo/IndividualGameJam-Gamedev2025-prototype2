extends Control

@onready var mainpanel = $MainPanel
@onready var play_button = $MainPanel/HBoxContainer/Play
@onready var loading_screen = $LoadingScreen
@onready var loading_screen2 = $LoadingScreen2
@onready var postprocessing = $PostProcessing/ColorRect
@onready var staticimage = $TextureRect

func _ready():
	loading_screen.visible = false
	$MainPanel/Title.play()
	postprocessing.mouse_filter = MOUSE_FILTER_IGNORE
	loading_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_screen.position = Vector2(0, get_viewport_rect().size.y)
	staticimage.position = Vector2(0, get_viewport_rect().size.y)
	
	loading_screen2.visible = true
	loading_screen2.position = Vector2(0, 0)
	await get_tree().create_timer(0.5).timeout  
	var tween = create_tween()
	tween.tween_property(loading_screen2, "position", Vector2(0, -loading_screen.size.y), 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	await tween.finished

func _on_play_pressed():
	$Switch.play()
	loading_screen.visible = true
	play_button.disabled = true

	var screen_size = get_viewport_rect().size
	var tween = create_tween()
	var slide_duration = 0.3

	tween.tween_property(mainpanel, "position", Vector2(0, -screen_size.y), slide_duration)
	tween.tween_property(loading_screen, "position", Vector2(0, 0), slide_duration)

	await tween.finished
	await get_tree().create_timer(0.5).timeout

	await get_tree().change_scene_to_file("res://scenes/test_scene.tscn")

func _on_exit_pressed():
	$Switch.play()
	staticimage.visible = true
	var screen_size = get_viewport_rect().size
	var tween = create_tween()
	var slide_duration = 0.3
	tween.tween_property(mainpanel, "position", Vector2(0, -screen_size.y), slide_duration)
	tween.tween_property(staticimage, "position", Vector2(0, 0), slide_duration)
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
