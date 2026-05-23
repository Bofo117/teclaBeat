extends AnimatedSprite2D

var is_dancing: bool = false
var dance_timer: float = 0.0
var dance_duration: float = 0.7

func _ready():
	# Configurar animación
	if sprite_frames.has_animation("dance"):
		sprite_frames.set_animation_loop("dance", true)
	
	# Iniciar quieto
	stop()
	frame = 0
	
	# ===== CONECTAR SEÑALES CORRECTAS PARA 1 JUGADOR =====
	Signals.IncrementScore.connect(_on_any_score)
	Signals.IncrementCombo.connect(_on_any_score)
	
	print("🕺 BackgroundDancer listo - Esperando aciertos")

func _on_any_score(_value = null):
	print("🎵 Acierto detectado - Iniciando baile")
	start_dancing()

func start_dancing():
	if is_dancing:
		dance_timer = dance_duration
		return
	
	is_dancing = true
	dance_timer = dance_duration
	
	if sprite_frames.has_animation("dance"):
		play("dance")
		print("💃 ¡Bailando!")
	else:
		print("⚠️ No se encontró la animación 'dance'")

func _process(delta):
	if is_dancing:
		dance_timer -= delta
		if dance_timer <= 0:
			is_dancing = false
			stop()
			frame = 0
			print("🕺 Baile terminado")
