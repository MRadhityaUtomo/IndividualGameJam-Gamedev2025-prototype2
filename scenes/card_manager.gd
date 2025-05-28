extends Node

@export var deck_data: Array[CardResource] 
var deck: Array[CardResource] = []
var deck_data_dup: Array[CardResource] = []
var current_card: CardResource = null
signal card_drawn(card)
signal deck_updated(deck: Array)


func _ready():
	emit_signal("deck_updated", deck)
	deck_data_dup = deck_data.duplicate()
	shuffle_deck()
	draw_card()

func shuffle_deck():
	deck = deck_data.duplicate()
	deck.shuffle()
	emit_signal("deck_updated", deck)
	
func reload_deck():
	if deck.size() == deck_data.size():
		return

	deck = deck_data_dup.duplicate()
	deck.shuffle()

	current_card = null
	draw_card()

	emit_signal("deck_updated", deck)


func draw_card():
	if deck.is_empty():
		current_card = null
		emit_signal("card_drawn", current_card)
		emit_signal("deck_updated", deck)
		return
	current_card = deck.pop_front()
	emit_signal("card_drawn", current_card)
	emit_signal("deck_updated", deck)
	
	
	
