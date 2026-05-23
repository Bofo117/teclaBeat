extends Control

# Puntajes
var player1_score: int = 0
var player1_combo: int = 0
var player2_score: int = 0
var player2_combo: int = 0

# Referencias a labels
var player1_score_label: Label
var player1_combo_label: Label
var player2_score_label: Label
var player2_combo_label: Label

# Colores
var color_j1 = Color(1, 0.5, 0.2)      # Naranja
var color_j2 = Color(0.2, 0.8, 0.2)    # Verde
var color_combo = Color(1, 0.8, 0.2)   # Dorado

func _ready():
	print("=== INICIANDO GAME_UI_2P ===")
	create_ui()
	connect_signals()
	reset_all()
	
	# Asegurar que la UI esté por encima
	z_index = 100

func create_ui():
	# Obtener tamaño de pantalla
	var screen_size = get_viewport().get_visible_rect().size
	print("Tamaño de pantalla: ", screen_size)
	
	# ===== POSICIONES PERSONALIZADAS =====
	# J1: x=500, y=250
	# J2: x=500, y=250 (centro) - mejor los ponemos separados
	
	# Opción 1: Centrados pero separados horizontalmente
	var j1_x = -550   # Jugador 1 más a la izquierda
	var j2_x = 350  # Jugador 2 más a la derecha
	var y_pos = -300  # Altura fija
	
	# Panel fondo para J1
	var panel_j1 = Panel.new()
	panel_j1.position = Vector2(j1_x, y_pos)
	panel_j1.size = Vector2(200, 80)
	panel_j1.add_theme_stylebox_override("panel", create_panel_style(Color(0, 0, 0, 0.8)))
	add_child(panel_j1)
	print("Panel J1 creado en posición: (", j1_x, ", ", y_pos, ")")
	
	# Panel fondo para J2
	var panel_j2 = Panel.new()
	panel_j2.position = Vector2(j2_x, y_pos)
	panel_j2.size = Vector2(200, 80)
	panel_j2.add_theme_stylebox_override("panel", create_panel_style(Color(0, 0, 0, 0.8)))
	add_child(panel_j2)
	print("Panel J2 creado en posición: (", j2_x, ", ", y_pos, ")")
	
	# ===== JUGADOR 1 =====
	# Título
	var title_j1 = create_label(
		"JUGADOR 1",
		j1_x + 10, y_pos + 5,
		14,
		color_j1
	)
	add_child(title_j1)
	
	# Score
	player1_score_label = create_label(
		"0 pts",
		j1_x + 10, y_pos + 25,
		20,
		color_j1
	)
	add_child(player1_score_label)
	
	# Combo
	player1_combo_label = create_label(
		"x0",
		j1_x + 10, y_pos + 50,
		18,
		color_combo
	)
	add_child(player1_combo_label)
	
	# ===== JUGADOR 2 =====
	# Título
	var title_j2 = create_label(
		"JUGADOR 2",
		j2_x + 10, y_pos + 5,
		14,
		color_j2
	)
	add_child(title_j2)
	
	# Score
	player2_score_label = create_label(
		"0 pts",
		j2_x + 10, y_pos + 25,
		20,
		color_j2
	)
	add_child(player2_score_label)
	
	# Combo
	player2_combo_label = create_label(
		"x0",
		j2_x + 10, y_pos + 50,
		18,
		color_combo
	)
	add_child(player2_combo_label)
	
	print("UI creada - J1 en (", j1_x, ", ", y_pos, ") - J2 en (", j2_x, ", ", y_pos, ")")

func create_panel_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.8, 0.6, 0.2)
	return style

func create_label(text: String, x: float, y: float, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.position = Vector2(x, y)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func connect_signals():
	print("Conectando señales...")
	
	if not Signals:
		print("ERROR: Signals no encontrado")
		return
	
	Signals.Player1_add_score.connect(_on_player1_add_score)
	Signals.Player1_increment_combo.connect(_on_player1_increment_combo)
	Signals.Player1_reset_combo.connect(_on_player1_reset_combo)
	
	Signals.Player2_add_score.connect(_on_player2_add_score)
	Signals.Player2_increment_combo.connect(_on_player2_increment_combo)
	Signals.Player2_reset_combo.connect(_on_player2_reset_combo)
	
	print("Todas las señales conectadas")

func reset_all():
	player1_score = 0
	player1_combo = 0
	player2_score = 0
	player2_combo = 0
	
	# ACTUALIZAR GAMEMANAGER
	if GameManager:
		GameManager.current_scores.player1 = 0
		GameManager.current_scores.player2 = 0
		GameManager.best_combo_player1 = 0
		GameManager.best_combo_player2 = 0
	
	update_ui()
	print("UI reiniciada")

func update_ui():
	if player1_score_label:
		player1_score_label.text = str(player1_score) + " pts"
	if player1_combo_label:
		player1_combo_label.text = "x" + str(player1_combo)
	if player2_score_label:
		player2_score_label.text = str(player2_score) + " pts"
	if player2_combo_label:
		player2_combo_label.text = "x" + str(player2_combo)
	
	# Efecto visual combo alto
	if player1_combo >= 10 and player1_combo_label:
		player1_combo_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	elif player1_combo_label:
		player1_combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	
	if player2_combo >= 10 and player2_combo_label:
		player2_combo_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	elif player2_combo_label:
		player2_combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))

# ===== JUGADOR 1 =====
# ===== JUGADOR 1 =====
func _on_player1_add_score(incr: int):
	player1_score += incr
	# ACTUALIZAR GAMEMANAGER
	if GameManager:
		GameManager.current_scores.player1 = player1_score
	update_ui()
	print("J1 +", incr, " (Total: ", player1_score, ")")

func _on_player1_increment_combo():
	player1_combo += 1
	# ACTUALIZAR GAMEMANAGER
	if GameManager:
		GameManager.update_best_combo_player(1, player1_combo)
	update_ui()
	print("J1 Combo: x", player1_combo)

func _on_player1_reset_combo():
	player1_combo = 0
	update_ui()
	print("J1 Combo reset")

# ===== JUGADOR 2 =====
func _on_player2_add_score(incr: int):
	player2_score += incr
	# ACTUALIZAR GAMEMANAGER
	if GameManager:
		GameManager.current_scores.player2 = player2_score
	update_ui()
	print("J2 +", incr, " (Total: ", player2_score, ")")

func _on_player2_increment_combo():
	player2_combo += 1
	# ACTUALIZAR GAMEMANAGER
	if GameManager:
		GameManager.update_best_combo_player(2, player2_combo)
	update_ui()
	print("J2 Combo: x", player2_combo)

func _on_player2_reset_combo():
	player2_combo = 0
	update_ui()
	print("J2 Combo reset")
