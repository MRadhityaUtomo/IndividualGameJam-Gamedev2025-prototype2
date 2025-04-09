extends Control

@onready var deck_size = $Deck
@onready var need_reload = $ReloadWarning
@onready var player = $"../../Player/CharacterBody2D"
@onready var card_manager = player.get_card_manager()

var flicker_timer := 0.5
var is_flickering := false

func _ready():
	print(card_manager)
	deck_size.text = str(card_manager.deck.size())
	if card_manager:
		card_manager.connect("deck_updated", self._on_deck_updated)
	need_reload.visible = false

func _process(delta):
	if is_flickering:
		flicker_timer += delta
		if flicker_timer >= 0.4:
			need_reload.visible = !need_reload.visible
			flicker_timer = 0.0

func _on_deck_updated(deck: Array):
	deck_size.text = str(deck.size())

	if deck.size() <= 0:
		need_reload.text = "[X] DECK IS EMPTY, PRESS R TO RELOAD"
		is_flickering = true
		need_reload.visible = true
	else:
		is_flickering = false
		need_reload.visible = false
