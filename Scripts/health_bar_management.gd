extends Sprite2D

var initial_scale: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_scale = scale.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_health(current_hp: int, max_hp: int) -> void:
	var ratio = float(current_hp) / float(max_hp)
	
	ratio = clamp(ratio, 0.0, 1.0)
	
	scale.x = initial_scale * ratio
