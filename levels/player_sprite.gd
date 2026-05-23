extends AnimatedSprite2D

# Configuración de teclas y animaciones
var key_to_animation = {
	"button_Q": "left",   # Q → izquierda
	"button_W": "down",   # W → abajo
	"button_E": "right",  # E → derecha
	"button_R": "up"      # R → arriba
}

var current_animation_name: String = "idle"
var is_animating_movement: bool = false

func _ready():
	# Conectar señal
	Signals.KeyPressedForMove.connect(_on_key_pressed)
	
	# Iniciar animación idle (loop infinito)
	play_loop("idle")

func play_loop(anim_name: String):
	if current_animation_name == anim_name:
		return
	current_animation_name = anim_name
	play(anim_name)
	# No hacer nada más, ya está en loop

func play_once(anim_name: String):
	if is_animating_movement:
		return
	
	is_animating_movement = true
	current_animation_name = anim_name
	play(anim_name)
	
	# Esperar a que termine la animación
	await animation_finished
	
	# Volver a idle
	is_animating_movement = false
	play_loop("idle")

func _on_key_pressed(key_name: String):
	if key_to_animation.has(key_name):
		play_once(key_to_animation[key_name])
		print("🎬 Animación: ", key_to_animation[key_name])
