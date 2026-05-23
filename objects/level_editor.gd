extends Node2D

# Set this constant before game start
const in_edit_mode: bool = false
var current_level_name = "RHYTHM_HELL"
var is_game_active: bool = true
var villain_defeated_flag: bool = false

# ===== NUEVAS VARIABLES PARA MÚSICA =====
var music_player: AudioStreamPlayer
var defeat_music: AudioStream
var victory_music: AudioStream
var is_music_playing: bool = false
var game_ended: bool = false  # Evitar múltiples transiciones

# Time it takes for falling key to reach critical spot
var fk_fall_time: float = 2.2
var fk_output_arr = [[], [], [], []]

@onready var player_health = $PlayerHealth if has_node("PlayerHealth") else null
@onready var villain = $Villain if has_node("Villain") else null

# ===== VARIABLES DE PUNTUACIÓN =====
var score: int = 0
var combo_count: int = 0
var best_combo: int = 0
var game_finished: bool = false

var level_info = {
	"RHYTHM_HELL" = {
		"fk_times": "[[2.52533321380615, 6.55733375549316, 10.5573337554932, 14.5040004730225, 14.6533325195313, 15.5493324279785, 15.6986663818359, 15.9333332061768, 16.0719993591309, 19.76266746521, 22.8666675567627, 27.2293327331543, 30.823998260498, 34.5786674499512, 34.7173316955566, 35.0159996032715, 35.282666015625, 35.4640014648437, 35.6453330993652, 35.9333351135254, 36.1466682434082, 36.2533348083496, 36.3706672668457, 40.4133346557617], [3.03733329772949, 7.0586669921875, 7.28266696929932, 11.5600002288818, 11.8053329467773, 14.9200008392334, 15.0479991912842, 15.282666015625, 15.5813339233398, 16.296000289917, 18.8026664733887, 19.9119995117188, 20.0826671600342, 23.2080009460449, 23.346667098999, 23.9226673126221, 24.3279998779297, 26.792000579834, 27.7200000762939, 28.1253326416016, 31.1759994506836, 31.858666229248, 34.8453338623047, 34.9839981079102, 35.1546676635742, 35.3999984741211, 35.5706680297852, 35.741333770752, 35.8693321228027, 36.0186660766602, 36.1359985351562, 36.2533348083496], [3.56000022888184, 7.54933338165283, 10.7919996261597, 11.0266664505005, 14.5040004730225, 14.6533325195313, 15.5600002288818, 15.7093341827393, 15.9333332061768, 16.0826671600342, 19.0373332977295, 19.1973331451416, 19.3893325805664, 20.274666595459, 20.4026668548584, 23.5493324279785, 23.7093341827393, 24.1146667480469, 27.0159996032715, 27.9333332061768, 31.5280006408691, 32.231999206543], [4.07199983596802, 8.06133346557617, 12.0613334655762, 26.5893333435059, 27.4639995574951]]",
		"music": load("res://music/Rhythm Hell.wav")
	}
}

var spawn_timers = []
var music_started = false
var sync_offset: float = -0.95
var music_start_delay: float = 0.2

