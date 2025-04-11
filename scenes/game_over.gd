extends Control

@onready var retryButton = $GameOverPanel/Retry
@onready var postprocessing = $PostProcessing/ColorRect
@onready var loading_screen = $LoadingScreen
@onready var gameover_panel = $GameOverPanel
@onready var menubutton = $GameOverPanel/BackToMenu

func _ready():
	postprocessing.mouse_filter = MOUSE_FILTER_IGNORE
	loading_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_screen.position = Vector2(0, get_viewport_rect().size.y)

func _on_retry_pressed():
	$Switch.play()
	retryButton.disabled = true

	var tween = create_tween()
	var screen_size = get_viewport_rect().size
	var slide_duration = 0.3
	tween.tween_property(gameover_panel, "position", Vector2(0, -screen_size.y), slide_duration)
	tween.tween_property(loading_screen, "position", Vector2(0, 0), slide_duration)
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	await get_tree().change_scene_to_file("res://scenes/test_scene.tscn")


func _on_back_to_menu_pressed() -> void:
	$Switch.play()
	menubutton.disabled = true

	var tween = create_tween()
	var screen_size = get_viewport_rect().size
	var slide_duration = 0.3
	tween.tween_property(gameover_panel, "position", Vector2(0, -screen_size.y), slide_duration)
	tween.tween_property(loading_screen, "position", Vector2(0, 0), slide_duration)
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	await get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
