extends Control

@onready var card_art = $CardArt
@onready var card_label = $CardLabel
@onready var tween = get_tree().create_tween()
@onready var audio = $AudioStreamPlayer2D

func show_card(card: CardResource):
	if card == null:
		card_art.texture = null
		card_label.text = ""
	else:
		audio.play()
		card_art.texture = card.card_image
		card_label.text = card.card_name + ", [Cost: " + str(card.mana_cost) + "]"

		# Reset scale before tweening
		scale = Vector2(-2, 1)

		# Kill the previous tween if it's still running
		if tween.is_valid():
			tween.kill()

		# Create a new pop tween
		tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
