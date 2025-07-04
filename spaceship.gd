# spaceship.gd
# This script controls a Sprite2D node (your spaceship)
# to follow the mouse's X-coordinate while maintaining a fixed Y-coordinate
# at the bottom of the screen.
# It also handles spawning lasers on left mouse click with sound,
# spawns asteroids at random intervals and locations,
# plays background music, includes a life system,
# adds hit sound and explosion animation on impact,
# includes spawning and collecting life pickups,
# and now includes screenshake when the spaceship is hit.
# Asteroid speed and spawn frequency now increase over time.
# Transitions to a Game Over screen when lives run out.

extends Area2D # Now extends Area2D for collision detection.

@export var bottom_offset: float = 50.0 # Distance from the bottom of the screen in pixels
@export var spaceship_scale: float = 1.0 # Controls the visual scale of the spaceship (e.g., 0.5 for half size)

@export var laser_scene: PackedScene # Drag your saved Laser scene (.tscn) here in the Inspector!
@export var laser_spawn_offset_y: float = -50.0 # How far above the ship the laser spawns (negative for upwards)
@export var shoot_sound: AudioStream # Drag your sound file (.wav, .ogg) here in the Inspector!

# Sound and Animation for when the spaceship is hit
@export var hit_sound: AudioStream # Drag your "hit" sound file (.wav, .ogg) here!
@export var explosion_scene: PackedScene # Drag your new Explosion scene (.tscn) here!

# Life Pickup Variables
@export var life_pickup_scene: PackedScene # Drag your new Life Pickup scene (.tscn) here!
@export var life_pickup_spawn_interval: float = 10.0 # Time (seconds) between life pickup spawns
@export var life_pickup_spawn_chance: float = 0.3 # Chance (0.0 to 1.0) for a life pickup to spawn when interval met

# ASTEROID EXPORT VARIABLES:
@export var asteroid_scene: PackedScene # Drag your saved Asteroid scene (.tscn) here in the Inspector!
@export var base_asteroid_spawn_interval: float = 2.0 # Base time (seconds) between asteroid spawns
@export var asteroid_interval_randomness: float = 0.5 # How much randomness to add (e.g., 0.5 means +/- 50% of base)

# Normal Asteroid Properties
@export var min_asteroid_speed: float = 100.0 # Minimum random downward speed for common asteroids
@export var max_asteroid_speed: float = 250.0 # Maximum random downward speed for common asteroids
@export var min_asteroid_rotation_speed: float = -0.5 # Minimum random rotation speed (radians/sec)
@export var max_asteroid_rotation_speed: float = 0.5 # Maximum random rotation speed (radians/sec)
@export var min_asteroid_scale: float = 0.5 # Minimum random scale for common asteroids
@export var max_asteroid_scale: float = 1.5 # Maximum random scale for common asteroids

@export var min_asteroids_per_spawn: int = 1 # Minimum number of asteroids to spawn in a single burst
@export var max_asteroids_per_spawn: int = 3 # Maximum number of asteroids to spawn in a single burst

# Rare, Fast, Smaller Asteroid Properties
@export var rare_asteroid_chance: float = 0.1 # Chance (0.0 to 1.0) for a rare asteroid to spawn (e.g., 0.1 = 10%)
@export var min_rare_asteroid_speed: float = 300.0 # Minimum speed for rare asteroids
@export var max_rare_asteroid_speed: float = 500.0 # Maximum speed for rare asteroids
@export var min_rare_asteroid_scale: float = 0.2 # Minimum scale for rare asteroids (smaller)
@export var max_rare_asteroid_scale: float = 0.6 # Maximum scale for rare asteroids (smaller)

@export var background_music: AudioStream # Drag your background music file (.wav, .ogg) here!

# Life System Variables
@export var max_lives: int = 3 # Total lives the player starts with
var current_lives: int = 0 # Current lives remaining

# UI for Lives
@export var lives_label: Label # Drag your UI Label node here from the scene!

var asteroid_spawn_timer: float = 0.0 # Internal timer to track asteroid spawning
var next_asteroid_spawn_time: float = 0.0 # The calculated time for the next spawn
var life_pickup_timer: float = 0.0 # Timer for life pickup spawns

# Difficulty Scaling Variables
@export var difficulty_increase_interval: float = 15.0 # How often (in seconds) difficulty increases
@export var speed_increase_per_interval: float = 20.0 # How much min/max asteroid speed increases per interval
@export var spawn_interval_decrease_per_interval: float = 0.1 # How much spawn interval decreases per interval
@export var max_asteroid_speed_limit: float = 800.0 # Maximum possible asteroid speed
@export var min_spawn_interval_limit: float = 0.5 # Minimum possible spawn interval

