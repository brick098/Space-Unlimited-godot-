# background_stretch.gd
# This script is designed to be attached to a Sprite2D node
# to make it automatically stretch to fill the entire screen.

extends Sprite2D

func _ready() -> void:
	var screen_size = get_viewport_rect().size
	var texture_size = texture.get_size()

	scale.x = screen_size.x / texture_size.x
	scale.y = screen_size.y / texture_size.y

	position = screen_size / 2.0
	z_index = -1
