extends Node2D 

@onready var enemy_visual = $EnemyVisual
@onready var player_visual = $Player
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
@onready var win_screen = $WinScreen
@onready var win_message_label = $WinScreen/WinMessage
@onready var timer = $Timer

@export var player_saved_stats: CharacterStats
@export var enemy_roster: Array[CharacterStats]

@onready var player_combat_text = $Player/PlayerCombatText
@onready var enemy_combat_text = $EnemyCombatText

@onready var abilities_ui = $AbilitiesUI

var unlocked_abilities: int = 1
var bonus_damage: int = 0
var damage_reduction: int = 0

@onready var ability_slot_1 = $AbilitiesUI/GridContainer/TextureButton
@onready var ability_slot_2 = $AbilitiesUI/GridContainer/TextureButton2
@onready var ability_slot_3 = $AbilitiesUI/GridContainer/TextureButton3
@onready var ability_slot_4 = $AbilitiesUI/GridContainer/TextureButton4
@onready var abilities_slots = [ability_slot_1, ability_slot_2, ability_slot_3, ability_slot_4]

#TODO when assets are done I need to modify this
var tex_empty_ability = preload("res://Drawing_assets/buttons/empty_inventory.png")
var ability_two = preload("res://Drawing_assets/buttons/ability_doi.png")
var ability_three = preload("res://Drawing_assets/buttons/ability_trei.png")
var ability_four = preload("res://Drawing_assets/buttons/ability_quatro.png")


@onready var inventory_ui = $InventoryUI
var player_inventory: Array[String] = ["", "", "", ""]
@onready var inv_slot_1 = $InventoryUI/GridContainer/TextureButton
@onready var inv_slot_2 = $InventoryUI/GridContainer/TextureButton2
@onready var inv_slot_3 = $InventoryUI/GridContainer/TextureButton3
@onready var inv_slot_4 = $InventoryUI/GridContainer/TextureButton4 
@onready var inventory_slots = [inv_slot_1, inv_slot_2, inv_slot_3, inv_slot_4]

@onready var item_spawn_area = $ItemSpawnArea
var tex_cookies = preload("res://Drawing_assets/Items/cookies.png")
var tex_energy = preload("res://Drawing_assets/Items/energy_drink.png")
var tex_pufs = preload("res://Drawing_assets/Items/pufs.png")
var loot_table = {
	"Cookies": [40, tex_cookies],
	"Energy Drink": [30, tex_energy],
	"Pufs": [30, tex_pufs]
}

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
	win_screen.hide()
	move_1_button.hide()
	player_combat_text.hide()
	enemy_combat_text.hide()
	inventory_ui.hide()
	abilities_ui.hide()
	
	ability_slot_1.pressed.connect(func(): use_ability(0))
	ability_slot_2.pressed.connect(func(): use_ability(1))
	ability_slot_3.pressed.connect(func(): use_ability(2))
	ability_slot_4.pressed.connect(func(): use_ability(3))
	
	inv_slot_1.pressed.connect(func(): use_item(0))
	inv_slot_2.pressed.connect(func(): use_item(1))
	inv_slot_3.pressed.connect(func(): use_item(2))
	inv_slot_4.pressed.connect(func(): use_item(3))
	start_new_run()

func start_new_run():
	if not player_saved_stats or enemy_roster.is_empty():
		print("Make sure you add stats to the Inspector!")
		return
		
	active_player_stats = player_saved_stats.duplicate()
	health_bar.update_health(active_player_stats.current_health, active_player_stats.max_health)
	
	enemy_queue = enemy_roster.duplicate()
	#enemy_queue.shuffle() 
	
	spawn_next_enemy()
	
