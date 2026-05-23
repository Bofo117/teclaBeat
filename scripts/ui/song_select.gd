extends Control

@onready var songs_container = $SongsContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	load_songs()
	
	# Mostrar modo de juego actual
	var mode_text = "1 JUGADOR" if GameManager.game_mode == 1 else "2 JUGADORES"
	$Title.text = "SELECCIONA UNA CANCIÓN - " + mode_text

func load_songs():
	# Limpiar contenedor
	for child in songs_container.get_children():
		child.queue_free()
	
	# Obtener canciones del GameManager
	var songs = GameManager.get_available_songs_list()
	
	for song in songs:
		var button = create_song_button(song["name"], song["key"])
		songs_container.add_child(button)

func create_song_button(name: String, song_key: String):
	var button = Button.new()
	button.text = name
	button.custom_minimum_size = Vector2(400, 60)
	button.add_theme_font_size_override("font_size", 20)
	button.set_meta("song_key", song_key)
	button.pressed.connect(_on_song_selected.bind(song_key))
	
	# Efectos hover
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_exit.bind(button))
	
	return button

func _on_button_hover(button):
	button.add_theme_color_override("font_color", Color.YELLOW)

func _on_button_exit(button):
	button.add_theme_color_override("font_color", Color.WHITE)

func _on_song_selected(song_key: String):
	print("Canción seleccionada: ", song_key)
	
	GameManager.set_selected_song(song_key)
	
	
	# Ir a la ventana de información de teclas
	show_loading_message("Cargando...")
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu/key_info.tscn")
	
func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func show_loading_message(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.position = Vector2(540, 500)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(label.queue_free)
