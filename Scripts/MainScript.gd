extends Node2D 

@onready var mom = $Mom 
@onready var door_closed = $DoorClosed 
@onready var door_open = $DoorOpen 

# Grab references to the buttons we just made
@onready var move_1_button = $Move1Button
@onready var boss_health_ui = $BossHealthUI
@onready var health_bar = $BossHealthUI/HealthBar

@onready var game_over_screen = $GameOverScreen
@onready var random_message_label = $GameOverScreen/DeathName

@export var mom_saved_stats: CharacterStats
@export var player_saved_stats: CharacterStats

var active_mom_stats: CharacterStats
var active_player_stats: CharacterStats

enum Turn { PLAYER, MOM }
var current_turn = Turn.PLAYER

var ironic_messages_list = [
	'Maybe you should search for a job',
	'How can you lose in a game you are the boss',
	'Maybe try roblox?',
	'For a gamer, that was pathetic',
	'Damn...',
	'Don\'t retry, just quit!'
]

func _ready():
	mom.hide()
	door_closed.show()
	door_open.hide()
	boss_health_ui.hide()
	game_over_screen.hide()
	
	move_1_button.hide()
	
	if mom_saved_stats and player_saved_stats:
		active_mom_stats = mom_saved_stats.duplicate()
		active_player_stats = player_saved_stats.duplicate()

func _on_timer_timeout():
	door_closed.hide()
	door_open.show()
	mom.show()
	boss_health_ui.show()
	
	# move_1_button.show()

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
	
func trigger_game_over():
	random_message_label.text = ironic_messages_list.pick_random()
	
	game_over_screen.show()

func perform_attack(attacker: CharacterStats, defender: CharacterStats, move_index: int):
	var chosen_move = attacker.moveset[move_index]
	var total_damage = chosen_move.damage + attacker.attack_power
	defender.current_health -= total_damage
	
	print(attacker.character_name + " used " + chosen_move.move_name + "!")
	print(defender.character_name + " took " + str(total_damage) + " damage!")
	print(defender.character_name + " has " + str(defender.current_health) + " health left.")
	print("-------------------")
	
	if defender.character_name == active_player_stats.character_name:
		health_bar.update_health(defender.current_health, defender.max_health)
	
	if defender.character_name == active_player_stats.character_name and defender.current_health <= 0:
		trigger_game_over()


func _on_retry_button_pressed() -> void:
	game_over_screen.hide()
	
	active_player_stats = player_saved_stats.duplicate()
	active_mom_stats = mom_saved_stats.duplicate()
	
	health_bar.update_health(active_player_stats.current_health, active_player_stats.max_health)
	
	current_turn = Turn.PLAYER
	move_1_button.disabled = false
