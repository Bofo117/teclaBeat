extends Panel

@onready var start_button = $StartButton
@onready var close_button = $CloseButton
@onready var title = $Title

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	setup_styles()
	setup_ui()

func setup_styles():
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.8, 0.6, 0.2)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	add_theme_stylebox_override("panel", panel_style)
	
	if title:
		title.add_theme_font_size_override("font_size", 28)
		title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.2, 0.5)
	button_style.border_width_left = 1
	button_style.border_width_right = 1
	button_style.border_width_top = 1
	button_style.border_width_bottom = 1
	button_style.border_color = Color(0.8, 0.6, 0.2)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	
	if start_button:
		start_button.add_theme_stylebox_override("normal", button_style)
		start_button.add_theme_font_size_override("font_size", 20)
	
	if close_button:
		close_button.add_theme_stylebox_override("normal", button_style)
		close_button.add_theme_font_size_override("font_size", 16)
	
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.5, 0.3, 0.7)
	
	if start_button:
		start_button.add_theme_stylebox_override("hover", hover_style)
	if close_button:
		close_button.add_theme_stylebox_override("hover", hover_style)

func setup_ui():
	# Tamaño del panel
	size = Vector2(700, 450)
	
	# Centrar panel en la pantalla
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	position = Vector2(
		(screen_size.x - size.x) / 2,
		(screen_size.y - size.y) / 2
	)
	
	# ===== TÍTULO PRINCIPAL CENTRADO =====
	if title:
		# Ancho del panel es 700, título tiene 500 de ancho
		# (700 - 500) / 2 = 100
		title.position = Vector2(100, 20)
		title.size = Vector2(500, 40)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Botón cerrar (esquina superior derecha)
	if close_button:
		close_button.position = Vector2(660, 10)
		close_button.size = Vector2(30, 30)
		close_button.text = "X"
	
	if GameManager and GameManager.game_mode == 1:
		# ===== MODO 1 JUGADOR =====
		if title:
			title.text = "TECLAS - MODO 1 JUGADOR"
		
		var player2_container = get_node_or_null("Player2Container")
		var v_separator = get_node_or_null("VSeparator")
		var player1_container = get_node_or_null("Player1Container")
		
		if player2_container:
			player2_container.visible = false
		if v_separator:
			v_separator.visible = false
		if player1_container:
			player1_container.position = Vector2(150, 80)
			player1_container.size = Vector2(400, 220)
			player1_container.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if start_button:
			start_button.position = Vector2(250, 340)
			start_button.size = Vector2(200, 50)
			start_button.text = "COMENZAR JUEGO"
		
		# Textos J1
		var player1_title = get_node_or_null("Player1Container/Player1Title")
		if player1_title:
			player1_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			player1_title.add_theme_font_size_override("font_size", 20)
		
		var keys1 = get_node_or_null("Player1Container/Keys1")
		if keys1:
			keys1.text = "Q    W    E    R"
			keys1.add_theme_font_size_override("font_size", 32)
			keys1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var desc1 = get_node_or_null("Player1Container/Description1")
		if desc1:
			desc1.text = "Izquierda / Abajo / Arriba / Derecha"
			desc1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc1.add_theme_font_size_override("font_size", 14)
	
	else:
		# ===== MODO 2 JUGADORES =====
		if title:
			title.text = "TECLAS - MODO 2 JUGADORES"
		
		# Ocultar separador
		var v_separator = get_node_or_null("VSeparator")
		if v_separator:
			v_separator.visible = false
		
		var player1_container = get_node_or_null("Player1Container")
		var player2_container = get_node_or_null("Player2Container")
		
		# Centrar contenedores
		if player1_container:
			player1_container.position = Vector2(30, 80)
			player1_container.size = Vector2(300, 220)
			player1_container.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if player2_container:
			player2_container.position = Vector2(370, 80)
			player2_container.size = Vector2(300, 220)
			player2_container.alignment = HORIZONTAL_ALIGNMENT_CENTER
			player2_container.visible = true
		
		if start_button:
			start_button.position = Vector2(250, 340)
			start_button.size = Vector2(200, 50)
			start_button.text = "COMENZAR JUEGO"
		
		# ===== JUGADOR 1 =====
		var player1_title = get_node_or_null("Player1Container/Player1Title")
		if player1_title:
			player1_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			player1_title.add_theme_font_size_override("font_size", 20)
		
		var keys1 = get_node_or_null("Player1Container/Keys1")
		if keys1:
			keys1.text = "Q    W    E    R"
			keys1.add_theme_font_size_override("font_size", 32)
			keys1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var desc1 = get_node_or_null("Player1Container/Description1")
		if desc1:
			desc1.text = "Izquierda / Abajo / Arriba / Derecha"
			desc1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc1.add_theme_font_size_override("font_size", 14)
		
		# ===== JUGADOR 2 =====
		var player2_title = get_node_or_null("Player2Container/Player2Title")
		if player2_title:
			player2_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			player2_title.add_theme_font_size_override("font_size", 20)
		
		var keys2 = get_node_or_null("Player2Container/Keys2")
		if keys2:
			keys2.text = "←    ↓    →    ↑"
			keys2.add_theme_font_size_override("font_size", 32)
			keys2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var desc2 = get_node_or_null("Player2Container/Description2")
		if desc2:
			desc2.text = "Flechas direccionales"
			desc2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc2.add_theme_font_size_override("font_size", 14)

func _on_start_pressed():
	print("Botón COMENZAR presionado")
	
	if start_button:
		start_button.disabled = true
		start_button.text = "CARGANDO..."
	
	var loading_label = Label.new()
	loading_label.text = "CARGANDO JUEGO..."
	loading_label.add_theme_font_size_override("font_size", 20)
	loading_label.add_theme_color_override("font_color", Color.YELLOW)
	loading_label.position = Vector2(280, 400)
	loading_label.size = Vector2(140, 30)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(loading_label)
	
	await get_tree().create_timer(0.5).timeout
	loading_label.queue_free()
	
	var level_path = ""
	if GameManager and GameManager.game_mode == 1:
		level_path = "res://levels/game_level.tscn"
	else:
		level_path = "res://levels/game_level_2j.tscn"
	
	print("Cargando nivel: ", level_path)
	var result = get_tree().change_scene_to_file(level_path)
	if result != OK:
		print("ERROR: No se pudo cargar la escena: ", level_path)
		if start_button:
			start_button.disabled = false
			start_button.text = "COMENZAR JUEGO"

func _on_close_pressed():
	print("Volviendo al selector de canciones")
	get_tree().change_scene_to_file("res://scenes/menu/song_select.tscn")
