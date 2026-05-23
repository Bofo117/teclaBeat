extends Control

const API_URL = "https://rhythm-cps0.onrender.com/api"

var back_button: Button
var title_label: Label
var scroll_container: ScrollContainer
var games_container: VBoxContainer
var loading_label: Label
var difficulty_filter: OptionButton
var stats_panel: Panel
var games_panel: Panel
var stats_grid: GridContainer

var current_difficulty: String = "all"
var current_username: String = ""
var all_games: Array = []

func _ready():
	current_username = GameManager.current_user if GameManager else ""
	create_ui()
	load_user_games()

func create_ui():
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Titulo
	title_label = Label.new()
	title_label.text = "MIS PARTIDAS"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	
	# Boton volver
	back_button = Button.new()
	back_button.text = "VOLVER"
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.pressed.connect(_on_back_pressed)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.2, 0.5)
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.8, 0.6, 0.2)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	back_button.add_theme_stylebox_override("normal", btn_style)
	add_child(back_button)
	
	# Filtro
	var filter_label = Label.new()
	filter_label.text = "DIFICULTAD:"
	filter_label.add_theme_font_size_override("font_size", 14)
	filter_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(filter_label)
	
	difficulty_filter = OptionButton.new()
	difficulty_filter.add_item("TODAS", 0)
	difficulty_filter.add_item("FÁCIL", 1)
	difficulty_filter.add_item("MEDIO", 2)
	difficulty_filter.add_item("DIFÍCIL", 3)
	difficulty_filter.add_item("IMPOSIBLE", 4)
	difficulty_filter.add_theme_font_size_override("font_size", 14)
	difficulty_filter.item_selected.connect(_on_filter_changed)
	add_child(difficulty_filter)
	
	# Panel de estadisticas - MAS GRANDE
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.18, 0.95)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.8, 0.6, 0.2)
	
	stats_panel = Panel.new()
	stats_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(stats_panel)
	
	# Titulo panel estadisticas
	var stats_title = Label.new()
	stats_title.text = "ESTADISTICAS GENERALES"
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(stats_title)
	
	# Grid de estadisticas
	stats_grid = GridContainer.new()
	stats_grid.columns = 6
	stats_panel.add_child(stats_grid)
	
	# Panel de lista de partidas - MAS LARGO HACIA ABAJO
	games_panel = Panel.new()
	games_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(games_panel)
	
	# Titulo panel partidas
	var games_title = Label.new()
	games_title.text = "HISTORIAL DE PARTIDAS"
	games_title.add_theme_font_size_override("font_size", 16)
	games_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	games_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	games_panel.add_child(games_title)
	
	# Scroll container
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	games_panel.add_child(scroll_container)
	
	games_container = VBoxContainer.new()
	games_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(games_container)
	
	# Loading label
	loading_label = Label.new()
	loading_label.text = "CARGANDO..."
	loading_label.add_theme_font_size_override("font_size", 20)
	loading_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(loading_label)
	
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	
	title_label.position = Vector2((screen_size.x - 300) / 2, 20)
	title_label.size = Vector2(300, 50)
	
	back_button.position = Vector2(20, 25)
	back_button.size = Vector2(100, 40)
	
	filter_label.position = Vector2(screen_size.x - 200, 30)
	filter_label.size = Vector2(90, 25)
	
	difficulty_filter.position = Vector2(screen_size.x - 105, 25)
	difficulty_filter.size = Vector2(95, 35)
	
	# Panel de estadisticas
	stats_panel.position = Vector2(50, 90)
	stats_panel.size = Vector2(screen_size.x - 100, 160)
	
	stats_title.position = Vector2((stats_panel.size.x - 250) / 2, 8)
	stats_title.size = Vector2(250, 25)
	
	# Grid centrado - mover contenido mas hacia la derecha
	stats_grid.position = Vector2(30, 45)
	stats_grid.size = Vector2(stats_panel.size.x - 60, 100)
	
	# Panel de partidas - MAS LARGO
	games_panel.position = Vector2(50, 270)
	games_panel.size = Vector2(screen_size.x - 100, screen_size.y - 340)
	
	games_title.position = Vector2((games_panel.size.x - 250) / 2, 8)
	games_title.size = Vector2(250, 25)
	
	scroll_container.position = Vector2(10, 45)
	scroll_container.size = Vector2(games_panel.size.x - 20, games_panel.size.y - 55)
	
	loading_label.position = Vector2((screen_size.x - 200) / 2, (screen_size.y - 30) / 2)
	loading_label.size = Vector2(200, 30)

func load_user_games():
	loading_label.visible = true
	stats_panel.visible = false
	games_panel.visible = false
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/user_games/" + current_username)
	http.request_completed.connect(_on_games_received.bind(http))

