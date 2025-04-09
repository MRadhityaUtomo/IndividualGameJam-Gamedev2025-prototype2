extends Control

@onready var slot1 = $Slots/VBoxContainer/Slot1
@onready var slot2 = $Slots/VBoxContainer2/Slot2
@onready var slot3 = $Slots/VBoxContainer3/Slot3
@onready var slot1Label = $HBoxContainer/Label
@onready var slot2Label = $HBoxContainer/Label2
@onready var slot3Label = $HBoxContainer/Label3
@onready var tween = get_tree().create_tween()


@onready var player = $"../../Player/CharacterBody2D"
@onready var slots = [slot1,slot2,slot3]
@onready var slotLabel = [slot1Label,slot2Label,slot3Label]

var idle_sway_tweens = {}


func _ready():
	var sleight_manager = player.get_sleight_manager()
	print(sleight_manager)
	if sleight_manager:
		sleight_manager.connect("sleight_updated", self._on_sleight_updated)
		sleight_manager.connect("sleight_used", self._on_sleight_used)

		
func _on_sleight_updated(buffer: Array):
	for i in slots.size():
		var slot = slots[i]
		var label = slotLabel[i]

		if idle_sway_tweens.has(i):
			idle_sway_tweens[i].kill()
			idle_sway_tweens.erase(i)

		if i < buffer.size():
			var card = buffer[i]
			slot.texture = card.card_image
			label.text = card.card_name

			# Reset transform
			slot.scale = Vector2.ONE
			slot.rotation_degrees = 0

			# Pop effect
			var tween = get_tree().create_tween()
			tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.08)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.12)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

			# Start idle sway
			var idle_tween = get_tree().create_tween()
			idle_tween.set_loops()
			idle_tween.tween_property(slot, "rotation_degrees", -2.5, 0.5)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			idle_tween.tween_property(slot, "rotation_degrees", 2.5, 1.0)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			idle_tween.tween_property(slot, "rotation_degrees", 0.0, 0.5)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

			idle_sway_tweens[i] = idle_tween

		else:
			# 🔧 Make sure to reset empty slot visuals
			slot.texture = load("res://myassets/card_base-export.png")
			label.text = "[X] EMPTY"
			slot.rotation_degrees = 0
			slot.scale = Vector2.ONE




			
			
func _on_sleight_used(buffer: Array):
	for i in slots.size():
		var slot = slots[i]
		slot.texture = load("res://myassets/card_base-export.png")

		# Kill any idle sway tween
		if idle_sway_tweens.has(i):
			idle_sway_tweens[i].kill()
			idle_sway_tweens.erase(i)

		# Reset rotation just in case
		slot.rotation_degrees = 0
		
