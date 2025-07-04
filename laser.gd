# laser.gd
# This script controls a laser projectile's movement and its destruction
# based on a set lifetime and collision detection.

class_name Laser # This registers the script as a global type named "Laser"

extends Area2D # Now extends Area2D for collision detection.

@export var speed: float = 600.0 # Adjust this value in the Inspector to change laser speed.
@export var laser_scale: float = 1.0 # Adjust this value in the Inspector to change laser size.
@export var lifetime_duration: float = 1.5 # How long the laser stays alive in seconds (e.g., 1.5 seconds)

func _ready() -> void:
	# Ensure the laser's visual origin is centered.
	# This is CRITICAL for accurate positioning and visual consistency.
	# Select this Sprite2D node in Godot and CHECK the "Centered" property in the Inspector.
	# The position of this node will then correspond to the center of its texture.
	var laser_sprite: Sprite2D = find_child("Sprite2D", true, false)
	if laser_sprite:
		laser_sprite.scale = Vector2(laser_scale, laser_scale)
	else:
		pass # No error print as requested.

	# Create and start a timer to manage the laser's lifetime.
	var timer = Timer.new()
	add_child(timer) # Add the timer as a child of the laser node.
	timer.wait_time = lifetime_duration # Set the timer's duration.
	timer.one_shot = true # The timer will only run once.
	timer.timeout.connect(on_lifetime_timeout) # Connect the timeout signal to our function.
	timer.start() # Start the timer.

	# Connect the 'area_entered' signal to a function in this script.
	# This signal is emitted when this laser's Area2D enters another Area2D's collision shape.
	area_entered.connect(on_area_entered)


func _process(delta: float) -> void:
	# Move the laser upwards.
	position.y -= speed * delta


# Called when the lifetime timer runs out.
func on_lifetime_timeout() -> void:
	queue_free() # Safely remove the laser instance from the scene.


# Called when this laser's Area2D enters another Area2D's collision shape.
func on_area_entered(area: Area2D) -> void:
	# Check if the entering area is an Asteroid (using its class_name).
	if area is Asteroid: # 'Asteroid' is the class_name we added to asteroid.gd
		queue_free() # Destroy the laser.
		# The asteroid's script will handle destroying itself.
