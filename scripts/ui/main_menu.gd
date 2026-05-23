# scripts/ui/main_menu.gd
extends Control

var btn_one_player: Button
var btn_two_players: Button
var btn_stats: Button
var btn_my_games: Button
var btn_exit: Button
var user_label: Label
var login_button: Button  # Nuevo botón

func _ready():
	print("=== MAIN MENU CARGADO ===")
	
	find_nodes()
	connect_buttons()
	update_user_display()

func find_nodes():
	var vbox = $VBoxContainer if has_node("VBoxContainer") else null
	
	if vbox:
		btn_one_player = vbox.get_node("OnePlayerButton") if vbox.has_node("OnePlayerButton") else null
		btn_two_players = vbox.get_node("TwoPlayersButton") if vbox.has_node("TwoPlayersButton") else null
		btn_stats = vbox.get_node("StatsButton") if vbox.has_node("StatsButton") else null
		btn_my_games = vbox.get_node("MyGamesButton") if vbox.has_node("MyGamesButton") else null
		btn_exit = vbox.get_node("ExitButton") if vbox.has_node("ExitButton") else null
	
	user_label = $UserLabel if has_node("UserLabel") else null
	
	# Buscar o crear botón de login
	login_button = $LoginButton if has_node("LoginButton") else null
	if not login_button:
		login_button = Button.new()
		login_button.name = "LoginButton"
		login_button.text = "INICIAR SESIÓN"
		login_button.position = Vector2(20, 20)
		login_button.size = Vector2(120, 35)
		add_child(login_button)

func connect_buttons():
	if btn_one_player: btn_one_player.pressed.connect(_on_one_player_pressed)
	if btn_two_players: btn_two_players.pressed.connect(_on_two_players_pressed)
	if btn_stats: btn_stats.pressed.connect(_on_stats_pressed)
	if btn_my_games: btn_my_games.pressed.connect(_on_my_games_pressed)
	if btn_exit: btn_exit.pressed.connect(_on_exit_pressed)
	if login_button: login_button.pressed.connect(_on_login_pressed)

func update_user_display():
	var is_logged_in = GameManager and GameManager.current_user and GameManager.current_user != "" and GameManager.current_user != "INVITADO"
	
	if is_logged_in:
		# Usuario logueado - mostrar nombre, ocultar botón login
		if user_label:
			user_label.text = "👤 " + GameManager.current_user
			user_label.visible = true
		if login_button:
			login_button.visible = false
	else:
		# No logueado - ocultar label, mostrar botón login
		if user_label:
			user_label.visible = false
		if login_button:
			login_button.visible = true

func _on_one_player_pressed():
	if GameManager:
		GameManager.set_game_mode(1)
		GameManager.reset_game_data()
	get_tree().change_scene_to_file("res://scenes/menu/difficulty_select.tscn")
	#get_tree().change_scene_to_file("res://scenes/menu/song_select.tscn")

func _on_two_players_pressed():
	if GameManager:
		GameManager.set_game_mode(2)
		GameManager.reset_game_data()
	#get_tree().change_scene_to_file("res://scenes/menu/song_select.tscn")
	get_tree().change_scene_to_file("res://scenes/menu/difficulty_select.tscn")

func _on_stats_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/ranking_screen.tscn")

func _on_my_games_pressed():
	if GameManager and GameManager.current_user and GameManager.current_user != "" and GameManager.current_user != "INVITADO":
		get_tree().change_scene_to_file("res://scenes/menu/my_games_screen.tscn")
	else:
		show_temp_message("Crea una cuenta o inicia sesión para ver tus partidas", Color.YELLOW)

func _on_login_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/login_screen.tscn")

func _on_exit_pressed():
	get_tree().quit()

func show_temp_message(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.position = Vector2(345, 500)
	add_child(label)
	await get_tree().create_timer(2.5).timeout
	label.queue_free()