func spawn_next_enemy():
	if enemy_queue.is_empty():
		print("YOU BEAT EVERYONE! YOU WIN!")
		trigger_win_screen()
		return 
	
	# Pop the first enemy off the shuffled list
	active_enemy_stats = enemy_queue.pop_front().duplicate()
	enemy_visual.texture = active_enemy_stats.character_texture
	
	enemy_visual.scale = Vector2(1, 1)
	print("Numele caracterului si de ce poate are probleme", active_enemy_stats.character_name)
	
	match active_enemy_stats.character_name:
		"Dog":
			print("Intra la dog")
			enemy_visual.scale = Vector2(2.5, 2.5)
			enemy_visual.position = Vector2(400, 520)
		"Sister":
			print("Intra la Sister")
			enemy_visual.scale = Vector2(1.745, 1.944)
			enemy_visual.position = Vector2(410.0, 344.0)	
		"Mom":
			print("Intra la mom")
			enemy_visual.scale = Vector2(1.607, 1.634)
			enemy_visual.position = Vector2(387.0, 370.0)	
		"Dad":
			print("Intra la dad")
			enemy_visual.scale = Vector2(1.46, 1.348)
			enemy_visual.position = Vector2(434.0, 386.0)
	
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
	move_1_button.hide()
	inventory_button.hide()
	
	abilities_ui.show()
	

func take_player_turn(move_index: int):
	# Player attacks
	perform_attack(active_player_stats, active_enemy_stats, move_index)
	
	# Disable buttons so the player can't spam click
	move_1_button.disabled = true
	inventory_button.disabled = true
	
	if active_enemy_stats.current_health <= 0:
		print(active_enemy_stats.character_name + " was defeated!")
		enemy_health_ui.hide()
		
		if unlocked_abilities < 4: 
			var new_slot_index = unlocked_abilities 
			unlocked_abilities += 1 
			
			var slot_button = abilities_slots[new_slot_index]
			
			if new_slot_index == 1:
				slot_button.texture_normal = ability_two
			elif new_slot_index == 2:
				slot_button.texture_normal = ability_three
			elif new_slot_index == 3:
				slot_button.texture_normal = ability_four
			
			slot_button.ignore_texture_size = true
			slot_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			
			slot_button.custom_minimum_size = Vector2(32, 32) 
			
			if slot_button.has_node("ItemIcon"):
				slot_button.get_node("ItemIcon").hide()
			
			print("Ai deblocat abilitatea de pe slotul " + str(new_slot_index + 1) + "!")
		spawn_random_item(true)
		spawn_next_enemy()
		return
	
	# Otherwise, it's the enemy's turn
	current_turn = Turn.ENEMY
	get_tree().create_timer(1.5).timeout.connect(enemy_take_turn)

func enemy_take_turn():
	var roll = randi_range(1, 100)
	var current_sum = 0
	var chosen_move_index = 0
	
	for i in range(active_enemy_stats.moveset.size()):
		current_sum += active_enemy_stats.moveset[i].prob
		
		if roll <= current_sum:
			chosen_move_index = i
			break 
	
	perform_attack(active_enemy_stats, active_player_stats, chosen_move_index)
	
	if active_player_stats.current_health > 0:
		current_turn = Turn.PLAYER
		spawn_random_item()
		move_1_button.disabled = false
		inventory_button.disabled = false
	
func trigger_game_over():
	random_message_label.text = ironic_messages_list.pick_random()
	
	game_over_screen.show()

func display_combat_text(label_node: Label, text: String, text_color: Color = Color.RED):
	label_node.text = text
	
	if label_node.label_settings:
		var new_settings = label_node.label_settings.duplicate()
		new_settings.font_color = text_color
		label_node.label_settings = new_settings
		
	label_node.show()
	label_node.modulate.a = 1.0
	
	var tween = get_tree().create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(label_node, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label_node.hide)

func use_ability(slot_index: int):
	if slot_index >= unlocked_abilities:
		print("This ability has not been unlocked")
		return
		
	abilities_ui.hide()
	move_1_button.show()
	inventory_button.show()
	
	if current_turn == Turn.PLAYER:
		take_player_turn(slot_index)
		
