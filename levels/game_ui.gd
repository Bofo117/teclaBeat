extends Control

var score: int = 0
var combo_count: int = 0

# Variables para el cronometro
var timer_running: bool = false
var elapsed_time: float = 0.0

# Referencias
@onready var health_bar = $PlayerHealthBar if has_node("PlayerHealthBar") else null
@onready var health_label = $PlayerHealthLabel if has_node("PlayerHealthLabel") else null
@onready var villain_health_bar = $VillainHealthBar if has_node("VillainHealthBar") else null
@onready var villain_health_label = $VillainHealthLabel if has_node("VillainHealthLabel") else null
@onready var timer_label = $TimerLabel if has_node("TimerLabel") else null
@onready var combo_label = $ComboLabel if has_node("ComboLabel") else null

var timer_canvas: CanvasLayer

func _ready():
	# Conectar senales
	Signals.IncrementScore.connect(IncrementScore)
	Signals.IncrementCombo.connect(IncrementCombo)
	Signals.ResetCombo.connect(ResetCombo)
	
	# Conectar senales de salud
	if GameManager and GameManager.game_mode == 1:
		var villain = get_node("/root/GameLevel/Villain")
		if villain:
			villain.health_changed.connect(_update_villain_health)
	
	var player_health = get_node("/root/GameLevel/player1")
	if player_health:
		player_health.health_changed.connect(_update_health_display)
	
	# Configurar temporizador con CanvasLayer (independiente de la camara)
	_setup_timer_canvas()
	start_timer()
	
	ResetCombo()

func _setup_timer_canvas():
	# Crear CanvasLayer para que el timer no se vea afectado por la camara
	timer_canvas = CanvasLayer.new()
	timer_canvas.layer = 100  # Capa alta para que se vea siempre encima
	add_child(timer_canvas)
	
	# Crear label dentro del canvas
	var label = Label.new()
	label.name = "TimerLabel"
	
	# Obtener tamaño de pantalla
	var screen_size = get_viewport().get_visible_rect().size
	
	# Posicion absoluta en pantalla
	label.position = Vector2(screen_size.x - 200, 20)
	
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_outline_modulate", Color(0, 0, 0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	timer_canvas.add_child(label)
	timer_label = label
	
	print("Timer Canvas created at position: ", label.position)
	print("Screen size: ", screen_size)

func _process(delta):
	if timer_running:
		elapsed_time += delta
		_update_timer_display()

func _update_timer_display():
	if timer_label:
		var minutes = floor(elapsed_time / 60)
		var seconds = int(elapsed_time) % 60
		var milliseconds = int((elapsed_time - floor(elapsed_time)) * 100)
		timer_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func start_timer():
	timer_running = true
	elapsed_time = 0.0

func stop_timer():
	timer_running = false

func get_elapsed_time() -> float:
	return elapsed_time

func IncrementScore(incr: int):
	score += incr

func _update_health_display(current, max):
	if health_bar:
		health_bar.value = current
		health_bar.max_value = max
	if health_label:
		health_label.text = str(current) + "/" + str(max)

func _update_villain_health(current, max):
	if villain_health_bar:
		villain_health_bar.value = current
		villain_health_bar.max_value = max
	if villain_health_label:
		villain_health_label.text = str(current) + "/" + str(max)

func IncrementCombo():
	combo_count += 1
	if combo_label:
		combo_label.text = str(combo_count) + "x COMBO"
		combo_label.add_theme_font_size_override("font_size", 28)
		combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		combo_label.add_theme_constant_override("outline_size", 8)

func ResetCombo():
	combo_count = 0
	if combo_label:
		combo_label.text = ""
