extends Node2D

# Configuración
var current_level_name = "RHYTHM_HELL"
var is_game_active: bool = true
var game_ended: bool = false
var game_result: String = ""

# Música - SOLO AMBIENTAL
var music_player: AudioStreamPlayer
var victory_music: AudioStreamPlayer
var defeat_music: AudioStreamPlayer

# Escenas
@export var player1_scene: PackedScene
@export var player2_scene: PackedScene
@export var villain_scene: PackedScene

# Referencias
var player1: Node2D
var player2: Node2D
var villain: Node2D

# Estado
var player1_alive: bool = true
var player2_alive: bool = true
var game_over_timer: Timer

# Posiciones
var player1_position = Vector2(200, 400)
var player2_position = Vector2(700, 400)
var villain_position = Vector2(450, 150)

# Posiciones de teclas
var player1_key_positions = {
	"button_Q": Vector2(300, 500),
	"button_W": Vector2(380, 500),
	"button_E": Vector2(460, 500),
	"button_R": Vector2(540, 500)
}

var player2_key_positions = {
	"ui_left": Vector2(700, 500),
	"ui_down": Vector2(780, 500),
	"ui_right": Vector2(860, 500),
	"ui_up": Vector2(940, 500)
}

var key_listener_scene: PackedScene = preload("res://objects/key_listener_2p.tscn")

func _ready():
	print("=== INICIANDO MODO 2 JUGADORES ===")
	
	_setup_music()
	_instantiate_players()
	_setup_key_listeners()
	_connect_signals()
	_setup_timer()
	
	# Cargar canción
	if GameManager and GameManager.selected_song_key != "":
		current_level_name = GameManager.selected_song_key
	
	start_game()

func _setup_timer():
	game_over_timer = Timer.new()
	game_over_timer.one_shot = true
	game_over_timer.timeout.connect(_go_to_results)
	add_child(game_over_timer)

func _instantiate_players():
	if player1_scene:
		player1 = player1_scene.instantiate()
		player1.name = "Player2P1"
		player1.position = player1_position
		add_child(player1)
		print("✅ Jugador 1 instanciado")
	
	if player2_scene:
		player2 = player2_scene.instantiate()
		player2.name = "Player2P2"
		player2.position = player2_position
		add_child(player2)
		print("✅ Jugador 2 instanciado")
	
	if villain_scene:
		villain = villain_scene.instantiate()
		villain.name = "Villain"
		villain.position = villain_position
		add_child(villain)
		print("✅ Villano instanciado")

func _setup_key_listeners():
	print("📌 Configurando KeyListeners...")
	
	for key_name in player1_key_positions:
		var listener = key_listener_scene.instantiate()
		listener.player_id = 1
		listener.key_name = key_name
		listener.frame = _get_frame_from_key(key_name)
		listener.position = player1_key_positions[key_name]
		listener.enable_random_spawn = true
		player1.add_child(listener)
		print("   ✅ J1: ", key_name)
	
	for key_name in player2_key_positions:
		var listener = key_listener_scene.instantiate()
		listener.player_id = 2
		listener.key_name = key_name
		listener.frame = _get_frame_from_key_2p(key_name)
		listener.position = player2_key_positions[key_name]
		listener.enable_random_spawn = true
		player2.add_child(listener)
		print("   ✅ J2: ", key_name)

func _get_frame_from_key(key_name: String) -> int:
	match key_name:
		"button_Q": return 0
		"button_W": return 1
		"button_E": return 2
		"button_R": return 3
	return 0

func _get_frame_from_key_2p(key_name: String) -> int:
	match key_name:
		"ui_left": return 0
		"ui_down": return 1
		"ui_right": return 2
		"ui_up": return 3
	return 0

func _setup_music():
	# Música ambiental (loop)
	music_player = AudioStreamPlayer.new()
	music_player.name = "AmbientMusic"
	add_child(music_player)
	
	# Música de victoria
	victory_music = AudioStreamPlayer.new()
	victory_music.name = "VictoryMusic"
	add_child(victory_music)
	
	# Música de derrota
	defeat_music = AudioStreamPlayer.new()
	defeat_music.name = "DefeatMusic"
	add_child(defeat_music)
	
	# Cargar archivos
	var ambient_song = load("res://music/Rhythm Hell.wav")
	if ambient_song:
		music_player.stream = ambient_song
	
	var victory_song = load("res://music/victory.wav") if ResourceLoader.exists("res://music/victory.wav") else null
	if victory_song:
		victory_music.stream = victory_song
	
	var defeat_song = load("res://music/game_over.wav") if ResourceLoader.exists("res://music/game_over.wav") else null
	if defeat_song:
		defeat_music.stream = defeat_song

