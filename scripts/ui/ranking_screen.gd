extends Control

const API_URL = "https://rhythm-cps0.onrender.com/api"

var back_button: Button
var title_label: Label
var scroll_container: ScrollContainer
var entries_container: VBoxContainer
var loading_label: Label
var difficulty_filter: OptionButton
var status_label: Label

var current_difficulty: String = "all"
var all_entries: Array = []

func _ready():
	create_ui()
	load_ranking()

func create_ui():
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	title_label = Label.new()
	title_label.text = "RANKING GLOBAL"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	
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
	
	var panel = Panel.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.18, 0.95)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.8, 0.6, 0.2)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(status_label)
	
	loading_label = Label.new()
	loading_label.text = "CARGANDO..."
	loading_label.add_theme_font_size_override("font_size", 20)
	loading_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(loading_label)
	
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll_container)
	
	entries_container = VBoxContainer.new()
	entries_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(entries_container)
	
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
	
	panel.position = Vector2(50, 90)
	panel.size = Vector2(screen_size.x - 100, screen_size.y - 110)
	
	loading_label.position = Vector2((panel.size.x - 200) / 2, (panel.size.y - 30) / 2)
	loading_label.size = Vector2(200, 30)
	
	status_label.position = Vector2(10, panel.size.y - 30)
	status_label.size = Vector2(panel.size.x - 20, 25)
	
	scroll_container.position = Vector2(10, 10)
	scroll_container.size = Vector2(panel.size.x - 20, panel.size.y - 50)

func load_ranking():
	loading_label.visible = true
	scroll_container.visible = false
	status_label.visible = false
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/global_leaderboard")
	http.request_completed.connect(_on_ranking_received.bind(http))

func _on_ranking_received(result, code, headers, body, http):
	loading_label.visible = false
	http.queue_free()
	
	if code == 200:
		all_entries = JSON.parse_string(body.get_string_from_utf8())
		
		print("=== RANKING CARGADO ===")
		print("Total entradas: ", all_entries.size())
		
		# Mostrar primera entrada para debug
		if all_entries.size() > 0:
			print("Primera entrada: ", all_entries[0])
		
		apply_filter()
	else:
		show_error("Error al cargar datos")

func apply_filter():
	var filtered = []
	
	print("=== APLICANDO FILTRO ===")
	print("Filtro seleccionado: ", current_difficulty)
	
	if current_difficulty == "all":
		# Filtrar solo victorias
		for e in all_entries:
			if e.get("victory", false) == true:
				filtered.append(e)
		print("Mostrando todas las dificultades (solo victorias): ", filtered.size())
	else:
		var filter_norm = current_difficulty.to_upper().replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")
		
		for e in all_entries:
			var diff = e.get("difficulty", "")
			var diff_norm = diff.to_upper().replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")
			var is_victory = e.get("victory", false)
			
			if diff_norm == filter_norm and is_victory == true:
				filtered.append(e)
		
		print("Partidas con dificultad ", current_difficulty, " (solo victorias): ", filtered.size())
	
	# Ordenar: primero por tiempo (menor a mayor), luego por combo (mayor a menor)
	var sorted = filtered.duplicate()
	for i in range(sorted.size()):
		for j in range(i + 1, sorted.size()):
			var a = sorted[i]
			var b = sorted[j]
			
			var time_a = a.get("time", 999999)
			var time_b = b.get("time", 999999)
			
			if time_a > time_b:
				var temp = sorted[i]
				sorted[i] = sorted[j]
				sorted[j] = temp
			elif time_a == time_b:
				var combo_a = a.get("combo", 0)
				var combo_b = b.get("combo", 0)
				
				if combo_a < combo_b:
					var temp = sorted[i]
					sorted[i] = sorted[j]
					sorted[j] = temp
	
	display_ranking(sorted)

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

func format_time(seconds: float) -> String:
	var minutes = floor(seconds / 60)
	var secs = int(seconds) % 60
	return str(minutes).lpad(2, "0") + ":" + str(secs).lpad(2, "0")

func display_ranking(entries: Array):
	for child in entries_container.get_children():
		child.queue_free()
	
	if entries.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No hay victorias para esta dificultad"
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entries_container.add_child(empty_label)
		scroll_container.visible = true
		status_label.visible = true
		status_label.text = "Total: 0 registros"
		return
	
	# Cabecera con mas columnas
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.2, 0.2, 0.35)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header.add_theme_stylebox_override("panel", header_style)
	
	var widths = [45, 100, 70, 70, 85, 55, 55, 55, 55, 55, 90]
	var titles = ["#", "JUGADOR", "COMBO", "TIEMPO", "DIFICULTAD", "PERF", "GREAT", "GOOD", "OK", "MISS", "FECHA"]
	
	for i in range(titles.size()):
		var label = Label.new()
		label.text = titles[i]
		label.custom_minimum_size.x = widths[i]
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(label)
	
	entries_container.add_child(header)
	entries_container.add_child(HSeparator.new())
	
	for i in range(entries.size()):
		var entry = entries[i]
		var row = create_entry(i + 1, entry)
		entries_container.add_child(row)
		if i < entries.size() - 1:
			entries_container.add_child(HSeparator.new())
	
	scroll_container.visible = true
	status_label.visible = true
	status_label.text = "Total: " + str(entries.size()) + " victorias"

