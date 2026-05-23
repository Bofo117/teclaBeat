extends Node

const API_URL = "https://rhythm-cps0.onrender.com/api"

func test_connection():
	var http = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/global_leaderboard")
	http.request_completed.connect(_on_test_complete.bind(http))

func _on_test_complete(result, code, headers, body, http):
	print("Codigo: ", code)
	if code == 200:
		print("Conectado a la API")
	else:
		print("Error de conexion")
	http.queue_free()

# NUEVA VERSION: Guardar partida completa
func save_game_complete(username: String, game_data: Dictionary):
	print("Guardando partida completa para: ", username)
	var http = HTTPRequest.new()
	add_child(http)
	var body = JSON.stringify({
		"username": username,
		"score": 0,
		"song": game_data.get("song", ""),
		"combo": game_data.get("max_combo", 0),
		"player": 1,
		"victory": game_data.get("victory", false),
		"time": game_data.get("time", 0.0),
		"difficulty": game_data.get("difficulty", "MEDIO"),
		"perfect": game_data.get("perfect", 0),
		"great": game_data.get("great", 0),
		"good": game_data.get("good", 0),
		"ok": game_data.get("ok", 0),
		"miss": game_data.get("miss", 0),
		"boss_hp_remaining": game_data.get("boss_hp_remaining", 0),
		"player_hp_remaining": game_data.get("player_hp_remaining", 0),
		"date": Time.get_datetime_string_from_system()
	})
	var headers = ["Content-Type: application/json"]
	http.request(API_URL + "/save_game_complete", headers, HTTPClient.METHOD_POST, body)
	http.request_completed.connect(_on_save_complete.bind(http))

func _on_save_complete(result, code, headers, body, http):
	print("Guardado - Codigo: ", code)
	if code == 200:
		print("Partida guardada correctamente")
	else:
		print("Error al guardar: ", code)
	http.queue_free()

# Obtener historial completo del usuario
func get_user_games(username: String, callback):
	var http = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/user_games/" + username)
	http.request_completed.connect(func(r, c, h, b):
		if c == 200:
			var data = JSON.parse_string(b.get_string_from_utf8())
			callback.call(data if data else [])
		else:
			callback.call([])
		http.queue_free()
	)

# Obtener estadisticas del usuario
func get_user_stats(username: String, callback):
	var http = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/user_stats/" + username)
	http.request_completed.connect(func(r, c, h, b):
		if c == 200:
			var data = JSON.parse_string(b.get_string_from_utf8())
			callback.call(data if data else {})
		else:
			callback.call({})
		http.queue_free()
	)

# Obtener leaderboard global
func get_global_leaderboard(callback):
	var http = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/global_leaderboard")
	http.request_completed.connect(func(r, c, h, b):
		if c == 200:
			var data = JSON.parse_string(b.get_string_from_utf8())
			callback.call(data if data else [])
		else:
			callback.call([])
		http.queue_free()
	)

# Obtener leaderboard por cancion
func get_song_leaderboard(song: String, callback):
	var http = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/song_leaderboard/" + song)
	http.request_completed.connect(func(r, c, h, b):
		if c == 200:
			var data = JSON.parse_string(b.get_string_from_utf8())
			callback.call(data if data else [])
		else:
			callback.call([])
		http.queue_free()
	)

# Metodos antiguos para compatibilidad
func upload_score(player_name, score, song, combo, player):
	print("Subiendo puntaje - Jugador ", player, ": ", player_name, " - ", score)
	var http = HTTPRequest.new()
	add_child(http)
	var body = JSON.stringify({
		"name": player_name,
		"score": score,
		"song": song,
		"combo": combo,
		"player": player
	})
	var headers = ["Content-Type: application/json"]
	http.request(API_URL + "/scores", headers, HTTPClient.METHOD_POST, body)
	http.request_completed.connect(_on_upload_complete.bind(http))

func _on_upload_complete(result, code, headers, body, http):
	print("Codigo: ", code)
	if code == 200:
		print("Puntaje guardado")
	http.queue_free()

func upload_score_with_player(player_name, score, song, combo, player):
	upload_score(player_name, score, song, combo, player)
