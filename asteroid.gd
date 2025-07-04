# asteroid.gd
# This script controls the movement, rotation, and collision detection of an individual asteroid.

class_name Asteroid # This registers the script as a global type named "Asteroid"

extends Area2D # Now extends Area2D for collision detection.

# These variables will be set by the spawner when the asteroid is created.
var speed: float = 0.0
var rotation_speed: float = 0.0
var current_scale: float = 1.0 # Store the scale applied at creation

func _ready() -> void:
	# Apply the scale that was set by the spawner to the Sprite2D.
	var asteroid_sprite: Sprite2D = find_child("Sprite2D", true, false)
	if asteroid_sprite:
		asteroid_sprite.scale = Vector2(current_scale, current_scale)
		# Ensure the Sprite2D itself is centered for correct visual alignment
		# This should also be set in the editor for the Sprite2D node.
	else:
		pass # No error print as requested.

	# Apply the scale to the CollisionShape2D node directly.
	var collision_shape: CollisionShape2D = find_child("CollisionShape2D", true, false)
	if collision_shape:
		collision_shape.scale = Vector2(current_scale, current_scale)
	else:
		pass # No error print as requested.


	# Connect the 'area_entered' signal to a function in this script.
	# This signal is emitted when another Area2D enters this asteroid's collision shape.
	area_entered.connect(on_area_entered)


func _process(delta: float) -> void:
	# Move the asteroid downwards (increasing Y in Godot's 2D).
	position.y += speed * delta

	# Rotate the asteroid around its center.
	rotation += rotation_speed * delta

	# Despawn the asteroid when it is completely off the bottom of the screen.
	var screen_height = get_viewport_rect().size.y
	# Despawn 500 pixels BELOW the bottom edge of the screen.
	var despawn_y_threshold = screen_height + 500.0


	# Calculate the effective half-height of the asteroid based on its sprite and current scale.
	var half_asteroid_height = 0.0
	var asteroid_sprite: Sprite2D = find_child("Sprite2D", true, false)
	if asteroid_sprite and asteroid_sprite.texture:
		half_asteroid_height = (asteroid_sprite.texture.get_height() * current_scale) / 2.0
	else:
		# Fallback if no Sprite2D or texture is found (for despawn calculation)
		half_asteroid_height = 30.0 # Default value, adjust if your asteroids are very different in size.

	# If the asteroid's center (position.y) plus its half-height is greater than
	# the despawn threshold, it means the bottom edge of the asteroid has left the screen
	# by the specified extra amount.
	if position.y - half_asteroid_height > despawn_y_threshold:
		queue_free() # Safely remove the asteroid instance from the scene.


# Called when another Area2D enters this asteroid's collision shape.
func on_area_entered(area: Area2D) -> void:
	# Check if the entering area is a Laser.
	if area is Laser:
		queue_free() # Destroy the asteroid.
		area.queue_free() # Destroy the laser that hit it.
	# If it's the player, let the player handle the damage, but still destroy the asteroid.
	elif area.has_method("on_spaceship_area_entered"): # A simple check to see if it's likely the player
		queue_free() # Destroy the asteroid upon hitting the player.
		# The spaceship's script will handle reducing lives.
