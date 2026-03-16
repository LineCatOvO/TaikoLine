# Mock Audio Manager
# Use this for testing without actual audio playback

extends RefCounted
class_name MockAudioManager

var is_playing = false
var current_track = ""
var volume = 1.0

func play(track_path: String) -> void:
	current_track = track_path
	is_playing = true

func stop() -> void:
	is_playing = false
	current_track = ""

func set_volume(value: float) -> void:
	volume = value

func get_volume() -> float:
	return volume