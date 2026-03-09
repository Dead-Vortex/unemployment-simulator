extends Node2D

@onready var camera : Camera2D = $Camera2D

# Player Pieces
@onready var player1 = $Goat
@onready var player2 = $Bag
@onready var player3 = $Cards
@onready var player4 = $Milk # these might be useless? if they are i will remove them (this is a reminder)
var player_piece_names : Dictionary = {1: "Goat", 2: "Bag", 3: "Cards", 4: "Milk"}
var current_player : int = 1
var living_humans : int = 4

# UI
@onready var status_label = $CanvasLayer/PanelContainer/VBoxContainer/StatusLabel
@onready var die_button = $CanvasLayer/PanelContainer/VBoxContainer/Dice
@onready var purchase_sad_meal_button = $CanvasLayer/PanelContainer/VBoxContainer/BuySadMeal
@onready var eat_sad_meal_button = $CanvasLayer/PanelContainer/VBoxContainer/SadMeal
@onready var rhymes_with_grug_button = $CanvasLayer/PanelContainer/VBoxContainer/Drug # I have an idea!
@onready var status_update = $CanvasLayer/StatusUpdate

# Other shitty ui i needed for some bullshit
@onready var second_ui = $CanvasLayer/SpaceUI
@onready var second_ui_text_label = $CanvasLayer/SpaceUI/VBoxContainer/PoorTextLabel
@onready var second_ui_button1 = $CanvasLayer/SpaceUI/VBoxContainer/Button1
@onready var second_ui_button2 = $CanvasLayer/SpaceUI/VBoxContainer/Button2
signal second_ui_button
var second_ui_last_pressed_button : int = 1

# Turn logic
var before_turn : bool = true
signal die_rolled
var die_roll : int = 2

var die_roll_jail1 : int = 1
var die_roll_jail2 : int = 2

var player_stats : Array = [ # Self explanitory.
	{"money": 10, "hunger": 0, "inebriation": 0, "sadmeals": 1, "drugs": 0, "space": 0, "jail": 0, "alive": true},
	{"money": 10, "hunger": 0, "inebriation": 0, "sadmeals": 1, "drugs": 0, "space": 0, "jail": 0, "alive": true},
	{"money": 10, "hunger": 0, "inebriation": 0, "sadmeals": 1, "drugs": 0, "space": 0, "jail": 0, "alive": true},
	{"money": 10, "hunger": 0, "inebriation": 0, "sadmeals": 1, "drugs": 0, "space": 0, "jail": 0, "alive": true}
]

# Board Spaces
var police_inspection_spaces : Array = [1, 10, 13, 17, 19, 25]
var dark_alleyway_spaces : Array = [4, 8, 12, 16, 20, 23, 26]
var heist_spaces : Array = [3, 6, 9, 27]
var npc_spaces : Array = [5, 11, 15, 18, 22, 24]
# Start - 0
# Unemployment Tax - 2
# Casino - 7
# Just Visiting - 14
# Bar - 21

# Cards
var dark_alleyway_cards : Array = [0, 0, 0, 0, 0, 1, 2, 2, 2, 1, 1, 1, 3, 3, 3, 4, 1, 1, 4, 4, 5, 5, 6, 6]
var dark_alleyway_outcomes : Dictionary = {0: "Gain 1 Drug", 1: "Gain 1 Sad Meal", 2: "Gain 2 Drugs", 3: "Lose $1", 4: "Lose $5", 5: "Lose 1 Sad Meal", 6: "Lose 2 Drugs"}
var dark_alleyway_card : int = 0

