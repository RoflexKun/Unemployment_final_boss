extends Node2D 

@onready var enemy_visual = $EnemyVisual
@onready var door_closed = $DoorClosed 
@onready var door_open = $DoorOpen 

# Grab references to the buttons we just made
@onready var move_1_button = $Move1Button
@onready var inventory_button = $InventoryButton
@onready var boss_health_ui = $BossHealthUI
@onready var health_bar = $BossHealthUI/HealthBar
@onready var enemy_health_ui = $EnemyHealthUI
@onready var enemy_health_bar = $EnemyHealthUI/HealthBar

@onready var game_over_screen = $GameOverScreen
@onready var random_message_label = $GameOverScreen/DeathName
@onready var timer = $Timer

@export var player_saved_stats: CharacterStats
@export var enemy_roster: Array[CharacterStats]

@onready var player_combat_text = $Player/PlayerCombatText
@onready var enemy_combat_text = $EnemyCombatText

var enemy_queue: Array[CharacterStats]
var active_enemy_stats: CharacterStats
var active_player_stats: CharacterStats

enum Turn { PLAYER, ENEMY }
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
	enemy_visual.hide()
	door_closed.show()
	door_open.hide()
	boss_health_ui.hide()
	enemy_health_ui.hide()
	game_over_screen.hide()
	move_1_button.hide()
	player_combat_text.hide()
	enemy_combat_text.hide()
	
	start_new_run()

func start_new_run():
	if not player_saved_stats or enemy_roster.is_empty():
		print("Make sure you add stats to the Inspector!")
		return
		
	active_player_stats = player_saved_stats.duplicate()
	health_bar.update_health(active_player_stats.current_health, active_player_stats.max_health)
	
	# Duplicate the roster and shuffle it so the order is random every time
	enemy_queue = enemy_roster.duplicate()
	enemy_queue.shuffle() 
	
	spawn_next_enemy()
	
func spawn_next_enemy():
	if enemy_queue.is_empty():
		print("YOU BEAT EVERYONE! YOU WIN!")
		return 
	
	# Pop the first enemy off the shuffled list
	active_enemy_stats = enemy_queue.pop_front().duplicate()
	enemy_visual.texture = active_enemy_stats.character_texture
	
	enemy_health_bar.update_health(active_enemy_stats.current_health, active_enemy_stats.max_health)
	
	# Reset the door and start the dramatic entrance timer
	enemy_visual.hide()
	door_open.hide()
	door_closed.show()
	timer.start()

func _on_timer_timeout():
	door_closed.hide()
	door_open.show()
	enemy_visual.show()
	boss_health_ui.show()
	enemy_health_ui.show()
	
	current_turn = Turn.PLAYER
	move_1_button.disabled = false
	inventory_button.disabled = false

func _on_move_1_button_pressed():
	if current_turn == Turn.PLAYER:
		take_player_turn(0)

func take_player_turn(move_index: int):
	# Player attacks
	perform_attack(active_player_stats, active_enemy_stats, move_index)
	
	# Disable buttons so the player can't spam click
	move_1_button.disabled = true
	inventory_button.disabled = true
	
	if active_enemy_stats.current_health <= 0:
		print(active_enemy_stats.character_name + " was defeated!")
		enemy_health_ui.hide()
		spawn_next_enemy()
		return
	
	# Otherwise, it's the enemy's turn
	current_turn = Turn.ENEMY
	get_tree().create_timer(1.5).timeout.connect(enemy_take_turn)

func enemy_take_turn():
	# 1. Roll a random number from 1 to 100 (like rolling a d100 in D&D)
	var roll = randi_range(1, 100)
	var current_sum = 0
	var chosen_move_index = 0
	
	# 2. Step through the moves and check the roll
	for i in range(active_enemy_stats.moveset.size()):
		current_sum += active_enemy_stats.moveset[i].prob
		
		# If our roll falls within this move's probability window, pick it!
		if roll <= current_sum:
			chosen_move_index = i
			break 
	
	# 3. Perform the attack using the chosen move
	perform_attack(active_enemy_stats, active_player_stats, chosen_move_index)
	
	# 4. Pass the turn back to the player
	if active_player_stats.current_health > 0:
		current_turn = Turn.PLAYER
		move_1_button.disabled = false
		inventory_button.disabled = false
	
func trigger_game_over():
	random_message_label.text = ironic_messages_list.pick_random()
	
	game_over_screen.show()

func display_combat_text(label_node: Label, text: String):
	label_node.text = text
	label_node.show()
	label_node.modulate.a = 1.0 # Ensure it is fully visible at first
	
	# Create a simple animation to fade it out
	var tween = get_tree().create_tween()
	tween.tween_interval(1.0) # Keep it on screen for 1 second
	tween.tween_property(label_node, "modulate:a", 0.0, 0.5) # Fade it out over 0.5 seconds
	tween.tween_callback(label_node.hide) # Hide it completely when the fade is done

func perform_attack(attacker: CharacterStats, defender: CharacterStats, move_index: int):
	var chosen_move = attacker.moveset[move_index]
	var total_damage = chosen_move.damage
	defender.current_health -= total_damage
	
	var combat_message = chosen_move.move_name + "!\n-" + str(total_damage) + " HP"
	if attacker.character_name == active_player_stats.character_name:
		display_combat_text(player_combat_text, combat_message)
	else:
		display_combat_text(enemy_combat_text, combat_message)
	
	print(attacker.character_name + " used " + chosen_move.move_name + "!")
	print(defender.character_name + " took " + str(total_damage) + " damage!")
	print(defender.character_name + " has " + str(defender.current_health) + " health left.")
	print("-------------------")
	
	if defender.character_name == active_player_stats.character_name:
		health_bar.update_health(defender.current_health, defender.max_health)
	else:
		enemy_health_bar.update_health(defender.current_health, defender.max_health)
	
	if defender.character_name == active_player_stats.character_name and defender.current_health <= 0:
		trigger_game_over()


func _on_retry_button_pressed() -> void:
	game_over_screen.hide()
	start_new_run()
