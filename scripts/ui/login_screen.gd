# scripts/ui/login_screen.gd
extends Control

const API_URL = "https://rhythm-cps0.onrender.com/api"

var username_input: LineEdit
var password_input: LineEdit
var login_button: Button
var register_button: Button
var guest_button: Button
var error_label: Label
var loading_label: Label
var title_label: Label
var panel: Panel

func _ready():
	print("=== PANTALLA DE LOGIN CARGADA ===")
	create_ui()
	center_elements()

func create_ui():
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.size = get_viewport().get_visible_rect().size
	add_child(bg)
	
	# Título principal
	title_label = Label.new()
	title_label.text = "RHYTHM GAME"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	
	# Panel de login
	panel = Panel.new()
	panel.size = Vector2(400, 380)
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
	
	# Título del panel
	var panel_title = Label.new()
	panel_title.text = "INICIAR SESIÓN"
	panel_title.position = Vector2((400 - 200) / 2, 20)
	panel_title.size = Vector2(200, 30)
	panel_title.add_theme_font_size_override("font_size", 20)
	panel_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(panel_title)
	
	# Campo Usuario
	var user_label = Label.new()
	user_label.text = "USUARIO:"
	user_label.position = Vector2(30, 80)
	user_label.size = Vector2(100, 25)
	user_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(user_label)
	
	username_input = LineEdit.new()
	username_input.position = Vector2(130, 75)
	username_input.size = Vector2(240, 35)
	username_input.placeholder_text = "Mínimo 3 caracteres"
	username_input.add_theme_font_size_override("font_size", 14)
	panel.add_child(username_input)
	
	# Campo Contraseña
	var pass_label = Label.new()
	pass_label.text = "CONTRASEÑA:"
	pass_label.position = Vector2(30, 130)
	pass_label.size = Vector2(100, 25)
	pass_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(pass_label)
	
	password_input = LineEdit.new()
	password_input.position = Vector2(130, 125)
	password_input.size = Vector2(240, 35)
	password_input.secret = true
	password_input.placeholder_text = "Mínimo 3 caracteres"
	password_input.add_theme_font_size_override("font_size", 14)
	panel.add_child(password_input)
	
	# Botón Login
	login_button = Button.new()
	login_button.text = "INICIAR SESIÓN"
	login_button.position = Vector2(50, 190)
	login_button.size = Vector2(140, 45)
	login_button.add_theme_font_size_override("font_size", 14)
	login_button.pressed.connect(_on_login_pressed)
	panel.add_child(login_button)
	
	# Botón Registro
	register_button = Button.new()
	register_button.text = "REGISTRARSE"
	register_button.position = Vector2(210, 190)
	register_button.size = Vector2(140, 45)
	register_button.add_theme_font_size_override("font_size", 14)
	register_button.pressed.connect(_on_register_pressed)
	panel.add_child(register_button)
	
	# Botón Invitado
	guest_button = Button.new()
	guest_button.text = "JUGAR COMO INVITADO"
	guest_button.position = Vector2(100, 255)
	guest_button.size = Vector2(200, 40)
	guest_button.add_theme_font_size_override("font_size", 14)
	guest_button.pressed.connect(_on_guest_pressed)
	panel.add_child(guest_button)
	
	# Label de error/mensaje
	error_label = Label.new()
	error_label.position = Vector2(50, 320)
	error_label.size = Vector2(300, 50)
	error_label.add_theme_font_size_override("font_size", 12)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(error_label)
	
	# Loading label
	loading_label = Label.new()
	loading_label.text = "PROCESANDO..."
	loading_label.add_theme_font_size_override("font_size", 24)
	loading_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.visible = false
	add_child(loading_label)