var heist_cards : Array = [
	{"task": "Roll an odd number", "success": "Gain 3 Drugs", "fail": "Pay $2", "acceptable_rolls": [1, 3, 5], "success_prize": ["drugs", 3], "fail_penalty": ["money", -2]},
	{"task": "Roll a 5 or 6", "success": "Gain $10", "fail": "Go to Jail", "acceptable_rolls": [5, 6], "success_prize": ["money", 10], "fail_penalty": ["jail"]},
	{"task": "Roll an even number", "success": "Gain 2 Drugs", "fail": "Pay $1", "acceptable_rolls": [2, 4, 6], "success_prize": ["drugs", 2], "fail_penalty": ["money", -1]},
	{"task": "Roll a 1", "success": "Gain 10 Sad Meals", "fail": "Pay $5", "acceptable_rolls": [1], "success_prize": ["sadmeals", 10], "fail_penalty": ["money", -5]},
	{"task": "Roll a 2 or 3", "success": "Gain 2 Sad Meals", "fail": "Lose 2 Sad Meals", "acceptable_rolls": [2, 3], "success_prize": ["sadmeals", 2], "fail_penalty": ["sadmeals", -2]},
	{"task": "Roll between 2-5", "success": "Gain $3", "fail": "Go to Jail", "acceptable_rolls": [2, 3, 4, 5], "success_prize": ["money", 3], "fail_penalty": ["jail"]},
	{"task": "Roll an even number", "success": "Gain $4", "fail": "Go to Jail", "acceptable_rolls": [2, 4, 6], "success_prize": ["money", 4], "fail_penalty": ["jail"]},
	{"task": "Roll an odd number", "success": "Gain $2", "fail": "Move back 2 spaces", "acceptable_rolls": [1, 3, 5], "success_prize": ["money", 2], "fail_penalty": ["spaces", -2]},
	{"task": "Roll an even number", "success": "Gain 4 Drugs", "fail": "Pay $6", "acceptable_rolls": [2, 4, 6], "success_prize": ["drugs", 4], "fail_penalty": ["money", -6]},
	{"task": "Roll a 1 or 2", "success": "Gain $4", "fail": "Go to Jail", "acceptable_rolls": [1, 2], "success_prize": ["money", 4], "fail_penalty": ["jail"]},
]
var heist_card : int = 0

func _ready() -> void:
	if player_stats[0]["alive"] == false:
		player1.visible = false
		living_humans -= 1
	if player_stats[1]["alive"] == false:
		player2.visible = false
		living_humans -= 1
	if player_stats[2]["alive"] == false:
		player3.visible = false
		living_humans -= 1
	if player_stats[3]["alive"] == false:
		player4.visible = false
		living_humans -= 1
	status_message("Arrow Keys to move camera")
	while living_humans > 1:
		if player_stats[0]["alive"] == true:
			await(game_turn(1))
		if player_stats[1]["alive"] == true:
			await(game_turn(2))
		if player_stats[2]["alive"] == true:
			await(game_turn(3))
		if player_stats[3]["alive"] == true:
			await(game_turn(4))
	if player_stats[0]["alive"] == true:
		print("Goat wins the game!")
		status_message("Goat wins the game!")
	if player_stats[1]["alive"] == true:
		print("Bag wins the game!")
		status_message("Bag wins the game!")
	if player_stats[2]["alive"] == true:
		print("Cards wins the game!")
		status_message("Cards wins the game!")
	if player_stats[3]["alive"] == true:
		print("Milk wins the game!")
		status_message("Milk wins the game!")

func _process(delta: float) -> void:
	# Camera controls
	camera.global_position.x += Input.get_axis("camera_left", "camera_right") * 1000 * delta
	camera.global_position.y += Input.get_axis("camera_up", "camera_down") * 1000 * delta
	# I feel like there's a better way to do this but i dont know how so have unoptimized camera bounds
	if camera.global_position.x < -232:
		camera.global_position.x = -232
	elif camera.global_position.x > 232:
		camera.global_position.x = 232
	if camera.global_position.y > 568:
		camera.global_position.y = 568
	elif camera.global_position.y < -568:
		camera.global_position.y = -568
		
	#camera.zoom += Vector2(Input.get_axis("camera_zoom_out", "camera_zoom_in") * delta, Input.get_axis("camera_zoom_out", "camera_zoom_in") * delta)

