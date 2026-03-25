extends Sprite2D

@onready var abilities_button = $"../Move1Button"
@onready var inventory_button = $"../InventoryButton"

func _ready():
	material.set_shader_parameter("is_highlighted", false)
	abilities_button.hide()
	inventory_button.hide()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		material.set_shader_parameter("is_highlighted", true)
		abilities_button.show()
		inventory_button.show()
		get_viewport().set_input_as_handled()


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		material.set_shader_parameter("is_highlighted", false)
		abilities_button.hide()
		inventory_button.hide()
