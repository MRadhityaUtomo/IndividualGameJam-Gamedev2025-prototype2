#extends Node2D
#
#@onready var mana_label = $CanvasLayer/ManaLabel
#@onready var player = $Player/CharacterBody  # or wherever your mana is stored
#
#func _process(delta):
	#if player:
		#mana_label.text = "Mana: " + str(round(player.mana)) + " / " + str(player.max_mana)