func _connect_signals():
	# Conectar señales de muerte
	if player1 and player1.has_signal("player_died"):
		player1.player_died.connect(_on_player_died.bind(1))
	
	if player2 and player2.has_signal("player_died"):
		player2.player_died.connect(_on_player_died.bind(2))
	
	# Conectar victoria del villano
	if villain and villain.has_signal("villain_defeated"):
		villain.villain_defeated.connect(_on_villain_defeated)
	
	# ⚠️ IMPORTANTE: La música ambiental SOLO se reinicia, NO termina el juego
	if music_player:
		# Desconectar cualquier conexión previa
		if music_player.finished.is_connected(_on_music_finished):
			music_player.finished.disconnect(_on_music_finished)
		if music_player.finished.is_connected(_on_ambient_music_finished):
			music_player.finished.disconnect(_on_ambient_music_finished)
		# Conectar para reiniciar
		music_player.finished.connect(_on_ambient_music_finished)

# 🔥 CRÍTICO: Esta función SOLO reinicia la música, NO termina el juego
func _on_ambient_music_finished():
	print("🎵 Música ambiental terminó - Reiniciando (sin afectar el juego)")
	music_player.play()

# Evitar que exista esta función o asegurar que no haga nada
func _on_music_finished():
	# Esta función NO DEBE existir o debe estar vacía
	print("⚠️ _on_music_finished llamado - IGNORADO")
	pass

# ===== MANEJAR MUERTE =====
func _on_player_died(player_id: int):
	if game_ended:
		return
	
	if player_id == 1:
		player1_alive = false
		print("⚠️ Jugador 1 ha muerto")
		_show_floating_message("¡JUGADOR 1 ELIMINADO!", Color(1, 0.3, 0.3))
		_stop_player_notes(1)
	else:
		player2_alive = false
		print("⚠️ Jugador 2 ha muerto")
		_show_floating_message("¡JUGADOR 2 ELIMINADO!", Color(1, 0.5, 0.2))
		_stop_player_notes(2)
	
	# Verificar si ambos están muertos
	if not player1_alive and not player2_alive:
		print("💀 AMBOS JUGADORES MUERTOS - GAME OVER 💀")
		_end_game(false)

func _stop_player_notes(player_id: int):
	print("🛑 Deteniendo notas del Jugador ", player_id)
	
	var all_listeners = get_tree().get_nodes_in_group("key_listener")
	for listener in all_listeners:
		var listener_id = listener.get("player_id") if "player_id" in listener else 0
		if listener_id == player_id:
			if listener.has_method("set_game_active"):
				listener.set_game_active(false)
			if listener.has_method("_on_game_over"):
				listener._on_game_over()
	
	var all_notes = get_tree().get_nodes_in_group("falling_notes")
	for note in all_notes:
		if is_instance_valid(note):
			var note_owner = note.get("owner_player_id") if "owner_player_id" in note else 0
			if note_owner == player_id:
				note.queue_free()

# ===== VICTORIA =====
func _on_villain_defeated():
	if game_ended:
		return
	
	print("🏆 ¡VILLANO DERROTADO! - VICTORIA!")
	_end_game(true)

# ===== TERMINAR JUEGO =====
func _end_game(is_victory: bool):
	if game_ended:
		return
	
	game_ended = true
	is_game_active = false
	game_result = "victory" if is_victory else "defeat"
	
	print("=== FIN DEL JUEGO ===")
	print("Resultado: ", game_result.upper())
	
	# Detener música ambiental
	if music_player and music_player.playing:
		music_player.stop()
	
	# Detener toda actividad
	_stop_all_game_activity()
	
	# Reproducir música de resultado
	if is_victory:
		if victory_music and victory_music.stream:
			victory_music.play()
		_show_victory_message()
	else:
		if defeat_music and defeat_music.stream:
			defeat_music.play()
		_show_defeat_message()
	
	# Guardar datos
	_save_game_data()
	
	# Esperar y cambiar de escena
	var wait_time = 3.5
	game_over_timer.start(wait_time)

func _stop_all_game_activity():
	print("🛑 Deteniendo toda la actividad...")
	
	var all_listeners = get_tree().get_nodes_in_group("key_listener")
	for listener in all_listeners:
		if listener.has_method("set_game_active"):
			listener.set_game_active(false)
		if listener.has_method("_on_game_over"):
			listener._on_game_over()
	
	var all_notes = get_tree().get_nodes_in_group("falling_notes")
	for note in all_notes:
		if is_instance_valid(note):
			note.queue_free()
	
	print("   ✅ Actividad detenida")

