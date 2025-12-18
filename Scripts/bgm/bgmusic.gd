extends AudioStreamPlayer
@onready var bgmusic: AudioStreamPlayer = $"."


var rng := RandomNumberGenerator.new()

# Preload your tracks
var tracks: Array[AudioStream] = [
	preload("res://sfx/fall.mp3"),
	preload("res://sfx/as-alive-as-you-need-me-to-be.mp3"),
	preload("res://sfx/derezzed.mp3"),
	preload("res://sfx/infiltrator.mp3"),
	preload("res://sfx/the-game-has-changed.mp3")
]

func _ready():
	rng.randomize()

func play_random_track():
	if tracks.size() == 0:
		push_warning("No music tracks found in tracks array.")
		return
	var idx = rng.randi_range(0, tracks.size() - 1)
	bgmusic.stream = tracks[idx]
	bgmusic.play()

# call play_random_track() when a new game starts
