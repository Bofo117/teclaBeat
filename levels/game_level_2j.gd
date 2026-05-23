extends Node2D

const in_edit_mode: bool = false
var current_level_name = "RHYTHM_HELL"
var fk_fall_time: float = 2.2
var music_start_delay: float = 0.2
var sync_offset: float = -0.95
var player1_best_combo: int = 0
var player2_best_combo: int = 0

var level_info = {
	"RHYTHM_HELL": {
		"fk_times": "[[2.52533321380615, 6.55733375549316, 10.5573337554932, 14.5040004730225, 14.6533325195313, 15.5493324279785, 15.6986663818359, 15.9333332061768, 16.0719993591309, 19.76266746521, 22.8666675567627, 27.2293327331543, 30.823998260498, 34.5786674499512, 34.7173316955566, 35.0159996032715, 35.282666015625, 35.4640014648437, 35.6453330993652, 35.9333351135254, 36.1466682434082, 36.2533348083496, 36.3706672668457, 40.4133346557617], [3.03733329772949, 7.0586669921875, 7.28266696929932, 11.5600002288818, 11.8053329467773, 14.9200008392334, 15.0479991912842, 15.282666015625, 15.5813339233398, 16.296000289917, 18.8026664733887, 19.9119995117188, 20.0826671600342, 23.2080009460449, 23.346667098999, 23.9226673126221, 24.3279998779297, 26.792000579834, 27.7200000762939, 28.1253326416016, 31.1759994506836, 31.858666229248, 34.8453338623047, 34.9839981079102, 35.1546676635742, 35.3999984741211, 35.5706680297852, 35.741333770752, 35.8693321228027, 36.0186660766602, 36.1359985351562, 36.2533348083496], [3.56000022888184, 7.54933338165283, 10.7919996261597, 11.0266664505005, 14.5040004730225, 14.6533325195313, 15.5600002288818, 15.7093341827393, 15.9333332061768, 16.0826671600342, 19.0373332977295, 19.1973331451416, 19.3893325805664, 20.274666595459, 20.4026668548584, 23.5493324279785, 23.7093341827393, 24.1146667480469, 27.0159996032715, 27.9333332061768, 31.5280006408691, 32.231999206543], [4.07199983596802, 8.06133346557617, 12.0613334655762, 26.5893333435059, 27.4639995574951]]",
		"music": load("res://music/Rhythm Hell.wav")
	}
}

var spawn_timers_j1 = []
var spawn_timers_j2 = []
var music_started = false

@onready var music_player = $MusicPlayer

@onready var j1_keys = {
	"button_Q": $J1_KeyListener_Q,
	"button_W": $J1_KeyListener_W,
	"button_E": $J1_KeyListener_E,
	"button_R": $J1_KeyListener_R
}
@onready var j2_keys = {
	"ui_left": $J2_KeyListener_Left,
	"ui_down": $J2_KeyListener_Down,
	"ui_right": $J2_KeyListener_Right,
	"ui_up": $J2_KeyListener_Up
}

func _ready():
	if not music_player:
		music_player = find_child("MusicPlayer", true, false)
		if not music_player:
			print("ERROR: No hay MusicPlayer")
			return
	
	# CONECTAR LA SEÑAL MANUALMENTE
	if music_player and not music_player.finished.is_connected(_on_music_player_finished):
		music_player.finished.connect(_on_music_player_finished)
		print("Señal de música conectada correctamente")
	
	configure_key_listeners()
	
	if GameManager and GameManager.selected_song_key != "":
		current_level_name = GameManager.selected_song_key
	
	load_level()

func configure_key_listeners():
	print("=== Configurando KeyListeners ===")
	
	for key_name in j1_keys:
		if j1_keys[key_name]:
			j1_keys[key_name].set_player_id(1)
			j1_keys[key_name].set_key_name(key_name)
			print("J1: ", key_name, " -> ID: 1")
	
	for key_name in j2_keys:
		if j2_keys[key_name]:
			j2_keys[key_name].set_player_id(2)
			j2_keys[key_name].set_key_name(key_name)
			print("J2: ", key_name, " -> ID: 2")
			
func load_level():
	var fk_times = level_info.get(current_level_name).get("fk_times")
	var fk_times_arr = str_to_var(fk_times)
	
	var counter: int = 0
	for key in fk_times_arr:
		var button_name_j1: String = ""
		var button_name_j2: String = ""
		
		match counter:
			0:
				button_name_j1 = "button_Q"
				button_name_j2 = "ui_left"
			1:
				button_name_j1 = "button_W"
				button_name_j2 = "ui_down"
			2:
				button_name_j1 = "button_R"
				button_name_j2 = "ui_right"
			3:
				button_name_j1 = "button_E"
				button_name_j2 = "ui_up"
		
		for delay in key:
			var adjusted_delay = delay - fk_fall_time + sync_offset + music_start_delay
			if adjusted_delay < 0:
				adjusted_delay = 0
			
			spawn_timers_j1.append({"button": button_name_j1, "delay": adjusted_delay})
			spawn_timers_j2.append({"button": button_name_j2, "delay": adjusted_delay})
		
		counter += 1
	
	await get_tree().process_frame
	start_game()

func start_game():
	print("Iniciando juego de 2 jugadores...")
	print("Spawns J1: ", spawn_timers_j1.size())
	print("Spawns J2: ", spawn_timers_j2.size())
	
	await get_tree().create_timer(music_start_delay).timeout
	
	music_player.stream = level_info.get(current_level_name).get("music")
	music_player.play()
	
	for spawn_data in spawn_timers_j1:
		SpawnFallingKey(spawn_data.button, spawn_data.delay)
	
	for spawn_data in spawn_timers_j2:
		SpawnFallingKey(spawn_data.button, spawn_data.delay)
	
	music_started = true
	print("Juego de 2 jugadores iniciado")

func SpawnFallingKey(button_name: String, delay: float):
	await get_tree().create_timer(delay).timeout
	Signals.CreateFallingKey.emit(button_name)

func _on_music_player_finished():
	print("=== ¡¡¡LA MÚSICA TERMINÓ!!! ===")
	print("FIN DEL JUEGO 2 PLAYERS")
	
	# Mostrar scores actuales desde GameManager
	if GameManager:
		print("J1 Score: ", GameManager.current_scores.player1)
		print("J2 Score: ", GameManager.current_scores.player2)
		
		GameManager.current_song_name = current_level_name
		GameManager.game_mode = 2
	
	print("Cargando pantalla de resultados...")
	var result = get_tree().change_scene_to_file("res://scenes/menu/result_screen_2p.tscn")
	print("Resultado de cambio de escena: ", result)
