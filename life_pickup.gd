# life_pickup.gd
# This script controls the behavior of a life pickup item.

class_name LifePickup # This registers the script as a global type named "LifePickup"

extends Area2D

@export var speed: float = 100.0 # How fast the life pickup falls downwards.
@export var pickup_scale: float = 1.0 # Controls the visual scale of the pickup.

# Signal emitted when this life pickup is collected by the player.
signal collected


func _ready() -> void:
	# Apply the desired scale to the Sprite2D child.
	var pickup_sprite: Sprite2D = find_child("Sprite2D", true, false)
	if pickup_sprite:
		pickup_sprite.scale = Vector2(pickup_scale, pickup_scale)
	else:
		print("Warning: No Sprite2D child found for LifePickup!")
	
	# Connect the area_entered signal to our function to detect collisions.
	area_entered.connect(on_area_entered)


func _process(delta: float) -> void:
	# Move the life pickup downwards.
	position.y += speed * delta

	# Despawn the life pickup if it goes off-screen at the bottom.
	var screen_height = get_viewport_rect().size.y
	var pickup_height = 0.0
	var pickup_sprite: Sprite2D = find_child("Sprite2D", true, false)
	if pickup_sprite and pickup_sprite.texture:
		pickup_height = (pickup_sprite.texture.get_height() * pickup_sprite.scale.y) / 2.0
	else:
		pickup_height = 16.0 # Default if no texture/sprite, adjust based on your small icon size.

	if position.y - pickup_height > screen_height + 100: # Despawn a bit below screen
		queue_free() # Remove the life pickup from the scene.


# Called when another Area2D enters this life pickup's collision shape.
func on_area_entered(area: Area2D) -> void:
	# Check if the entering area is the player (Spaceship).
	# We use 'has_method("on_spaceship_area_entered")' as a robust way to identify the player.
	if area.has_method("on_spaceship_area_entered"):
		collected.emit() # Emit the signal to notify the player that it was collected.
		queue_free() # Remove the life pickup from the scene immediately after collection.
