extends Resource
class_name CharacterStats

@export var character_name: String = "Unknown"
@export var max_health: int = 100
@export var current_health: int = 100

@export var moveset: Array[Move]
@export var character_texture: Texture2D
