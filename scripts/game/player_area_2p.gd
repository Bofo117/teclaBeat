extends Node2D

@export var player_id: int = 1
@export var key_listener_scene: PackedScene
@export var key_names: Array[String] = []

var key_listeners = []
var score: int = 0
var combo: int = 0
var best_combo: int = 0

func _ready():
	print("=== Player Area ", player_id, " iniciado ===")
	setup_key_listeners()
	connect_signals()

func setup_key_listeners():
	if not key_listener_scene:
		print("ERROR: key_listener_scene no asignado para jugador ", player_id)
		return
	
	for i in range(key_names.size()):
		var listener = key_listener_scene.instantiate()
		listener.key_name = key_names[i]
		listener.player_id = player_id
		listener.frame = i
		
		var y_pos = 500
		var x_pos = 0
		
		if player_id == 1:
			match i:
				0: x_pos = 300
				1: x_pos = 380
				2: x_pos = 460
				3: x_pos = 380
		else:
			match i:
				0: x_pos = 700
				1: x_pos = 780
				2: x_pos = 860
				3: x_pos = 780
		
		listener.position = Vector2(x_pos, y_pos)
		add_child(listener)
		key_listeners.append(listener)

func connect_signals():
	if player_id == 1:
		Signals.Player1_add_score.connect(_on_add_score)
		Signals.Player1_increment_combo.connect(_on_increment_combo)
		Signals.Player1_reset_combo.connect(_on_reset_combo)
	else:
		Signals.Player2_add_score.connect(_on_add_score)
		Signals.Player2_increment_combo.connect(_on_increment_combo)
		Signals.Player2_reset_combo.connect(_on_reset_combo)

func _on_add_score(incr: int):
	score += incr
	print("J", player_id, " Score: ", score)

func _on_increment_combo():
	combo += 1
	if combo > best_combo:
		best_combo = combo
	print("J", player_id, " Combo: ", combo, " (Best: ", best_combo, ")")

func _on_reset_combo():
	combo = 0
	print("J", player_id, " Combo reset")

func get_final_data() -> Dictionary:
	return {
		"score": score,
		"best_combo": best_combo
	}