func _on_games_received(result, code, headers, body, http):
	loading_label.visible = false
	http.queue_free()
	
	if code == 200:
		all_games = JSON.parse_string(body.get_string_from_utf8())
		
		print("=== PARTIDAS CARGADAS ===")
		for game in all_games:
			var diff = game.get("difficulty", "NO TIENE")
			print("Dificultad almacenada: '", diff, "'")
		
		display_stats(all_games)
		apply_filter()
		stats_panel.visible = true
		games_panel.visible = true
	else:
		show_error("Error al cargar datos")

func display_stats(games: Array):
	for child in stats_grid.get_children():
		child.queue_free()
	
	if games.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No hay datos"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_grid.add_child(empty_label)
		return
	
	var total_games = games.size()
	var victories = 0
	var defeats = 0
	var best_combo = 0
	var total_time = 0.0
	var total_perfect = 0
	var total_great = 0
	var total_good = 0
	var total_ok = 0
	var total_miss = 0
	
	for game in games:
		if game.get("victory", false):
			victories += 1
		else:
			defeats += 1
		
		var combo = game.get("combo", 0)
		if combo > best_combo:
			best_combo = combo
		
		total_time += game.get("time", 0.0)
		total_perfect += game.get("perfect", 0)
		total_great += game.get("great", 0)
		total_good += game.get("good", 0)
		total_ok += game.get("ok", 0)
		total_miss += game.get("miss", 0)
	
	var win_rate = (victories * 100.0) / total_games if total_games > 0 else 0
	var avg_time = total_time / total_games if total_games > 0 else 0
	var total_hits = total_perfect + total_great + total_good + total_ok
	var accuracy = (total_hits * 100.0) / (total_hits + total_miss) if total_hits + total_miss > 0 else 0
	
	# Fila 1
	add_stat_card(stats_grid, "TOTAL", str(total_games))
	add_stat_card(stats_grid, "VICTORIAS", str(victories) + " (" + str(int(win_rate)) + "%)")
	add_stat_card(stats_grid, "DERROTAS", str(defeats))
	add_stat_card(stats_grid, "MEJOR COMBO", "x" + str(best_combo))
	add_stat_card(stats_grid, "TIEMPO PROM.", format_time(avg_time))
	add_stat_card(stats_grid, "PRECISION", str(int(accuracy)) + "%")
	
	# Fila 2
	add_stat_card(stats_grid, "PERFECT", str(total_perfect))
	add_stat_card(stats_grid, "GREAT", str(total_great))
	add_stat_card(stats_grid, "GOOD", str(total_good))
	add_stat_card(stats_grid, "OK", str(total_ok))
	add_stat_card(stats_grid, "MISS", str(total_miss))
	add_stat_card(stats_grid, "TOTAL HITS", str(total_hits))

func add_stat_card(grid: GridContainer, label_text: String, value_text: String):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(145, 55)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.08, 0.15)
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.corner_radius_bottom_right = 6
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.8, 0.6, 0.2, 0.5)
	card.add_theme_stylebox_override("panel", card_style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(vbox)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value)
	
	grid.add_child(card)

func apply_filter():
	var filtered = []
	
	print("=== APLICANDO FILTRO ===")
	print("Filtro seleccionado: ", current_difficulty)
	
	if current_difficulty == "all":
		filtered = all_games
		print("Mostrando todas las partidas: ", filtered.size())
	else:
		# Comparacion directa con el valor almacenado
		for game in all_games:
			var game_diff = game.get("difficulty", "")
			print("Comparando: '", game_diff, "' con filtro: '", current_difficulty, "'")
			
			# Normalizar ambos para comparar (quitar acentos)
			var game_diff_norm = game_diff.to_upper().replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")
			var filter_norm = current_difficulty.to_upper().replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")
			
			if game_diff_norm == filter_norm:
				filtered.append(game)
				print("  -> MATCH!")
		
		print("Partidas con dificultad ", current_difficulty, ": ", filtered.size())
	
	display_games(filtered)

func get_difficulty_display(difficulty: String) -> String:
	var diff_upper = difficulty.to_upper().replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")
	if diff_upper == "FACIL":
		return "FÁCIL"
	elif diff_upper == "MEDIO":
		return "MEDIO"
	elif diff_upper == "DIFICIL":
		return "DIFÍCIL"
	elif diff_upper == "IMPOSIBLE":
		return "IMPOSIBLE"
	return difficulty