func game_turn(player):
	current_player = player
	# Initialize UI
	die_button.disabled = false
	if player_stats[player - 1]["jail"] != -1:
		player_stats[player - 1]["hunger"] += 1
		player_stats[player - 1]["inebriation"] -= 1
		if player_stats[player - 1]["inebriation"] < 0:
			player_stats[player - 1]["inebriation"] = 0
		if player_stats[player - 1]["hunger"] >= 10 or player_stats[player - 1]["inebriation"] >= 10:
			eliminate_player(player)
			return
	else:
		player_stats[player - 1]["jail"] = 0
	update_ui()
	if player_stats[player - 1]["jail"] == 0:
		# Die Roll
		await(die_rolled)
		die_button.disabled = true
		purchase_sad_meal_button.disabled = true
		eat_sad_meal_button.disabled = true
		rhymes_with_grug_button.disabled = true
		for i in randi_range(6, 10):
			if player_stats[player - 1]["inebriation"] >= 4:
				die_roll = (randi_range(1, 6) + randi_range(1, 6))
			else:
				die_roll = randi_range(1, 6)
			die_button.text = str(die_roll)
			await get_tree().create_timer(0.2).timeout
		await get_tree().create_timer(0.5).timeout
		await(move_player_spaces(player, die_roll))
		
		# Board Space Actions
		if police_inspection_spaces.has(player_stats[player - 1]["space"]):
			print(player_piece_names[player] + " landed on Police Inspection")
			status_message((player_piece_names[player] + " landed on Police Inspection"))
			die_button.text = "Roll Die (Police)"
			die_button.disabled = false
			await(die_rolled)
			die_button.disabled = true
			for i in randi_range(6, 10):
				die_roll = randi_range(1, 6)
				die_button.text = str(die_roll)
				await get_tree().create_timer(0.2).timeout
			await get_tree().create_timer(0.5).timeout
			if die_roll == 1:
				die_button.text = "Safe"
			elif die_roll == 2 or die_roll == 3:
				if player_stats[player - 1]["drugs"] > 0:
					imprison(player)
					die_button.text = ">0 Drugs, Jail"
				else:
					die_button.text = "No Drugs, Safe"
			elif die_roll == 4 or die_roll == 5:
				if player_stats[player - 1]["inebriation"] >= 4:
					imprison(player)
					die_button.text = "Inebriated, Jail"
				else:
					move_player_spaces(player, -2)
					die_button.text = "Low Inebriation, Back 2"
			elif die_roll == 6:
				if player_stats[player - 1]["money"] >= 10:
					player_stats[player - 1]["money"] -= 10
					status_label.text = (player_piece_names[current_player] +
					" - $" + str(player_stats[current_player - 1]["money"]) +
					"\nHunger: " + str(player_stats[current_player - 1]["hunger"]) +
					"/10\nInebriation: " + str(player_stats[current_player - 1]["inebriation"]) + "/10")
					die_button.text = "Pay $10"
				else:
					imprison(player)
					die_button.text = "<$10, Jail"
			await get_tree().create_timer(2).timeout
			
			
		elif dark_alleyway_spaces.has(player_stats[player - 1]["space"]):
			print(player_piece_names[player] + " landed on Dark Alleyway")
			status_message((player_piece_names[player] + " landed on Dark Alleyway"))
			die_button.text = "Draw Card"
			die_button.disabled = false
			await(die_rolled)
			die_button.disabled = true
			for i in randi_range(6, 10):
				dark_alleyway_card = dark_alleyway_cards.pick_random()
				die_button.text = str(dark_alleyway_outcomes[dark_alleyway_card])
				await get_tree().create_timer(0.2).timeout
			await get_tree().create_timer(0.8).timeout
			if dark_alleyway_card == 0:
				player_stats[player - 1]["drugs"] += 1
			elif dark_alleyway_card == 1:
				player_stats[player - 1]["sadmeals"] += 1
			elif dark_alleyway_card == 2:
				player_stats[player - 1]["drugs"] += 2
			elif dark_alleyway_card == 3:
				player_stats[player - 1]["money"] -= 1
				if player_stats[player - 1]["money"] < 0:
					player_stats[player - 1]["money"] = 0
			elif dark_alleyway_card == 4:
				player_stats[player - 1]["money"] -= 5
				if player_stats[player - 1]["money"] < 0:
					player_stats[player - 1]["money"] = 0
			elif dark_alleyway_card == 5:
				player_stats[player - 1]["sadmeals"] -= 1
				if player_stats[player - 1]["sadmeals"] < 0:
					player_stats[player - 1]["sadmeals"] = 0
			elif dark_alleyway_card == 6:
				player_stats[player - 1]["drugs"] -= 2
				if player_stats[player - 1]["drugs"] < 0:
					player_stats[player - 1]["drugs"] = 0
					
					
		elif heist_spaces.has(player_stats[player - 1]["space"]):
			print(player_piece_names[player] + " landed on Heist")
			status_message((player_piece_names[player] + " landed on Heist"))
			heist_card = randi_range(0, 9)
			second_ui_text_label.text = heist_cards[heist_card]["task"] + "\nSuccess: " + heist_cards[heist_card]["success"] + "\nFail: " + heist_cards[heist_card]["fail"]
			second_ui_button1.text = "Roll Die"
			second_ui_button2.text = "Decline"
			second_ui_button1.disabled = false
			second_ui_button2.disabled = false
			second_ui.visible = true
			await(second_ui_button)
			if second_ui_last_pressed_button == 1:
				second_ui_button1.disabled = true
				second_ui_button2.disabled = true
				for i in randi_range(6, 10):
					die_roll = randi_range(1, 6)
					second_ui_button1.text = str(die_roll)
					await get_tree().create_timer(0.2).timeout
				await get_tree().create_timer(0.5).timeout
				if heist_cards[heist_card]["acceptable_rolls"].has(die_roll):
					second_ui_button1.text = "Success!"
					player_stats[player - 1][heist_cards[heist_card]["success_prize"][0]] += heist_cards[heist_card]["success_prize"][1]
				elif heist_cards[heist_card]["fail_penalty"][0] == "jail":
					second_ui_button1.text = "Failed!"
					imprison(player)
				elif heist_cards[heist_card]["fail_penalty"][0] == "spaces":
					second_ui_button1.text = "Failed!"
					await(move_player_spaces(player, heist_cards[heist_card]["fail_penalty"][1]))
				else:
					second_ui_button1.text = "Failed!"
					player_stats[player - 1][heist_cards[heist_card]["fail_penalty"][0]] += heist_cards[heist_card]["fail_penalty"][1]
				if player_stats[player - 1]["sadmeals"] < 0:
					player_stats[player - 1]["sadmeals"] = 0
				if player_stats[player - 1]["drugs"] < 0:
					player_stats[player - 1]["drugs"] = 0
				if player_stats[player - 1]["money"] < 0:
					player_stats[player - 1]["money"] = 0
				status_label.text = (player_piece_names[current_player] +
				" - $" + str(player_stats[current_player - 1]["money"]) +
				"\nHunger: " + str(player_stats[current_player - 1]["hunger"]) +
				"/10\nInebriation: " + str(player_stats[current_player - 1]["inebriation"]) + "/10")
				eat_sad_meal_button.text = "Consume a Sad Meal™️ (" + str(player_stats[current_player - 1]["sadmeals"]) + ")"
				rhymes_with_grug_button.text = "Consume a Drug (" + str(player_stats[current_player - 1]["drugs"]) + ")"
				await get_tree().create_timer(2).timeout
			second_ui.visible = false
			
			
		elif npc_spaces.has(player_stats[player - 1]["space"]):
			print(player_piece_names[player] + " landed on NPC")
			status_message((player_piece_names[player] + " landed on NPC"))
			second_ui_text_label.text = "Sell Drugs for $1"
			second_ui_button1.text = "Sell 1 Drug"
			second_ui_button2.text = "Done"
			second_ui_button1.disabled = false
			second_ui_button2.disabled = false
			second_ui_last_pressed_button = 1
			second_ui.visible = true
			while second_ui_last_pressed_button == 1:
				if player_stats[player - 1]["drugs"] <= 0:
					second_ui_button1.disabled = true
				await(second_ui_button)
				if second_ui_last_pressed_button == 1:
					player_stats[player - 1]["drugs"] -= 1
					player_stats[player - 1]["money"] += 1
					status_label.text = (player_piece_names[current_player] +
					" - $" + str(player_stats[current_player - 1]["money"]) +
					"\nHunger: " + str(player_stats[current_player - 1]["hunger"]) +
					"/10\nInebriation: " + str(player_stats[current_player - 1]["inebriation"]) + "/10")
					rhymes_with_grug_button.text = "Consume a Drug (" + str(player_stats[current_player - 1]["drugs"]) + ")"
				else:
					break
			second_ui.visible = false

			
		elif player_stats[player - 1]["space"] == 2:
			print(player_piece_names[player] + " landed on Unemployment Tax")
			status_message((player_piece_names[player] + " landed on Unemployment Tax"))
			if player_stats[player - 1]["money"] >= 10:
				player_stats[player - 1]["money"] -= 10
			else:
				imprison(player)
			
			
		elif player_stats[player - 1]["space"] == 7:
			print(player_piece_names[player] + " landed on Casino")
			status_message((player_piece_names[player] + " landed on Casino"))
			
		elif player_stats[player - 1]["space"] == 21:
			print(player_piece_names[player] + " landed on Bar")
			status_message((player_piece_names[player] + " landed on Bar"))
			if player_stats[player - 1]["money"] >= 2:
				player_stats[player - 1]["money"] -= 2
			player_stats[player - 1]["inebriation"] += 3
			if player_stats[player - 1]["inebriation"] >= 10:
				eliminate_player(player)
				return
			else:
				update_ui()
				await get_tree().create_timer(1).timeout
	
	
	
	elif player_stats[player - 1]["jail"] > 0:
		# Jail turn
		die_button.text = "Roll Dice (" + str(player_stats[player - 1]["jail"]) + " turns left)"
		purchase_sad_meal_button.disabled = true
		eat_sad_meal_button.disabled = true
		rhymes_with_grug_button.disabled = true
		await(die_rolled)
		die_button.disabled = true
		for i in randi_range(6, 10):
			die_roll_jail1 = randi_range(1, 6)
			die_roll_jail2 = randi_range(1, 6)
			die_button.text = str(die_roll_jail1) + " " + str(die_roll_jail2)
			await get_tree().create_timer(0.2).timeout
		await get_tree().create_timer(0.5).timeout
		if die_roll_jail1 == die_roll_jail2:
			player_stats[player - 1]["jail"] = -1
			die_button.text = "Doubles! Released!"
			get_node(player_piece_names[player]).global_position = get_node("BoardSpaces/Space14").global_position
			player_stats[player - 1]["space"] = 14
			await get_tree().create_timer(0.6).timeout
			await(game_turn(player))
		else:
			die_button.text = "Failed doubles!"
			player_stats[player - 1]["jail"] -= 1
			await get_tree().create_timer(0.7).timeout
			if player_stats[player - 1]["jail"] == 0:
				die_button.text = "Served jail time"
				player_stats[player - 1]["jail"] = -1
				get_node(player_piece_names[player]).global_position = get_node("BoardSpaces/Space14").global_position
				player_stats[player - 1]["space"] = 14
				await get_tree().create_timer(0.5).timeout
				await(game_turn(player))

