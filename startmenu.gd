# start_menu.gd
# This script controls the Start Menu scene.

extends Control

# Export variable to hold the path to your main game scene.
# Drag your 'Game.tscn' file here in the Inspector!
@export var main_game_scene_path: String = "res://game.tscn" # <<< CHECK THIS PATH IN EDITOR

# Export variable for the "Get Ready" screen scene.
@export var get_ready_scene: PackedScene # Drag your get_ready_screen.tscn here!


func _ready() -> void:
	# Get a reference to the "Start Game" button.
	var start_button: Button = find_child("Button", true, false)
	if start_button:
		# Connect the 'pressed' signal of the button to our _on_start_button_pressed function.
		start_button.pressed.connect(_on_start_button_pressed)
	else:
		print("Warning: 'Button' node not found in StartMenu scene!")


# This function is called when the "Start Game" button is pressed.
func _on_start_button_pressed() -> void:
	# Instantiate and show the "Get Ready" screen.
	if get_ready_scene != null:
		var get_ready_instance = get_ready_scene.instantiate()
		if get_ready_instance:
			# Connect the signal from the GetReadyScreen to know when it's done.
			get_ready_instance.ready_to_proceed.connect(_on_get_ready_screen_finished)
			
			# Add the Get Ready screen to the root of the scene tree so it appears on top.
			get_tree().get_root().add_child(get_ready_instance)
			
			# Optionally hide the start menu while the "Get Ready" screen is active
			# (though CanvasLayer should draw on top anyway)
			# hide() 
		else:
			print("Warning: Failed to instantiate Get Ready scene!")
			# If instantiation fails, proceed to game anyway to avoid getting stuck.
			_change_to_main_game_scene()
	else:
		print("Warning: Get Ready scene not assigned in the Inspector for StartMenu!")
		# If no Get Ready scene is assigned, just change to game scene directly.
		_change_to_main_game_scene()


# Called when the "Get Ready" screen's timer finishes.
func _on_get_ready_screen_finished() -> void:
	# Now that the "Get Ready" screen is done, change to the main game scene.
	_change_to_main_game_scene()


# Helper function to change to the main game scene.
func _change_to_main_game_scene() -> void:
	print("DEBUG: Attempting to change scene to: ", main_game_scene_path) # Debug print
	# Change the current scene to the main game scene.
	get_tree().change_scene_to_file(main_game_scene_path)