# ===== MENSAJES =====
func _show_floating_message(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_modulate", Color(0, 0, 0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var screen_size = get_viewport().get_visible_rect().size
	label.position = Vector2((screen_size.x - 400) / 2, screen_size.y - 150)
	label.size = Vector2(400, 50)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0, 2.0)
	tween.tween_callback(label.queue_free)

func _show_victory_message():
	var panel = Panel.new()
	panel.size = Vector2(500, 200)
	panel.position = Vector2(470, 250)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.2, 0.9, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var victory_label = Label.new()
	victory_label.text = "¡VICTORIA!"
	victory_label.position = Vector2(150, 40)
	victory_label.size = Vector2(200, 60)
	victory_label.add_theme_font_size_override("font_size", 48)
	victory_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(victory_label)
	
	var message_label = Label.new()
	var survivors = []
	if player1_alive: survivors.append("1")
	if player2_alive: survivors.append("2")
	
	if survivors.size() == 2:
		message_label.text = "¡Ambos jugadores derrotaron al villano!"
	elif survivors.size() == 1:
		message_label.text = "¡Jugador " + survivors[0] + " derrotó al villano!"
	else:
		message_label.text = "¡Villano derrotado!"
	
	message_label.position = Vector2(100, 110)
	message_label.size = Vector2(300, 40)
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(message_label)

func _show_defeat_message():
	var panel = Panel.new()
	panel.size = Vector2(500, 200)
	panel.position = Vector2(470, 250)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.9, 0.2, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var defeat_label = Label.new()
	defeat_label.text = "GAME OVER"
	defeat_label.position = Vector2(150, 40)
	defeat_label.size = Vector2(200, 60)
	defeat_label.add_theme_font_size_override("font_size", 48)
	defeat_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	defeat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(defeat_label)
	
	var message_label = Label.new()
	if not player1_alive and not player2_alive:
		message_label.text = "Ambos jugadores fueron derrotados"
	else:
		message_label.text = "No lograron derrotar al villano"
	message_label.position = Vector2(100, 110)
	message_label.size = Vector2(300, 40)
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(message_label)

# ===== FUNCIONES PRINCIPALES =====
func start_game():
	print("🎮 Iniciando juego de 2 jugadores...")
	player1_alive = true
	player2_alive = true
	game_ended = false
	game_result = ""
	is_game_active = true
	
	# Iniciar música ambiental en LOOP
	if music_player and music_player.stream:
		music_player.play()
		print("🎵 Música ambiental iniciada (loop infinito)")

func _go_to_results():
	print("📺 Cambiando a pantalla de resultados 2P")
	
	var tree = get_tree()
	if not tree:
		print("❌ Error: get_tree() es null")
		return
	
	# Detener todas las músicas
	if music_player: music_player.stop()
	if victory_music: victory_music.stop()
	if defeat_music: defeat_music.stop()
	
	var scene_path = "res://scenes/menu/result_screen_2p.tscn"
	var result = tree.change_scene_to_file(scene_path)
	
	if result != OK:
		print("❌ Error al cambiar a: ", scene_path)
		tree.change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _save_game_data():
	if not GameManager:
		return
	
	if player1 and player1.has_method("get_stats"):
		var stats1 = player1.get_stats()
		GameManager.perfect_count_p1 = stats1.perfect
		GameManager.great_count_p1 = stats1.great
		GameManager.good_count_p1 = stats1.good
		GameManager.ok_count_p1 = stats1.ok
		GameManager.miss_count_p1 = stats1.miss
		GameManager.current_scores.player1 = stats1.score
	
	if player2 and player2.has_method("get_stats"):
		var stats2 = player2.get_stats()
		GameManager.perfect_count_p2 = stats2.perfect
		GameManager.great_count_p2 = stats2.great
		GameManager.good_count_p2 = stats2.good
		GameManager.ok_count_p2 = stats2.ok
		GameManager.miss_count_p2 = stats2.miss
		GameManager.current_scores.player2 = stats2.score
	
	GameManager.current_song_name = current_level_name
	GameManager.game_mode = 2
	GameManager.game_completed = (game_result == "victory")

func _on_game_restart():
	print("🔄 Reiniciando juego 2P")
	game_ended = false
	is_game_active = true
	player1_alive = true
	player2_alive = true
	
	if player1 and player1.has_method("reset"):
		player1.reset()
	if player2 and player2.has_method("reset"):
		player2.reset()
	if villain and villain.has_method("reset_villain"):
		villain.reset_villain()
	
	var all_listeners = get_tree().get_nodes_in_group("key_listener")
	for listener in all_listeners:
		if listener.has_method("set_game_active"):
			listener.set_game_active(true)
		if listener.has_method("_on_game_restart"):
			listener._on_game_restart()
	
	if music_player and music_player.stream:
		music_player.play()
