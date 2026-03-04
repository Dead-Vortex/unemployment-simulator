extends Node2D

@onready var camera : Camera2D = $Camera2D

# Player Pieces
@onready var player1 = $Goat
@onready var player2 = $Bag
@onready var player3 = $Cards
@onready var player4 = $Milk # these might be useless? if they are i will remove them (this is a reminder)
var player_piece_names : Dictionary = {1: "Goat", 2: "Bag", 3: "Cards", 4: "Milk"}
var current_player : int = 1

# UI
@onready var status_label = $CanvasLayer/PanelContainer/VBoxContainer/StatusLabel
@onready var die_button = $CanvasLayer/PanelContainer/VBoxContainer/Dice
@onready var purchase_sad_meal_button = $CanvasLayer/PanelContainer/VBoxContainer/BuySadMeal
@onready var eat_sad_meal_button = $CanvasLayer/PanelContainer/VBoxContainer/SadMeal
@onready var rhymes_with_grug_button = $CanvasLayer/PanelContainer/VBoxContainer/Drug # I have an idea!

# Turn logic
var before_turn : bool = true
signal die_rolled
var die_roll : int = 2

var player_stats : Array = [ # Self explanitory.
	{"money": 10, "hunger": 0, "inebriation": 5, "sadmeals": 1, "drugs": 0, "space": 0},
	{"money": 10, "hunger": 0, "inebriation": 0, "sadmeals": 1, "drugs": 0, "space": 0},
	{"money": 10, "hunger": 0, "inebriation": 0, "sadmeals": 1, "drugs": 0, "space": 0},
	{"money": 10, "hunger": 0, "inebriation": 0, "sadmeals": 1, "drugs": 0, "space": 0}
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

func _ready() -> void:
	while true:
		await(game_turn(1))
		await(game_turn(2))
		await(game_turn(3))
		await(game_turn(4))

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

func game_turn(player):
	current_player = player
	# Initialize UI
	die_button.disabled = false
	player_stats[player - 1]["hunger"] += 1
	player_stats[player - 1]["inebriation"] -= 1
	if player_stats[player - 1]["inebriation"] < 0:
		player_stats[player - 1]["inebriation"] = 0
	update_ui()
	# Die Roll
	await(die_rolled)
	die_button.disabled = true
	purchase_sad_meal_button.disabled = true
	eat_sad_meal_button.disabled = true
	rhymes_with_grug_button.disabled = true
	for i in 10:
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
		die_button.text = "Roll Die"
		die_button.disabled = false
		await(die_rolled)
		die_button.disabled = true
		for i in 10:
			die_roll = randi_range(1, 6)
			die_button.text = str(die_roll)
			await get_tree().create_timer(0.2).timeout
		await get_tree().create_timer(0.5).timeout
		if (die_roll == 2 or die_roll == 3) and player_stats[player - 1]["drugs"] > 0:
			die_button.text = "Player has drugs, go to jail"
		elif die_roll == 4 or die_roll == 5:
			if player_stats[player - 1]["inebriation"] >= 4:
				pass # go to jail
			else:
				move_player_spaces(player, -2)
		elif die_roll == 6:
			if player_stats[player - 1]["money"] >= 10:
				player_stats[player - 1]["money"] -= 10
			else:
				pass # go to jail
		await get_tree().create_timer(0.8).timeout
			
	elif dark_alleyway_spaces.has(player_stats[player - 1]["space"]):
		print(player_piece_names[player] + " landed on Dark Alleyway")
	elif heist_spaces.has(player_stats[player - 1]["space"]):
		print(player_piece_names[player] + " landed on Heist")
	elif npc_spaces.has(player_stats[player - 1]["space"]):
		print(player_piece_names[player] + " landed on NPC")
	elif player_stats[player - 1]["space"] == 2:
		print(player_piece_names[player] + " landed on Unemployment Tax")
	elif player_stats[player - 1]["space"] == 7:
		print(player_piece_names[player] + " landed on Casino")
	elif player_stats[player - 1]["space"] == 21:
		print(player_piece_names[player] + " landed on Bar")

func update_ui():
	status_label.text = player_piece_names[current_player] + " - $" + str(player_stats[current_player - 1]["money"]) + "\nHunger: " + str(player_stats[current_player - 1]["hunger"]) + "/10\nInebriation: " + str(player_stats[current_player - 1]["inebriation"]) + "/10"
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

func move_player_spaces(player : int, spaces : int):
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
			# eliminate player
			pass
		update_ui()


# Old, bad code because i forgot dictionaries exist
## Player 1
#var player1_money : int = 10
#var player1_hunger : int = 0
#var player1_inebriation : int = 0
#var player1_sadmeals : int = 1
#var player1_drugs : int = 0
#var player1_space : int = 0
#
## Player 2
#var player2_money : int = 10
#var player2_hunger : int = 0
#var player2_inebriation : int = 0
#var player2_sadmeals : int = 1
#var player2_drugs : int = 0
#var player2_space : int = 0
#
## Player 3
#var player3_money : int = 10
#var player3_hunger : int = 0
#var player3_inebriation : int = 0
#var player3_sadmeals : int = 1
#var player3_drugs : int = 0
#var player3_space : int = 0
#
## Player 4
#var player4_money : int = 10
#var player4_hunger : int = 0
#var player4_inebriation : int = 0
#var player4_sadmeals : int = 1
#var player4_drugs : int = 0
#var player4_space : int = 0

#func get_player_stat(stat : String, player : int):
	#if stat == "money":
		#if player == 1:
			#return player1_money
		#elif player == 2:
			#return player2_money
		#elif player == 3:
			#return player3_money
		#elif player == 4:
			#return player4_money
	#elif stat == "hunger":
		#if player == 1:
			#return player1_hunger
		#elif player == 2:
			#return player2_hunger
		#elif player == 3:
			#return player3_hunger
		#elif player == 4:
			#return player4_hunger
	#elif stat == "inebriation":
		#if player == 1:
			#return player1_inebriation
		#elif player == 2:
			#return player2_inebriation
		#elif player == 3:
			#return player3_inebriation
		#elif player == 4:
			#return player4_inebriation
	#elif stat == "sadmeals":
		#if player == 1:
			#return player1_sadmeals
		#elif player == 2:
			#return player2_sadmeals
		#elif player == 3:
			#return player3_sadmeals
		#elif player == 4:
			#return player4_sadmeals
	#elif stat == "drugs":
		#if player == 1:
			#return player1_drugs
		#elif player == 2:
			#return player2_drugs
		#elif player == 3:
			#return player3_drugs
		#elif player == 4:
			#return player4_drugs
