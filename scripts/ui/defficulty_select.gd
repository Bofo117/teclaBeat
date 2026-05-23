extends Control

@onready var easy_button = $Panel/EasyButton
@onready var medium_button = $Panel/MediumButton
@onready var hard_button = $Panel/HardButton
@onready var impossible_button = $Panel/ImpossibleButton
@onready var confirm_button = $Panel/ConfirmButton
@onready var back_button = $Panel/BackButton
@onready var difficulty_info = $Panel/DifficultyInfo
@onready var difficulty_description = $Panel/DifficultyDescription
@onready var boss_hp_label = $Panel/BossHPLabel
@onready var speed_label = $Panel/SpeedLabel
@onready var difficulty_title = $Panel/DifficultyTitle

var selected_difficulty = null
var buttons = {}

func _ready():
	print("=== PANTALLA DE SELECCIÓN DE DIFICULTAD ===")
	
	# Verificar que DifficultyManager existe
	if not DifficultyManager:
		print("ERROR: DifficultyManager no encontrado. Asegúrate de agregarlo como autoload")
		return
	
	# Conectar señales de botones
	easy_button.pressed.connect(_on_easy_pressed)
	medium_button.pressed.connect(_on_medium_pressed)
	hard_button.pressed.connect(_on_hard_pressed)
	impossible_button.pressed.connect(_on_impossible_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Estilizar botones
	style_buttons()
	
	# Seleccionar dificultad por defecto (MEDIO)
	_on_medium_pressed()
	
	# Deshabilitar botón confirmar hasta seleccionar
	confirm_button.disabled = true

func style_buttons():
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.2, 0.5)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button_style.border_width_left = 1
	button_style.border_width_right = 1
	button_style.border_width_top = 1
	button_style.border_width_bottom = 1
	button_style.border_color = Color(0.8, 0.6, 0.2)
	
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.5, 0.3, 0.7)
	
	for button in [easy_button, medium_button, hard_button, impossible_button, confirm_button, back_button]:
		button.add_theme_stylebox_override("normal", button_style)
		button.add_theme_stylebox_override("hover", hover_style)
	
	# Colores específicos por dificultad
	easy_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	medium_button.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	hard_button.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	impossible_button.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _on_easy_pressed():
	select_difficulty(DifficultyManager.Difficulty.EASY, easy_button)

func _on_medium_pressed():
	select_difficulty(DifficultyManager.Difficulty.MEDIUM, medium_button)

func _on_hard_pressed():
	select_difficulty(DifficultyManager.Difficulty.HARD, hard_button)

func _on_impossible_pressed():
	select_difficulty(DifficultyManager.Difficulty.IMPOSSIBLE, impossible_button)

func select_difficulty(difficulty, button):
	selected_difficulty = difficulty
	
	# Resetear colores de todos los botones
	for btn in [easy_button, medium_button, hard_button, impossible_button]:
		btn.add_theme_color_override("font_color", Color.WHITE)
	
	# Resaltar botón seleccionado
	match difficulty:
		DifficultyManager.Difficulty.EASY:
			button.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		DifficultyManager.Difficulty.MEDIUM:
			button.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
		DifficultyManager.Difficulty.HARD:
			button.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
		DifficultyManager.Difficulty.IMPOSSIBLE:
			button.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	
	# Actualizar información
	update_difficulty_info(difficulty)
	
	# Habilitar botón confirmar
	confirm_button.disabled = false

func update_difficulty_info(difficulty):
	DifficultyManager.set_difficulty(difficulty)
	
	var config = DifficultyManager.get_current_config()
	
	# Actualizar título
	difficulty_title.text = "DIFICULTAD: " + config["name"]
	difficulty_title.add_theme_color_override("font_color", config["color"])
	
	# Actualizar descripción
	difficulty_description.text = config["description"]
	difficulty_description.add_theme_color_override("font_color", config["color"])
	
	# Actualizar estadísticas del jefe
	boss_hp_label.text = "JEFE: " + str(config["boss_hp"]) + " HP"
	boss_hp_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	
	# Actualizar información de velocidad
	var spawn_delays = DifficultyManager.get_spawn_delays()
	var base_note_speed = DifficultyManager.get_base_note_speed()
	speed_label.text = "VELOCIDAD BASE: %.1f notas/seg " % [base_note_speed]
	speed_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	# Información adicional
	var info_text = """

""" % [
		config["base_damage_to_boss"],
		config["damage_per_miss"],
		config["player_hp"],
		config["combo_multipliers"].get(50, 2.0)
	]
	
	difficulty_info.text = info_text
	
	# Guardar en GameManager
	if GameManager:
		GameManager.game_difficulty = difficulty
		GameManager.difficulty_config = config
		GameManager.current_difficulty_name = config["name"]
	
	print("Info actualizada para dificultad: ", config["name"])

func _on_confirm_pressed():
	if selected_difficulty == null:
		print("No hay dificultad seleccionada")
		return
	
	print("Dificultad seleccionada: ", DifficultyManager.get_difficulty_name())
	
	# Ir a selección de canción
	get_tree().change_scene_to_file("res://scenes/menu/song_select.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

# Función para obtener dificultad desde GameManager (útil para debug)
func get_current_difficulty_name() -> String:
	if GameManager and GameManager.has("current_difficulty_name"):
		return GameManager.current_difficulty_name
	return "No seleccionada"