func _ready():
	# ===== CARGAR MÚSICAS =====
	_setup_music()
	
	# Conectar señales
	Signals.IncrementScore.connect(_on_increment_score)
	Signals.IncrementCombo.connect(_on_increment_combo)
	Signals.ResetCombo.connect(_on_reset_combo)
	Signals.GameOver.connect(_on_game_over)
	Signals.GameRestart.connect(_on_game_restart)
	
	# Obtener el nombre de la canción desde GameManager si existe
	if GameManager and GameManager.selected_song_key != "":
		current_level_name = GameManager.selected_song_key
		print("Canción cargada desde GameManager: ", current_level_name)
	
	if player_health:
		player_health.health_changed.connect(_on_player_health_changed)
		player_health.player_died.connect(_on_player_died)
		print("✅ Salud del jugador conectada")
	
	# Configurar villano
	if villain:
		villain.health_changed.connect(_on_villain_health_changed)
		villain.villain_defeated.connect(_on_villain_defeated)
	
	if in_edit_mode:
		Signals.KeyListenerPress.connect(KeyListenerPress)
	else:
		var fk_times = level_info.get(current_level_name).get("fk_times")
		var fk_times_arr = str_to_var(fk_times)
		
		var counter: int = 0
		for key in fk_times_arr:
			var button_name: String = ""
			match counter:
				0:
					button_name = "button_Q"
				1:
					button_name = "button_W"
				2:
					button_name = "button_E"
				3:
					button_name = "button_R"
			
			for delay in key:
				var adjusted_delay = delay - fk_fall_time + sync_offset + music_start_delay
				if adjusted_delay < 0:
					adjusted_delay = 0
				spawn_timers.append({"button": button_name, "delay": adjusted_delay})
			
			counter += 1
	
	_setup_key_listeners()
	await get_tree().process_frame
	start_game()

# ===== NUEVA FUNCIÓN: CONFIGURAR MÚSICA =====
func _setup_music():
	# Crear el reproductor de música si no existe
	if not music_player:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		add_child(music_player)
		print("✅ MusicPlayer creado")
	
	# Cargar músicas adicionales (asegúrate de tener estos archivos)
	# Si no tienes estos archivos, comenta las líneas o crea los archivos
	defeat_music = load("res://music/game_over.wav") if ResourceLoader.exists("res://music/game_over.wav") else null
	victory_music = load("res://music/victory.wav") if ResourceLoader.exists("res://music/victory.wav") else null
	
	if not defeat_music:
		print("⚠️ No se encontró música de derrota en 'res://music/game_over.wav'")
	if not victory_music:
		print("⚠️ No se encontró música de victoria en 'res://music/victory.wav'")

# ===== NUEVA FUNCIÓN: REPRODUCIR MÚSICA PRINCIPAL EN BUCLE =====
func play_game_music():
	if not music_player:
		_setup_music()
	
	var song_stream = level_info.get(current_level_name).get("music") if level_info.has(current_level_name) else null
	
	if song_stream:
		music_player.stream = song_stream
		music_player.play()
		is_music_playing = true
		print("🎵 Música principal iniciada (loop habilitado)")
	else:
		print("❌ No se encontró música para: ", current_level_name)

# ===== NUEVA FUNCIÓN: REPRODUCIR MÚSICA DE DERROTA =====
func play_defeat_music():
	if not music_player:
		_setup_music()
	
	if defeat_music:
		music_player.stop()
		music_player.stream = defeat_music
		music_player.play()
		print("💀 Reproduciendo música de derrota")
	else:
		print("⚠️ No se puede reproducir música de derrota - archivo no encontrado")

# ===== NUEVA FUNCIÓN: REPRODUCIR MÚSICA DE VICTORIA =====
func play_victory_music():
	if not music_player:
		_setup_music()
	
	if victory_music:
		music_player.stop()
		music_player.stream = victory_music
		music_player.play()
		print("🏆 Reproduciendo música de victoria")
	else:
		print("⚠️ No se puede reproducir música de victoria - archivo no encontrado")

# ===== NUEVA FUNCIÓN: DETENER MÚSICA =====
func stop_music():
	if music_player and music_player.playing:
		music_player.stop()
		is_music_playing = false
		print("🔇 Música detenida")

