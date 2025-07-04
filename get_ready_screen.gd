# get_ready_screen.gd
# This script manages the "Get Ready" image and sound effect,
# showing them for a fixed duration before proceeding.

extends CanvasLayer

# This signal will be emitted when the timer finishes,
# letting the StartMenu script know it's time to change scenes.
signal ready_to_proceed

# Use @onready to ensure these nodes are available when _ready is called.
@onready var get_ready_image: TextureRect = $GetReadyImage
@onready var get_ready_sound_player: AudioStreamPlayer2D = $GetReadySoundPlayer
@onready var duration_timer: Timer = $DurationTimer

# Export variable for the sound effect itself (the AudioStream resource).
# This is where you drag your sound file (.wav, .ogg) in the Inspector.
@export var get_ready_sound_effect: AudioStream


func _ready() -> void:
	print("DEBUG: GetReadyScreen _ready() called.") # Debug print
	# Ensure the image is fully visible from the start (no fade).
	get_ready_image.modulate = Color(1, 1, 1, 1) # Set alpha to 1 (fully opaque)

	# Assign the exported sound effect (the AudioStream resource) to the
	# AudioStreamPlayer's 'stream' property.
	if get_ready_sound_effect != null:
		get_ready_sound_player.stream = get_ready_sound_effect
		get_ready_sound_player.play()
		print("DEBUG: Get Ready sound playing.") # Debug print
	else:
		print("Warning: Get Ready sound effect not assigned in GetReadyScreen!")

	# Start the duration timer.
	duration_timer.start()
	print("DEBUG: Duration timer started for 1 second.") # Debug print
	
	# Connect the 'timeout' signal from the Timer.
	# When the timer is done, we'll emit our custom signal and free this scene.
	duration_timer.timeout.connect(_on_duration_timer_timeout)


# This function is called when the DurationTimer finishes.
func _on_duration_timer_timeout() -> void:
	print("DEBUG: Duration timer timed out. Emitting ready_to_proceed signal.") # Debug print
	# Emit the signal to notify the parent (StartMenu) that we're done.
	ready_to_proceed.emit()
	# Remove this GetReadyScreen scene from the tree once its job is done.
	queue_free()