func use_item(slot_index: int):
	var item_name = player_inventory[slot_index]
	
	if item_name == "":
		print("Slot gol!")
		return
		
	match item_name:
		"Cookies":
			active_player_stats.current_health = min(active_player_stats.max_health, active_player_stats.current_health + 15)
			health_bar.update_health(active_player_stats.current_health, active_player_stats.max_health)
			display_combat_text(player_combat_text, "Cookies!\n+15 HP", Color.GREEN)
			print("Ai mancat cookies! +15 HP")
		"Energy Drink":
			bonus_damage = 10
			display_combat_text(player_combat_text, "Energy!\n+10 DMG", Color.GREEN)
			print("Energy Drink activat! +10 damage la urmatorul atac")
		"Pufs":
			damage_reduction = 5
			display_combat_text(player_combat_text, "Pufs!\n-5 DMG Inamic", Color.GREEN)
			print("Pufs activati! Urmatorul atac primit va fi redus cu 5")

	player_inventory[slot_index] = ""
	
	var icon_node = inventory_slots[slot_index].get_node("ItemIcon")
	icon_node.texture = null
	
	inventory_ui.hide()
	move_1_button.show()
	inventory_button.show()

func perform_attack(attacker: CharacterStats, defender: CharacterStats, move_index: int):
	var chosen_move = attacker.moveset[move_index]
	var total_damage = chosen_move.damage
	
	if attacker.character_name == active_player_stats.character_name:
		total_damage += bonus_damage
		bonus_damage = 0
	
	if defender.character_name == active_player_stats.character_name:
		total_damage = max(0, total_damage - damage_reduction)
		damage_reduction = 0
	
	defender.current_health -= total_damage
	
	if defender.current_health > 0:
		if defender.character_name == active_player_stats.character_name:
			apply_jitter(player_visual)
		else:
			apply_jitter(enemy_visual)
		
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
		
func apply_jitter(node_to_shake: Node2D):
	var original_pos = node_to_shake.position
	
	var color_tween = get_tree().create_tween()
	
	if node_to_shake.material:
		node_to_shake.material.set_shader_parameter("flash_amount", 1.0)
		color_tween.tween_property(node_to_shake.material, "shader_parameter/flash_amount", 0.0, 0.5)
	else:
		node_to_shake.modulate = Color.RED
		color_tween.tween_property(node_to_shake, "modulate", Color.WHITE, 0.5) 
	
	var tween = get_tree().create_tween()
	
	for i in range(10):
		var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		tween.tween_property(node_to_shake, "position", original_pos + random_offset, 0.05)
	
	tween.tween_property(node_to_shake, "position", original_pos, 0.05)
	
func pickup_item(item_name: String, item_node: Node):
	var slot_index = -1
	for i in range(player_inventory.size()):
		if player_inventory[i] == "":
			slot_index = i
			break
	
	if slot_index != -1:
		player_inventory[slot_index] = item_name
		var item_texture = loot_table[item_name][1]
		
		var icon_node = inventory_slots[slot_index].get_node("ItemIcon")
		icon_node.texture = item_texture
		
		item_node.queue_free()
	else:
		print("E plin inventarul, vedem ce facem aici")

func spawn_random_item(guaranteed: bool = false):
	if not guaranteed:
		var spawn_chance = randi_range(1, 100)
		if spawn_chance > 30:
			return
		
	var item_roll = randi_range(1, 100)
	var current_sum = 0
	var chosen_texture = null
	var chosen_name = ""
	
	for item_name in loot_table.keys():
		current_sum += loot_table[item_name][0]
		if item_roll <= current_sum:
			chosen_texture = loot_table[item_name][1]
			chosen_name = item_name
			break
	
	var new_item = TextureButton.new()
	new_item.texture_normal = chosen_texture
	new_item.scale = Vector2(2, 2)
	new_item.z_index = 100 
	
	new_item.ignore_texture_size = true
	new_item.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	new_item.custom_minimum_size = Vector2(32, 32)
	new_item.pressed.connect(func(): pickup_item(chosen_name, new_item))
	
	var random_x = randf_range(250, 750)
	var fixed_y = item_spawn_area.position.y
	
	new_item.position = Vector2(random_x, fixed_y)
	
	add_child(new_item)
	
func trigger_win_screen():
	win_screen.show()
	print("Ecran de victorie afișat!")

func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_inventory_button_pressed() -> void:
	move_1_button.hide()
	inventory_button.hide()
	
	inventory_ui.show()