var game_time_elapsed: float = 0.0 # Tracks total game time
var last_difficulty_increase_time: float = 0.0 # Tracks when difficulty was last increased

# Screenshake Variables
@export var main_camera: Camera2D # Drag your main Camera2D node here from the scene!
@export var screenshake_strength: float = 10.0 # How intense the screenshake is
@export var screenshake_duration: float = 0.2 # How long the screenshake lasts

var screenshake_active: bool = false # Flag to indicate if screenshake is currently active
var screenshake_timer: float = 0.0 # Timer to track screenshake duration

# Game Over Screen Variable
@export var game_over_scene: PackedScene # Drag your game_over_screen.tscn here!


# Explicitly load the Asteroid script to help Godot recognize the type.
# This assumes your asteroid.gd file is directly in the 'res://' root or a subfolder like 'res://scripts/'.
# Adjust the path if your asteroid.gd is in a different location.
const ASTEROID_SCRIPT = preload("res://asteroid.gd")


func _ready() -> void:
	# Hide the mouse cursor when the game starts
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# CRITICAL FOR CORRECT POSITIONING & CLAMPING:
	# Since this script is attached directly to the Sprite2D (your spaceship),
	# ensure its "Centered" property is CHECKED in the Inspector.
	# This makes the Sprite2D's 'position' (controlled by this script) correspond
	# to the visual center of your spaceship image, which is essential for
	# accurate following and preventing it from going off-screen.
	var spaceship_sprite: Sprite2D = find_child("Sprite2D", true, false)
	if spaceship_sprite:
		spaceship_sprite.scale = Vector2(spaceship_scale, spaceship_scale)
	else:
		pass # No error print as requested.

	# Initialize random number generator for truly random values each run.
	randi() # Ensure random number generator is seeded.

	# Initialize the time for the very first asteroid spawn.
	_calculate_next_spawn_time()

	# Play background music
	if background_music != null:
		var music_player = AudioStreamPlayer.new()
		music_player.stream = background_music
		music_player.bus = "Master" # Play on the Master audio bus
		music_player.autoplay = true # Start playing as soon as it's added
		
		# Correct way to loop music in Godot 4:
		if background_music is AudioStreamOggVorbis or background_music is AudioStreamWAV:
			background_music.loop = true # Set the loop property on the AudioStream itself
		else:
			music_player.stream_looped = true # Fallback for other stream types.
			
		add_child(music_player) # Add the player as a child of the spaceship node
	else:
		print("Warning: No background music assigned in the Inspector for Spaceship!")

	# Initialize lives
	current_lives = max_lives
	_update_lives_display() # Call function to update the UI display

	# DEBUGGING LINE: Confirm if lives_label is assigned
	if lives_label != null:
		print("DEBUG: Lives Label is assigned!")
	else:
		print("DEBUG: WARNING! Lives Label is NOT assigned in the Inspector for Spaceship!")


	# Connect the 'area_entered' signal to a function in this script.
	# This signal is emitted when another Area2D enters this spaceship's collision shape.
	area_entered.connect(on_spaceship_area_entered)


# Updates the text of the lives label.
func _update_lives_display() -> void:
	if lives_label != null:
		lives_label.text = "Lives: " + str(current_lives)
	else:
		print("Warning: Lives Label not assigned in the Inspector for Spaceship!")


# Handles all input events (like mouse clicks, key presses).
func _input(event: InputEvent) -> void:
	# Check if the event is a mouse button press.
	if event is InputEventMouseButton:
		# Check if the left mouse button was pressed down.
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			spawn_laser() # Call the function to create a laser.
			play_shoot_sound() # Play the sound when the laser spawns.


# Spawns a laser instance.
func spawn_laser() -> void:
	# Check if a Laser scene has been assigned in the Inspector.
	if laser_scene == null:
		print("Warning: Laser scene not assigned in the Inspector for Spaceship!")
		return # Exit if no laser scene is set.

	# Instantiate (create an instance of) the laser scene.
	var laser_instance = laser_scene.instantiate()
	if laser_instance == null:
		print("Warning: Failed to instantiate laser scene!")
		return # Exit if instantiation failed.

	# Position the laser instance.
	# `global_position` gives the spaceship's position in world coordinates.
	# We add an offset to spawn the laser slightly above the spaceship.
	laser_instance.global_position = global_position + Vector2(0, laser_spawn_offset_y)

	# Add the laser to the scene tree.
	# It's generally best to add projectiles as children of the main game scene node
	# (e.g., your game's root Node2D), not as children of the spaceship itself.
	# This ensures they move independently of the spaceship.
	get_parent().add_child(laser_instance)