func display_games(games: Array):
	for child in games_container.get_children():
		child.queue_free()
	
	if games.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No hay partidas para esta dificultad"
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		games_container.add_child(empty_label)
		return
	
	# Cabecera
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.2, 0.2, 0.35)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header.add_theme_stylebox_override("panel", header_style)
	
	var widths = [45, 80, 70, 70, 95, 55, 55, 55, 95]
	var headers = ["#", "RESULTADO", "COMBO", "TIEMPO", "DIFICULTAD", "PERF", "GREAT", "GOOD", "FECHA"]
	
	for i in range(headers.size()):
		var label = Label.new()
		label.text = headers[i]
		label.custom_minimum_size.x = widths[i]
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(label)
	
	games_container.add_child(header)
	games_container.add_child(HSeparator.new())
	
	# Ordenar por fecha descendente
	var sorted = games.duplicate()
	for i in range(sorted.size()):
		for j in range(i + 1, sorted.size()):
			var date_a = sorted[i].get("date", "")
			var date_b = sorted[j].get("date", "")
			if date_a < date_b:
				var temp = sorted[i]
				sorted[i] = sorted[j]
				sorted[j] = temp
	
	for i in range(sorted.size()):
		var game = sorted[i]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var row_style = StyleBoxFlat.new()
		if i % 2 == 0:
			row_style.bg_color = Color(0.12, 0.12, 0.22)
		else:
			row_style.bg_color = Color(0.08, 0.08, 0.18)
		
		# Borde izquierdo coloreado
		row_style.border_width_left = 4
		if game.get("victory", false):
			row_style.border_color = Color(0.2, 0.8, 0.2)
		else:
			row_style.border_color = Color(0.9, 0.2, 0.2)
		
		row.add_theme_stylebox_override("panel", row_style)
		
		# Numero
		var num_label = Label.new()
		num_label.text = str(i + 1)
		num_label.custom_minimum_size.x = widths[0]
		num_label.add_theme_font_size_override("font_size", 12)
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(num_label)
		
		# Resultado
		var result_label = Label.new()
		if game.get("victory", false):
			result_label.text = "VICTORIA"
			result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		else:
			result_label.text = "DERROTA"
			result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		result_label.custom_minimum_size.x = widths[1]
		result_label.add_theme_font_size_override("font_size", 10)
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(result_label)
		
		# Combo
		var combo_label = Label.new()
		combo_label.text = "x" + str(game.get("combo", 0))
		combo_label.custom_minimum_size.x = widths[2]
		combo_label.add_theme_font_size_override("font_size", 12)
		combo_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.4))
		combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(combo_label)
		
		# Tiempo
		var time_label = Label.new()
		time_label.text = format_time(game.get("time", 0.0))
		time_label.custom_minimum_size.x = widths[3]
		time_label.add_theme_font_size_override("font_size", 11)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(time_label)
		
		# Dificultad
		var diff_label = Label.new()
		diff_label.text = get_difficulty_display(game.get("difficulty", "MEDIO"))
		diff_label.custom_minimum_size.x = widths[4]
		diff_label.add_theme_font_size_override("font_size", 11)
		diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(diff_label)
		
		# Perfect
		var perfect_label = Label.new()
		perfect_label.text = str(game.get("perfect", 0))
		perfect_label.custom_minimum_size.x = widths[5]
		perfect_label.add_theme_font_size_override("font_size", 11)
		perfect_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(perfect_label)
		
		# Great
		var great_label = Label.new()
		great_label.text = str(game.get("great", 0))
		great_label.custom_minimum_size.x = widths[6]
		great_label.add_theme_font_size_override("font_size", 11)
		great_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		great_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(great_label)
		
		# Good
		var good_label = Label.new()
		good_label.text = str(game.get("good", 0))
		good_label.custom_minimum_size.x = widths[7]
		good_label.add_theme_font_size_override("font_size", 11)
		good_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
		good_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(good_label)
		
		# Fecha
		var date_label = Label.new()
		var date_str = game.get("date", "")
		if date_str.length() >= 10:
			date_label.text = date_str.substr(0, 10)
		else:
			date_label.text = date_str
		date_label.custom_minimum_size.x = widths[8]
		date_label.add_theme_font_size_override("font_size", 10)
		date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(date_label)
		
		games_container.add_child(row)
		if i < sorted.size() - 1:
			games_container.add_child(HSeparator.new())

func format_time(seconds: float) -> String:
	var minutes = floor(seconds / 60)
	var secs = int(seconds) % 60
	return str(minutes).lpad(2, "0") + ":" + str(secs).lpad(2, "0")

func show_error(msg: String):
	for child in games_container.get_children():
		child.queue_free()
	
	var error_label = Label.new()
	error_label.text = msg
	error_label.add_theme_font_size_override("font_size", 18)
	error_label.add_theme_color_override("font_color", Color.RED)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	games_container.add_child(error_label)
	
	stats_panel.visible = true
	games_panel.visible = true

func _on_filter_changed(index: int):
	match index:
		0: current_difficulty = "all"
		1: current_difficulty = "FÁCIL"
		2: current_difficulty = "MEDIO"
		3: current_difficulty = "DIFÍCIL"
		4: current_difficulty = "IMPOSIBLE"
	
	print("=== FILTRO CAMBIADO ===")
	print("Nuevo filtro: ", current_difficulty)
	apply_filter()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