func center_elements():
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	
	if title_label:
		title_label.position = Vector2((screen_size.x - 400) / 2, 60)
		title_label.size = Vector2(400, 60)
	
	if panel:
		panel.position = Vector2((screen_size.x - 400) / 2, 150)
	
	if loading_label:
		loading_label.position = Vector2((screen_size.x - 300) / 2, (screen_size.y - 30) / 2)
		loading_label.size = Vector2(300, 30)

func show_loading(show: bool, text: String = "PROCESANDO..."):
	if loading_label:
		loading_label.text = text
		loading_label.visible = show
	
	if login_button:
		login_button.disabled = show
	if register_button:
		register_button.disabled = show
	if guest_button:
		guest_button.disabled = show

func _on_login_pressed():
	var username = username_input.text.strip_edges() if username_input else ""
	var password = password_input.text.strip_edges() if password_input else ""
	
	if error_label:
		error_label.text = ""
	
	if username == "" or password == "":
		if error_label:
			error_label.text = "Completa todos los campos"
			error_label.add_theme_color_override("font_color", Color.RED)
		return
	
	if username.length() < 3:
		if error_label:
			error_label.text = "Usuario mínimo 3 caracteres"
			error_label.add_theme_color_override("font_color", Color.RED)
		return
	
	show_loading(true, "INICIANDO SESION...")
	
	var http = HTTPRequest.new()
	add_child(http)
	var body = JSON.stringify({"username": username, "password": password})
	var headers = ["Content-Type: application/json"]
	http.request(API_URL + "/login", headers, HTTPClient.METHOD_POST, body)
	http.request_completed.connect(_on_login_response.bind(http, username))

func _on_login_response(result, code, headers, body, http, username):
	show_loading(false)
	
	if code == 200:
		if GameManager:
			GameManager.set_current_user(username)
		
		if error_label:
			error_label.text = "Bienvenido " + username + "!"
			error_label.add_theme_color_override("font_color", Color.GREEN)
		
		# Cambiar a main menu
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
	else:
		var response = JSON.parse_string(body.get_string_from_utf8())
		var error_msg = response["error"] if response else "Error de conexion"
		if error_label:
			error_label.text = error_msg
			error_label.add_theme_color_override("font_color", Color.RED)
	
	http.queue_free()

func _on_register_pressed():
	var username = username_input.text.strip_edges() if username_input else ""
	var password = password_input.text.strip_edges() if password_input else ""
	
	if error_label:
		error_label.text = ""
	
	if username == "" or password == "":
		if error_label:
			error_label.text = "Completa todos los campos"
			error_label.add_theme_color_override("font_color", Color.RED)
		return
	
	if username.length() < 3:
		if error_label:
			error_label.text = "Usuario mínimo 3 caracteres"
			error_label.add_theme_color_override("font_color", Color.RED)
		return
	
	if password.length() < 3:
		if error_label:
			error_label.text = "Contraseña mínimo 3 caracteres"
			error_label.add_theme_color_override("font_color", Color.RED)
		return
	
	show_loading(true, "CREANDO USUARIO...")
	
	var http = HTTPRequest.new()
	add_child(http)
	var body = JSON.stringify({"username": username, "password": password})
	var headers = ["Content-Type: application/json"]
	http.request(API_URL + "/register", headers, HTTPClient.METHOD_POST, body)
	http.request_completed.connect(_on_register_response.bind(http))

func _on_register_response(result, code, headers, body, http):
	show_loading(false)
	
	if code == 200:
		if error_label:
			error_label.text = "Usuario creado! Ahora inicia sesion"
			error_label.add_theme_color_override("font_color", Color.GREEN)
		if username_input:
			username_input.text = ""
		if password_input:
			password_input.text = ""
	else:
		var response = JSON.parse_string(body.get_string_from_utf8())
		var error_msg = response["error"] if response else "Error de conexion"
		if error_label:
			error_label.text = error_msg
			error_label.add_theme_color_override("font_color", Color.RED)
	
	http.queue_free()

func _on_guest_pressed():
	if GameManager:
		GameManager.set_current_user("INVITADO")
	
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
