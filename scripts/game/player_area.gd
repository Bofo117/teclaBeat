extends Node2D

# Variables exportadas (ahora solo el ID es necesario)
@export var player_id: int = 1  # 1 o 2

# Variables internas (se encontrarán automáticamente)
var key_listener: Node2D
var score_label: Label
var combo_label: Label

# Variables de puntuación
var score: int = 0
var combo_count: int = 0
var best_combo: int = 0

func _ready():
	# Buscar los nodos automáticamente
	find_child_nodes()
	setup_player()
	connect_signals()

func find_child_nodes():
	# Buscar KeyListener (hijo directo o en cualquier lugar)
	for child in get_children():
		if child.name == "KeyListener":
			key_listener = child
			break
	
	# Buscar UI y sus labels
	var ui_node = $UI if has_node("UI") else null
	if ui_node:
		score_label = ui_node.get_node("ScoreLabel") if ui_node.has_node("ScoreLabel") else null
		combo_label = ui_node.get_node("ComboLabel") if ui_node.has_node("ComboLabel") else null
	
	# Crear labels si no existen
	if not score_label:
		score_label = create_label("SCORE: 0", Vector2(10, 10), 20)
	if not combo_label:
		combo_label = create_label("COMBO: 0", Vector2(10, 40), 18)

func create_label(text: String, position: Vector2, font_size: int) -> Label:
	var label = Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	
	# Asegurar que existe UI
	var ui_node = $UI if has_node("UI") else null
	if not ui_node:
		ui_node = Control.new()
		ui_node.name = "UI"
		add_child(ui_node)
	
	ui_node.add_child(label)
	return label

func setup_player():
	if player_id == 1:
		# Configurar teclas para Jugador 1: Q, W, E, R
		if key_listener and key_listener.has_method("set_key_name"):
			key_listener.set_key_name("button_Q")
		if score_label:
			score_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))  # Naranja
	else:
		# Configurar teclas para Jugador 2: Flechas
		if key_listener and key_listener.has_method("set_key_name"):
			key_listener.set_key_name("ui_left")
		if score_label:
			score_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # Verde

func connect_signals():
	var prefix = "Player" + str(player_id) + "_"
	
	if not Signals:
		print("ERROR: Signals no encontrado")
		return
	
	Signals.connect(prefix + "add_score", _on_add_score)
	Signals.connect(prefix + "increment_combo", _on_increment_combo)
	Signals.connect(prefix + "reset_combo", _on_reset_combo)

func _on_add_score(incr: int):
	score += incr
	if score_label:
		score_label.text = "SCORE: " + str(score)
	print("Jugador ", player_id, " Score: ", score)

func _on_increment_combo():
	combo_count += 1
	if combo_count > best_combo:
		best_combo = combo_count
	if combo_label:
		combo_label.text = "COMBO: " + str(combo_count) + "x"
	print("Jugador ", player_id, " Combo: ", combo_count)

func _on_reset_combo():
	combo_count = 0
	if combo_label:
		combo_label.text = "COMBO: 0"
	print("Jugador ", player_id, " Combo reset")

func get_game_data() -> Dictionary:
	return {
		"score": score,
		"best_combo": best_combo,
		"player_id": player_id
	}
