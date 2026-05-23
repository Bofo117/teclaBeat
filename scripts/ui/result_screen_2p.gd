# scripts/ui/result_screen_2p.gd
extends Panel

const API_URL = "https://rhythm-cps0.onrender.com/api"

# Variables para almacenar datos
var player1_score: int = 0
var player1_best_combo: int = 0
var player2_score: int = 0
var player2_best_combo: int = 0
var song_name: String = ""

# Referencias UI
var title_label: Label
var song_label: Label
var player1_score_label: Label
var player1_combo_label: Label
var player2_score_label: Label
var player2_combo_label: Label
var message_label: Label
var continue_button: Button

func _ready():
	print("=== PANTALLA RESULTADOS 2P ===")
	create_ui()
	load_data()
	center_panel()

func create_ui():
	size = Vector2(700, 500)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.8, 0.6, 0.2)
	add_theme_stylebox_override("panel", style)
	
	title_label = Label.new()
	title_label.text = "RESULTADOS FINALES"
	title_label.position = Vector2(200, 20)
	title_label.size = Vector2(300, 40)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	
	song_label = Label.new()
	song_label.position = Vector2(200, 60)
	song_label.size = Vector2(300, 30)
	song_label.add_theme_font_size_override("font_size", 16)
	song_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	song_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(song_label)
	
	var sep = HSeparator.new()
	sep.position = Vector2(50, 95)
	sep.size = Vector2(600, 5)
	add_child(sep)
	
	# JUGADOR 1
	var j1_title = Label.new()
	j1_title.text = "JUGADOR 1 (QWER)"
	j1_title.position = Vector2(50, 120)
	j1_title.size = Vector2(280, 25)
	j1_title.add_theme_font_size_override("font_size", 18)
	j1_title.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	add_child(j1_title)
	
	player1_score_label = Label.new()
	player1_score_label.position = Vector2(50, 155)
	player1_score_label.size = Vector2(280, 30)
	player1_score_label.add_theme_font_size_override("font_size", 22)
	player1_score_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(player1_score_label)
	
	player1_combo_label = Label.new()
	player1_combo_label.position = Vector2(50, 190)
	player1_combo_label.size = Vector2(280, 25)
	player1_combo_label.add_theme_font_size_override("font_size", 18)
	player1_combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	add_child(player1_combo_label)
	
	# JUGADOR 2
	var j2_title = Label.new()
	j2_title.text = "JUGADOR 2 (←↓→↑)"
	j2_title.position = Vector2(370, 120)
	j2_title.size = Vector2(280, 25)
	j2_title.add_theme_font_size_override("font_size", 18)
	j2_title.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	add_child(j2_title)
	
	player2_score_label = Label.new()
	player2_score_label.position = Vector2(370, 155)
	player2_score_label.size = Vector2(280, 30)
	player2_score_label.add_theme_font_size_override("font_size", 22)
	player2_score_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(player2_score_label)
	
	player2_combo_label = Label.new()
	player2_combo_label.position = Vector2(370, 190)
	player2_combo_label.size = Vector2(280, 25)
	player2_combo_label.add_theme_font_size_override("font_size", 18)
	player2_combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	add_child(player2_combo_label)
	
	# Mensaje
	message_label = Label.new()
	message_label.position = Vector2(250, 310)
	message_label.size = Vector2(200, 50)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(message_label)
	
	# Botón continuar
	continue_button = Button.new()
	continue_button.text = "CONTINUAR"
	continue_button.position = Vector2(275, 380)
	continue_button.size = Vector2(150, 45)
	continue_button.add_theme_font_size_override("font_size", 16)
	continue_button.pressed.connect(_on_continue_pressed)
	add_child(continue_button)

func center_panel():
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	position = Vector2(
		(screen_size.x - size.x) / 2,
		(screen_size.y - size.y) / 2
	)

func load_data():
	print("=== CARGANDO DATOS ===")
	
	if GameManager:
		player1_score = GameManager.current_scores.player1
		player1_best_combo = GameManager.best_combo_player1
		player2_score = GameManager.current_scores.player2
		player2_best_combo = GameManager.best_combo_player2
		song_name = GameManager.current_song_name
	
	player1_score_label.text = "PUNTUACIÓN: " + format_score(player1_score) + " pts"
	player1_combo_label.text = "MEJOR COMBO: x" + str(player1_best_combo)
	player2_score_label.text = "PUNTUACIÓN: " + format_score(player2_score) + " pts"
	player2_combo_label.text = "MEJOR COMBO: x" + str(player2_best_combo)
	song_label.text = "CANCIÓN: " + song_name
	
	if player1_score >= 50000:
		player1_score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	
	if player2_score >= 50000:
		player2_score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	
	# Guardar automáticamente
	auto_save()

func format_score(score: int) -> String:
	var str_score = str(score)
	var result = ""
	var count = 0
	for i in range(str_score.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_score[i] + result
		count += 1
	return result

func auto_save():
	var is_logged_in = GameManager and GameManager.current_user and GameManager.current_user != "" and GameManager.current_user != "INVITADO"
	
	if is_logged_in:
		save_scores(GameManager.current_user)
	else:
		message_label.text = "Crea una cuenta para guardar tus puntajes"
		message_label.add_theme_color_override("font_color", Color.YELLOW)
		continue_button.disabled = false

func save_scores(username: String):
	print("Guardando partidas de 2 jugadores para: ", username)
	message_label.text = "Guardando puntajes..."
	message_label.add_theme_color_override("font_color", Color.YELLOW)
	continue_button.disabled = true
	
	var pending = 2
	
	var check_complete = func():
		pending -= 1
		if pending == 0:
			message_label.text = "¡Puntajes guardados!"
			message_label.add_theme_color_override("font_color", Color.GREEN)
			continue_button.disabled = false
	
	var save_player = func(player_num, score, combo):
		var http = HTTPRequest.new()
		add_child(http)
		var body = JSON.stringify({
			"username": username,
			"score": score,
			"song": song_name,
			"combo": combo,
			"player": player_num,
			"date": Time.get_datetime_string_from_system()
		})
		var headers = ["Content-Type: application/json"]
		http.request(API_URL + "/save_game", headers, HTTPClient.METHOD_POST, body)
		http.request_completed.connect(func(result, code, headers, body, http):
			http.queue_free()
			check_complete.call()
		)
	
	save_player.call(1, player1_score, player1_best_combo)
	save_player.call(2, player2_score, player2_best_combo)

func _on_continue_pressed():
	if GameManager:
		GameManager.reset_game_data()
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