func update_ui() -> void:
	status_label.text = (player_piece_names[current_player] +
	" - $" + str(player_stats[current_player - 1]["money"]) +
	"\nHunger: " + str(player_stats[current_player - 1]["hunger"]) +
	"/10\nInebriation: " + str(player_stats[current_player - 1]["inebriation"]) + "/10")
	# haha funny small text difference
	if player_stats[current_player - 1]["inebriation"] >= 4:
		die_button.text = "Roll Dice"
	else:
		die_button.text = "Roll Die"
	if player_stats[current_player - 1]["money"] < 5:
		purchase_sad_meal_button.disabled = true
	else:
		purchase_sad_meal_button.disabled = false
	eat_sad_meal_button.text = "Consume a Sad Meal™️ (" + str(player_stats[current_player - 1]["sadmeals"]) + ")"
	if player_stats[current_player - 1]["sadmeals"] <= 0:
		eat_sad_meal_button.disabled = true
	else:
		eat_sad_meal_button.disabled = false
	rhymes_with_grug_button.text = "Consume a Drug (" + str(player_stats[current_player - 1]["drugs"]) + ")"
	if player_stats[current_player - 1]["drugs"] <= 0:
		rhymes_with_grug_button.disabled = true
	else:
		rhymes_with_grug_button.disabled = false