func _setup_key_listeners():
	print("=== CONFIGURANDO KEY LISTENERS ===")
	
	# Buscar todos los KeyListeners de diferentes maneras
	var all_listeners = []
	
	# Método 1: Buscar por nombre en la raíz
	for child in get_children():
		if child is Sprite2D and (child.name.contains("KeyListener") or child.name.contains("key")):
			all_listeners.append(child)
	
	# Método 2: Buscar por grupos
	var group_listeners = get_tree().get_nodes_in_group("key_listener")
	all_listeners.append_array(group_listeners)
	
	# Método 3: Buscar por nombres específicos
	var specific_names = ["KeyListener_Q", "KeyListener_W", "KeyListener_E", "KeyListener_R",
						  "J1_KeyListener_Q", "J1_KeyListener_W", "J1_KeyListener_E", "J1_KeyListener_R",
						  "button_Q", "button_W", "button_E", "button_R"]
	
	for name in specific_names:
		var node = get_node_or_null(name)
		if node and node not in all_listeners:
			all_listeners.append(node)
	
	# Limpiar duplicados
	all_listeners = _unique_array(all_listeners)
	
	if all_listeners.is_empty():
		print("❌ ERROR CRÍTICO: No se encontraron KeyListeners")
		print("   Por favor, verifica que los KeyListeners existan en la escena")
		return
	
	print("✅ Encontrados ", all_listeners.size(), " KeyListeners")
	
	# Configurar cada KeyListener
	var key_mapping = [
		{"name": "Q", "key": "button_Q", "frame": 0},
		{"name": "W", "key": "button_W", "frame": 1},
		{"name": "E", "key": "button_E", "frame": 2},
		{"name": "R", "key": "button_R", "frame": 3}
	]
	
	for i in range(min(all_listeners.size(), key_mapping.size())):
		var listener = all_listeners[i]
		var mapping = key_mapping[i]
		
		if listener.has_method("set_key_name"):
			listener.set_key_name(mapping["key"])
		else:
			listener.key_name = mapping["key"]
		
		if listener.has_method("set_player_id"):
			listener.set_player_id(1)
		else:
			listener.player_id = 1
		
		listener.frame = mapping["frame"]
		
		print("   ✅ Configurado: ", listener.name, " -> tecla: ", mapping["key"])

func _unique_array(arr):
	var dict = {}
	for item in arr:
		dict[item] = true
	return dict.keys()

func _on_game_over():
	if game_ended:
		return
	
	game_ended = true
	print("🏁 Game Over - Deteniendo juego")
	is_game_active = false
	
	# Reproducir música de derrota
	play_defeat_music()

func _on_game_restart():
	print("🔄 Reiniciando juego")
	is_game_active = true
	game_ended = false
	
	# Reiniciar música principal
	play_game_music()

func _on_increment_score(incr: int):
	score += incr
	print("Score: ", score)

func _on_increment_combo():
	combo_count += 1
	if combo_count > best_combo:
		best_combo = combo_count
	print("Combo: ", combo_count)

func _on_reset_combo():
	combo_count = 0
	print("Combo reset")

func start_game():
	print("Iniciando juego con spawn aleatorio...")
	
	# Ya no usamos spawn_timers programados
	# Los KeyListeners ya tienen sus propios timers aleatorios
	
	# Iniciar música en bucle
	play_game_music()
	
	music_started = true
	print("Juego iniciado - Las notas aparecerán aleatoriamente")
	_verify_key_listeners()

func _verify_key_listeners():
	print("=== VERIFICANDO KEY LISTENERS ===")
	
	# Buscar todos los nodos KeyListener en la escena
	var all_nodes = get_tree().get_nodes_in_group("key_listener")
	if all_nodes.is_empty():
		# Buscar por nombre alternativo
		all_nodes = get_tree().get_nodes_in_group("KeyListener")
	
	if all_nodes.is_empty():
		# Buscar manualmente por hijos
		for child in get_children():
			if child.name.contains("KeyListener") or child.name.contains("key"):
				all_nodes.append(child)
	
	if all_nodes.is_empty():
		print("⚠️ No se encontraron KeyListeners por grupo, buscando por nombre específico...")
		var possible_names = ["KeyListener_Q", "KeyListener_W", "KeyListener_E", "KeyListener_R", 
							  "J1_KeyListener_Q", "J1_KeyListener_W", "J1_KeyListener_E", "J1_KeyListener_R",
							  "button_Q", "button_W", "button_E", "button_R"]
		
		for name in possible_names:
			var node = get_node_or_null(name)
			if node:
				print("✅ KeyListener encontrado por nombre: ", name)
				all_nodes.append(node)
	
	if all_nodes.is_empty():
		print("❌ ERROR: No se encontraron KeyListeners en la escena")
		print("   Nodos hijos disponibles:")
		for child in get_children():
			print("   - ", child.name)
	else:
		print("✅ Total KeyListeners encontrados: ", all_nodes.size())