func create_entry(rank: int, entry: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var row_style = StyleBoxFlat.new()
	if rank % 2 == 0:
		row_style.bg_color = Color(0.12, 0.12, 0.22)
	else:
		row_style.bg_color = Color(0.08, 0.08, 0.18)
	
	row_style.border_width_left = 4
	row_style.border_color = Color(0.8, 0.6, 0.2)
	row.add_theme_stylebox_override("panel", row_style)
	
	var widths = [45, 100, 70, 70, 85, 55, 55, 55, 55, 55, 90]
	
	var rank_color = Color.WHITE
	if rank == 1:
		rank_color = Color(1, 0.8, 0.2)
	elif rank == 2:
		rank_color = Color(0.8, 0.8, 0.9)
	elif rank == 3:
		rank_color = Color(0.8, 0.5, 0.2)
	
	# Rank
	var rank_label = Label.new()
	rank_label.text = str(rank)
	rank_label.custom_minimum_size.x = widths[0]
	rank_label.add_theme_font_size_override("font_size", 13)
	rank_label.add_theme_color_override("font_color", rank_color)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(rank_label)
	
	# Jugador
	var name_label = Label.new()
	name_label.text = entry.get("name", "???")
	name_label.custom_minimum_size.x = widths[1]
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	
	# Combo
	var combo_label = Label.new()
	combo_label.text = "x" + str(entry.get("combo", 0))
	combo_label.custom_minimum_size.x = widths[2]
	combo_label.add_theme_font_size_override("font_size", 12)
	combo_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.4))
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(combo_label)
	
	# Tiempo
	var time_label = Label.new()
	time_label.text = format_time(entry.get("time", 0.0))
	time_label.custom_minimum_size.x = widths[3]
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(time_label)
	
	# Dificultad
	var diff_label = Label.new()
	diff_label.text = get_difficulty_display(entry.get("difficulty", "MEDIO"))
	diff_label.custom_minimum_size.x = widths[4]
	diff_label.add_theme_font_size_override("font_size", 11)
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(diff_label)
	
	# Perfect
	var perfect_label = Label.new()
	perfect_label.text = str(entry.get("perfect", 0))
	perfect_label.custom_minimum_size.x = widths[5]
	perfect_label.add_theme_font_size_override("font_size", 11)
	perfect_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(perfect_label)
	
	# Great
	var great_label = Label.new()
	great_label.text = str(entry.get("great", 0))
	great_label.custom_minimum_size.x = widths[6]
	great_label.add_theme_font_size_override("font_size", 11)
	great_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	great_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(great_label)
	
	# Good
	var good_label = Label.new()
	good_label.text = str(entry.get("good", 0))
	good_label.custom_minimum_size.x = widths[7]
	good_label.add_theme_font_size_override("font_size", 11)
	good_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
	good_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(good_label)
	
	# OK
	var ok_label = Label.new()
	ok_label.text = str(entry.get("ok", 0))
	ok_label.custom_minimum_size.x = widths[8]
	ok_label.add_theme_font_size_override("font_size", 11)
	ok_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	ok_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(ok_label)
	
	# Miss
	var miss_label = Label.new()
	miss_label.text = str(entry.get("miss", 0))
	miss_label.custom_minimum_size.x = widths[9]
	miss_label.add_theme_font_size_override("font_size", 11)
	miss_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	miss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(miss_label)
	
	# Fecha
	var date_label = Label.new()
	var date_str = entry.get("date", "")
	if date_str.length() >= 10:
		date_label.text = date_str.substr(0, 10)
	else:
		date_label.text = date_str
	date_label.custom_minimum_size.x = widths[10]
	date_label.add_theme_font_size_override("font_size", 10)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(date_label)
	
	return row

func show_error(msg: String):
	for child in entries_container.get_children():
		child.queue_free()
	
	var error_label = Label.new()
	error_label.text = msg
	error_label.add_theme_font_size_override("font_size", 18)
	error_label.add_theme_color_override("font_color", Color.RED)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries_container.add_child(error_label)
	
	scroll_container.visible = true
	status_label.visible = true
	status_label.text = "Error"

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