func move_player_spaces(player : int, spaces : int) -> void:
	if spaces > 0:
		for i in spaces:
			player_stats[player - 1]["space"] += 1
			if player_stats[player - 1]["space"] > 27 and player_stats[player - 1]["space"] != 99:
				player_stats[player - 1]["space"] = 0
			get_node(player_piece_names[player]).global_position = get_node("BoardSpaces/Space" + str(player_stats[player - 1]["space"])).global_position
			await get_tree().create_timer(0.5).timeout
	else:
		for i in abs(spaces):
			player_stats[player - 1]["space"] -= 1
			if player_stats[player - 1]["space"] < 0 and player_stats[player - 1]["space"] != 99:
				player_stats[player - 1]["space"] = 27
			get_node(player_piece_names[player]).global_position = get_node("BoardSpaces/Space" + str(player_stats[player - 1]["space"])).global_position
			await get_tree().create_timer(0.5).timeout

func eliminate_player(player : int) -> void:
	player_stats[player - 1]["alive"] = false
	get_node(player_piece_names[player]).visible = false
	living_humans -= 1
	print(player_piece_names[player] + " died!")
	status_message((player_piece_names[player] + " died!"))

func imprison(player : int) -> void:
	player_stats[player - 1]["jail"] = 3
	get_node(player_piece_names[player]).global_position = get_node("BoardSpaces/Jail").global_position
	print(player_piece_names[player] + " was sent to jail!")
	status_message((player_piece_names[player] + " was sent to jail!"))