func KeyListenerPress(button_name: String, array_num: int):
	if music_started:
		fk_output_arr[array_num].append($MusicPlayer.get_playback_position() - fk_fall_time)

func _on_player_health_changed(current, max):
	print("Jugador HP: ", current, "/", max)

func _on_player_died():
	if game_ended:
		return
	
	game_ended = true
	print("💀 Game Over - El jugador ha muerto")
	
	if not is_game_active:
		return
	
	is_game_active = false
	
	# Reproducir música de derrota (se maneja en _on_game_over también)
	# Pero como player_died se emite antes, aseguramos
	if not game_ended:
		_on_game_over()
	
	_stop_game_immediately()

func _stop_game_immediately():
	# 1. Detener música si no se ha cambiado ya
	if music_player and music_player.playing:
		# No detenemos aquí porque ya se reproduce la música de derrota
		pass
	
	# 2. Detener todos los timers de spawn
	var all_timers = get_tree().get_nodes_in_group("spawn_timers")
	for timer in all_timers:
		if timer is Timer:
			timer.stop()
	
	# 3. Limpiar todas las notas
	var falling_keys = get_tree().get_nodes_in_group("falling_keys")
	for key in falling_keys:
		if is_instance_valid(key):
			key.queue_free()
	
	# 4. Desactivar key listeners
	var key_listeners = get_tree().get_nodes_in_group("key_listeners")
	for listener in key_listeners:
		listener.set_process(false)
		listener.set_physics_process(false)

func stop_spawning():
	is_game_active = false

func _on_villain_health_changed(current, max):
	print("Villano HP: ", current, "/", max)

func _on_villain_defeated():
	if villain_defeated_flag or game_ended:
		return
	
	villain_defeated_flag = true
	game_ended = true
	print("🏆 VICTORIA! Villano derrotado!")
	
	# Detener la música actual y reproducir victoria
	play_victory_music()
	
	# Emitir GameOver para detener spawn de notas
	Signals.GameOver.emit()
	
	# Guardar datos finales antes de cambiar de escena
	if GameManager:
		print("Score final Jugador 1: ", GameManager.current_scores.player1)
		print("Mejor combo: ", GameManager.best_combo)
		GameManager.current_song_name = GameManager.selected_song_key if GameManager.selected_song_key else "RHYTHM_HELL"
	
	# Mostrar mensaje de victoria
	_show_victory_message()

func _show_victory_message():
	var victory_panel = Panel.new()
	victory_panel.size = Vector2(400, 150)
	victory_panel.position = Vector2(340, 250)
	
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
	style.border_color = Color(0.8, 0.6, 0.2)
	victory_panel.add_theme_stylebox_override("panel", style)
	add_child(victory_panel)
	
	var victory_label = Label.new()
	victory_label.text = "¡VICTORIA!"
	victory_label.position = Vector2(100, 30)
	victory_label.size = Vector2(200, 50)
	victory_label.add_theme_font_size_override("font_size", 32)
	victory_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_panel.add_child(victory_label)
	
	var message_label = Label.new()
	message_label.text = "Has derrotado al villano!"
	message_label.position = Vector2(50, 80)
	message_label.size = Vector2(300, 30)
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_panel.add_child(message_label)
	
	# Esperar que termine la música de victoria (o 3 segundos máximo)
	var wait_time = 3.0
	if victory_music:
		wait_time = max(victory_music.get_length(), 2.0)
	
	await get_tree().create_timer(wait_time).timeout
	victory_panel.queue_free()
	
	# Cambiar a pantalla de resultados
	if GameManager and GameManager.game_mode == 1:
		get_tree().change_scene_to_file("res://scenes/menu/result_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/result_screen_2p.tscn")
