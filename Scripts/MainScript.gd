extends Node2D 

@onready var mom = $Mom 
@onready var door_closed = $DoorClosed 
@onready var door_open = $DoorOpen 

# Grab references to the buttons we just made
@onready var move_1_button = $Move1Button

@export var mom_saved_stats: CharacterStats
@export var player_saved_stats: CharacterStats

var active_mom_stats: CharacterStats
var active_player_stats: CharacterStats

enum Turn { PLAYER, MOM }
var current_turn = Turn.PLAYER

func _ready():
	mom.hide()
	door_closed.show()
	door_open.hide()
	
	move_1_button.hide()
	
	if mom_saved_stats and player_saved_stats:
		active_mom_stats = mom_saved_stats.duplicate()
		active_player_stats = player_saved_stats.duplicate()

func _on_timer_timeout():
	door_closed.hide()
	door_open.show()
	mom.show()
	
	move_1_button.show()

# 2. Player clicks Button 1
func _on_move_1_button_pressed():
	if current_turn == Turn.PLAYER:
		take_player_turn(0)

func take_player_turn(move_index: int):
	# Player attacks
	perform_attack(active_player_stats, active_mom_stats, move_index)
	
	# Disable buttons so the player can't spam click
	move_1_button.disabled = true
	
	# Switch turn to Mom
	current_turn = Turn.MOM
	
	get_tree().create_timer(1.5).timeout.connect(mom_take_turn)

func mom_take_turn():
	var random_move_index = randi() % active_mom_stats.moveset.size()
	
	perform_attack(active_mom_stats, active_player_stats, random_move_index)
	
	current_turn = Turn.PLAYER
	
	move_1_button.disabled = false

func perform_attack(attacker: CharacterStats, defender: CharacterStats, move_index: int):
	var chosen_move = attacker.moveset[move_index]
	var total_damage = chosen_move.damage + attacker.attack_power
	defender.current_health -= total_damage
	
	print(attacker.character_name + " used " + chosen_move.move_name + "!")
	print(defender.character_name + " took " + str(total_damage) + " damage!")
	print(defender.character_name + " has " + str(defender.current_health) + " health left.")
	print("-------------------")
