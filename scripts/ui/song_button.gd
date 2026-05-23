extends Button

@export var song_key: String = ""
@export var song_name: String = ""

var is_selected: bool = false

func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

func _on_pressed():
	is_selected = true
	add_theme_color_override("font_color", Color.GREEN)

func _on_hover():
	if not is_selected:
		add_theme_color_override("font_color", Color.YELLOW)

func _on_exit():
	if not is_selected:
		add_theme_color_override("font_color", Color.WHITE)
