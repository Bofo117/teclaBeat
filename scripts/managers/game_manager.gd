extends Node

# Variables globales
var game_mode: int = 1
var selected_song: Dictionary = {}
var selected_song_key: String = ""
var best_combo_player1: int = 0
var best_combo_player2: int = 0
var current_user: String = ""

# Teclas predefinidas
var player1_keys = ["button_Q", "button_W", "button_E", "button_R"]
var player2_keys = ["button_A", "button_S", "button_D", "button_F"]

var game_difficulty = null  # Se llenará con DifficultyManager.Difficulty
var difficulty_config: Dictionary = {}
var current_difficulty_name: String = "MEDIO"

# Puntajes actuales
var current_scores = {
	"player1": 0,
	"player2": 0
}

# Canciones disponibles
var available_songs = {
	"RHYTHM_HELL": {
		"name": "Rhythm Hell",
		"difficulty": "HARD",
		"duration": 40.413,
		"bpm": 140,
		"music_path": "res://music/Rhythm Hell.wav",
		"level_path": "res://levels/level_editor.tscn",
		"thumbnail": null
	},
}

var best_combo: int = 0
var current_song_name: String = ""

# ===== NUEVAS VARIABLES PARA ESTADÍSTICAS COMPLETAS =====
var game_completed: bool = false
var final_boss_hp_remaining: int = 0
var final_player_hp_remaining: int = 0
var time_to_complete: float = 0.0
var total_notes_hit: int = 0
var perfect_count: int = 0
var great_count: int = 0
var good_count: int = 0
var ok_count: int = 0
var miss_count: int = 0
var max_combo_achieved: int = 0

# Para 2 jugadores (si los necesitas)
var perfect_count_p1: int = 0
var great_count_p1: int = 0
var good_count_p1: int = 0
var ok_count_p1: int = 0
var miss_count_p1: int = 0

var perfect_count_p2: int = 0
var great_count_p2: int = 0
var good_count_p2: int = 0
var ok_count_p2: int = 0
var miss_count_p2: int = 0

func _ready():
	reset_game_data()

func set_current_user(username: String):
	current_user = username
	print("Usuario actual: ", current_user)

func is_logged_in() -> bool:
	return current_user != "" and current_user != "INVITADO"

func set_game_mode(mode: int):
	game_mode = mode
	print("Modo de juego: ", "Un Jugador" if mode == 1 else "Dos Jugadores")

func set_selected_song(song_key: String):
	if available_songs.has(song_key):
		selected_song = available_songs[song_key]
		selected_song_key = song_key
		print("Canción seleccionada: ", selected_song["name"])
		return true
	return false

func get_available_songs_list():
	var songs = []
	for key in available_songs:
		songs.append({
			"key": key,
			"name": available_songs[key]["name"],
			"difficulty": available_songs[key]["difficulty"]
		})
	return songs

func reset_game_data():
	current_scores.player1 = 0
	current_scores.player2 = 0
	best_combo = 0
	best_combo_player1 = 0
	best_combo_player2 = 0
	current_song_name = ""
	selected_song = {}
	selected_song_key = ""
	
	# Resetear estadísticas
	game_completed = false
	final_boss_hp_remaining = 0
	final_player_hp_remaining = 0
	time_to_complete = 0.0
	total_notes_hit = 0
	perfect_count = 0
	great_count = 0
	good_count = 0
	ok_count = 0
	miss_count = 0
	max_combo_achieved = 0
	
	perfect_count_p1 = 0
	great_count_p1 = 0
	good_count_p1 = 0
	ok_count_p1 = 0
	miss_count_p1 = 0
	
	perfect_count_p2 = 0
	great_count_p2 = 0
	good_count_p2 = 0
	ok_count_p2 = 0
	miss_count_p2 = 0

func add_score(player: int, amount: int):
	current_scores["player" + str(player)] += amount

func update_best_combo(current_combo: int):
	if current_combo > best_combo:
		best_combo = current_combo
		max_combo_achieved = current_combo

func update_best_combo_player(player: int, current_combo: int):
	if player == 1:
		if current_combo > best_combo_player1:
			best_combo_player1 = current_combo
	else:
		if current_combo > best_combo_player2:
			best_combo_player2 = current_combo

func get_player_data(player: int) -> Dictionary:
	return {
		"score": current_scores["player" + str(player)],
		"best_combo": best_combo_player1 if player == 1 else best_combo_player2
	}

# ===== NUEVAS FUNCIONES PARA REGISTRAR ESTADÍSTICAS =====
func record_note_hit(player: int, hit_type: String):
	match hit_type:
		"PERFECT":
			if player == 1:
				perfect_count_p1 += 1
				perfect_count += 1
			else:
				perfect_count_p2 += 1
		"GREAT":
			if player == 1:
				great_count_p1 += 1
				great_count += 1
			else:
				great_count_p2 += 1
		"GOOD":
			if player == 1:
				good_count_p1 += 1
				good_count += 1
			else:
				good_count_p2 += 1
		"OK":
			if player == 1:
				ok_count_p1 += 1
				ok_count += 1
			else:
				ok_count_p2 += 1
	
	total_notes_hit += 1

func record_miss(player: int):
	if player == 1:
		miss_count_p1 += 1
		miss_count += 1
	else:
		miss_count_p2 += 1

func set_game_result(victory: bool, boss_hp: int, player_hp: int, time: float):
	game_completed = victory
	final_boss_hp_remaining = boss_hp
	final_player_hp_remaining = player_hp
	time_to_complete = time
