extends Node

signal sleight_triggered(card_names: Array)
signal sleight_updated(buffer: Array)
signal sleight_used(buffer: Array)


var card_buffer: Array = []
@export var sleight_data: Array[SleightRecipe]

var player = null

func _ready():
	player = $"../CharacterBody2D"# assuming this is a child of the Player node


func add_card_to_buffer(card):
	if card_buffer.size() < 3:
		card_buffer.append(card)
		print("Card added to buffer: ", card.card_name)
		emit_signal("sleight_updated", card_buffer)
	else:
		print("❌ Sleight buffer full!")

func try_activate_sleight():
	if card_buffer.size() < 3:
		print("❌ Not enough cards for a sleight!")
		return

	var combo = card_buffer.map(func(c): return c.card_name)
	combo.sort()  # Ensure consistent matching order
	print("combo: ")
	print(combo)
	print(player.mana)

	for recipe in sleight_data:
		var sorted_recipe = recipe.card_names.duplicate()
		sorted_recipe.sort()
		print("sorted recipe: ")
		print(sorted_recipe)
		print("==============")

		if sorted_recipe == combo:
			var cost = recipe.mana_cost
			if cost == -1:
				cost = card_buffer.reduce(func(accum, c): return accum + c.mana_cost, 0)
				if cost > player.max_mana:
					cost = player.max_mana
				print(cost)
			else:
				cost = recipe.mana_cost
				print("combo cost: " + str(cost))

			if player.mana >= cost:
				player.mana -= cost
				print("✅ Sleight triggered: ", recipe.name)

				emit_signal("sleight_triggered", combo)
				card_buffer.clear()
				emit_signal("sleight_updated", card_buffer)
				emit_signal("sleight_used", card_buffer)
			else:
				print("❌ Not enough mana!")
			return
	
	print("❌ No matching sleight!")
	card_buffer.clear()
	player.canshoot = true
	emit_signal("sleight_updated", card_buffer)
	emit_signal("sleight_used", card_buffer)