func status_message(message : String):
	status_update.text = message
	status_update.visible = true
	await get_tree().create_timer(float(message.length()) / 10).timeout
	status_update.visible = false

func _on_dice_roll_button_pressed() -> void:
	emit_signal("die_rolled")

func _on_buy_sad_meal_button_pressed() -> void:
	if before_turn and player_stats[current_player - 1]["money"] >= 5:
		player_stats[current_player - 1]["money"] -= 5
		player_stats[current_player - 1]["sadmeals"] += 1
		update_ui()

func _on_eat_sad_meal_pressed() -> void:
	if before_turn and player_stats[current_player - 1]["sadmeals"] > 0:
		player_stats[current_player - 1]["sadmeals"] -= 1
		if player_stats[current_player - 1]["inebriation"] >= 4: # Inebriation Bonus
			player_stats[current_player - 1]["hunger"] -= 5
		else:
			player_stats[current_player - 1]["hunger"] -= 2
		if player_stats[current_player - 1]["hunger"] < 0:
			player_stats[current_player - 1]["hunger"] = 0
		update_ui()

func _on_use_drug_pressed() -> void:
	if before_turn and player_stats[current_player - 1]["drugs"] > 0:
		player_stats[current_player - 1]["drugs"] -= 1
		player_stats[current_player - 1]["inebriation"] += 3
		if player_stats[current_player - 1]["inebriation"] > 10:
			eliminate_player(current_player)
			return
		update_ui()

func _on_second_ui_button_1_pressed() -> void:
	second_ui_last_pressed_button = 1
	emit_signal("second_ui_button")

func _on_second_ui_button_2_pressed() -> void:
	second_ui_last_pressed_button = 2
	emit_signal("second_ui_button")