# Plays the assigned shoot sound.
func play_shoot_sound() -> void:
	if shoot_sound != null:
		# Create a temporary AudioStreamPlayer to play the sound.
		var player = AudioStreamPlayer.new()
		player.stream = shoot_sound
		player.bus = "Master" # Play on the Master audio bus
		add_child(player) # Add the player as a child of the spaceship
		player.play()
		# Connect a signal to free the player when the sound finishes
		player.finished.connect(player.queue_free)
	else:
		pass # No warning print as requested.


# Calculates the time for the next asteroid spawn with randomness.
func _calculate_next_spawn_time() -> void:
	var random_offset = randf_range(-asteroid_interval_randomness, asteroid_interval_randomness) * base_asteroid_spawn_interval
	next_asteroid_spawn_time = base_asteroid_spawn_interval + random_offset
	# Ensure the interval doesn't become negative or too small if randomness is high.
	if next_asteroid_spawn_time < 0.1: # Minimum interval of 0.1 seconds
		next_asteroid_spawn_time = 0.1


# Main game loop processing.
func _process(delta: float) -> void:
	# Spaceship movement logic:
	var screen_size = get_viewport_rect().size
	var fixed_y = screen_size.y - bottom_offset
	var mouse_position = get_global_mouse_position()
	var new_x = mouse_position.x
	var spaceship_sprite: Sprite2D = find_child("Sprite2D", true, false)
	var half_width = 0.0
	if spaceship_sprite and spaceship_sprite.texture:
		half_width = (spaceship_sprite.texture.get_width() * spaceship_sprite.scale.x) / 2.0
	else:
		half_width = 30.0
	new_x = clamp(new_x, half_width, screen_size.x - half_width)
	position = Vector2(new_x, fixed_y)

	# ASTEROID SPAWNING LOGIC:
	asteroid_spawn_timer += delta # Increment the timer by the time elapsed since the last frame.
	if asteroid_spawn_timer >= next_asteroid_spawn_time:
		# Spawn multiple asteroids in a burst
		var num_asteroids_to_spawn = randi_range(min_asteroids_per_spawn, max_asteroids_per_spawn)
		for i in range(num_asteroids_to_spawn):
			spawn_asteroid() # Call the spawn function for each asteroid in the burst
		
		asteroid_spawn_timer = 0.0 # Reset the timer for the next spawn.
		_calculate_next_spawn_time() # Calculate the time for the *next* burst of spawns.

	# Life Pickup Spawning Logic
	life_pickup_timer += delta
	if life_pickup_timer >= life_pickup_spawn_interval:
		life_pickup_timer = 0.0 # Reset the timer
		if randf() < life_pickup_spawn_chance: # Check if we should spawn based on chance
			spawn_life_pickup()

	# Difficulty Scaling Logic
	game_time_elapsed += delta
	if game_time_elapsed - last_difficulty_increase_time >= difficulty_increase_interval:
		last_difficulty_increase_time = game_time_elapsed
		_increase_difficulty()

	# Screenshake Update Logic
	if screenshake_active:
		screenshake_timer -= delta
		if screenshake_timer > 0:
			# Apply a random offset within the strength limits
			if main_camera != null:
				main_camera.offset = Vector2(randf_range(-screenshake_strength, screenshake_strength), randf_range(-screenshake_strength, screenshake_strength))
		else:
			# End screenshake and reset camera offset
			screenshake_active = false
			if main_camera != null:
				main_camera.offset = Vector2.ZERO


# Increases the game difficulty over time.
func _increase_difficulty() -> void:
	# Increase asteroid speeds
	min_asteroid_speed = min(min_asteroid_speed + speed_increase_per_interval, max_asteroid_speed_limit)
	max_asteroid_speed = min(max_asteroid_speed + speed_increase_per_interval, max_asteroid_speed_limit)

	# Decrease asteroid spawn interval (make them spawn faster)
	base_asteroid_spawn_interval = max(base_asteroid_spawn_interval - spawn_interval_decrease_per_interval, min_spawn_interval_limit)

	print("DEBUG: Difficulty increased! New Min Speed: ", min_asteroid_speed, ", Max Speed: ", max_asteroid_speed, ", Spawn Interval: ", base_asteroid_spawn_interval)


# Spawns an asteroid instance.
func spawn_asteroid() -> void:
	if asteroid_scene == null:
		print("Warning: Asteroid scene not assigned in the Inspector for Spaceship!")
		return

	# Type-cast the instantiated node to 'Asteroid' to access its script variables.
	var asteroid_instance: Asteroid = asteroid_scene.instantiate()
	
	if asteroid_instance == null:
		print("Warning: Failed to instantiate asteroid scene!")
		return

	# Determine if this will be a rare, fast, smaller asteroid
	var is_rare_asteroid = randf() < rare_asteroid_chance

	var chosen_speed: float
	var chosen_scale: float

	if is_rare_asteroid:
		chosen_speed = randf_range(min_rare_asteroid_speed, max_rare_asteroid_speed)
		chosen_scale = randf_range(min_rare_asteroid_scale, max_rare_asteroid_scale)
	else:
		# Use the CURRENT (potentially increased) min/max speeds
		chosen_speed = randf_range(min_asteroid_speed, max_asteroid_speed)
		chosen_scale = randf_range(min_asteroid_scale, max_asteroid_scale)


	# Set asteroid's random initial position at the top of the screen.
	var screen_width = get_viewport_rect().size.x
	# Spawn even further above the screen to ensure it enters fully and visibly falls.
	var spawn_y = -500.0 # Increased from -300.0 to -500.0
	var spawn_x = randf_range(0, screen_width) # Random X position across the screen width.

	asteroid_instance.position = Vector2(spawn_x, spawn_y)

	# Set asteroid's random speed, rotation speed, and scale.
	# These properties are defined as 'var' in asteroid.gd and will be set here.
	asteroid_instance.speed = chosen_speed # Assign the chosen speed
	asteroid_instance.rotation_speed = randf_range(min_asteroid_rotation_speed, max_asteroid_rotation_speed)
	asteroid_instance.current_scale = chosen_scale # Assign the chosen scale

	# Add the asteroid to the main game scene.
	get_parent().add_child(asteroid_instance)


# Spawns a life pickup.
func spawn_life_pickup() -> void:
	if life_pickup_scene == null:
		print("Warning: Life Pickup scene not assigned in the Inspector for Spaceship!")
		return

	var life_pickup_instance = life_pickup_scene.instantiate()
	if life_pickup_instance == null:
		print("Warning: Failed to instantiate life pickup scene!")
		return

	# Connect the 'collected' signal from the life pickup to our healing function.
	life_pickup_instance.collected.connect(_on_life_pickup_collected)

	# Set random initial position at the top of the screen.
	var screen_width = get_viewport_rect().size.x
	var spawn_x = randf_range(0, screen_width)
	var spawn_y = -50.0 # Spawn slightly above the top edge

	life_pickup_instance.position = Vector2(spawn_x, spawn_y)

	# Add the life pickup to the main game scene.
	get_parent().add_child(life_pickup_instance)


# Called when a life pickup is collected.
func _on_life_pickup_collected() -> void:
	if current_lives < max_lives:
		current_lives += 1
		_update_lives_display()
		print("DEBUG: Life healed! Current lives: ", current_lives)


# Called when another Area2D enters the spaceship's collision shape.
func on_spaceship_area_entered(area: Area2D) -> void:
	# Check if the entering area is an Asteroid.
	if area is Asteroid:
		current_lives -= 1 # Decrease a life
		print("DEBUG: Lives decreased to ", current_lives) # Added for debugging
		_update_lives_display() # Update the UI display

		# Play hit sound
		if hit_sound != null:
			var player = AudioStreamPlayer.new()
			player.stream = hit_sound
			player.bus = "Master"
			add_child(player)
			player.play()
			player.finished.connect(player.queue_free)
		else:
			print("Warning: Hit sound not assigned for Spaceship!")

		# Play explosion animation
		if explosion_scene != null:
			var explosion_instance = explosion_scene.instantiate()
			if explosion_instance:
				# Add the explosion as a child of the spaceship.
				# This makes it automatically follow the spaceship's movement.
				add_child(explosion_instance)
				# Set its local position to (0,0) so it appears at the spaceship's origin.
				explosion_instance.position = Vector2(0,0)
			else:
				print("Warning: Failed to instantiate explosion scene!")
		else:
			print("Warning: Explosion scene not assigned for Spaceship!")
		
		# Activate screenshake
		if main_camera != null:
			screenshake_active = true
			screenshake_timer = screenshake_duration
		else:
			print("Warning: Main Camera not assigned for Screenshake on Spaceship!")


		# Destroy the asteroid that hit the player
		area.queue_free()

		if current_lives <= 0:
			print("Game Over!") # For now, just print "Game Over!"
			# Transition to the Game Over scene.
			if game_over_scene != null:
				get_tree().change_scene_to_file(game_over_scene.resource_path)
			else:
				print("Warning: Game Over scene not assigned for Spaceship! Cannot transition.")
				queue_free() # Still remove player if no game over scene.
