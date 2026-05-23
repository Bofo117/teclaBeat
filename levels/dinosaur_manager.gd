extends Node2D

var dino_nodes = {}
var last_pressed_key: String = ""

var key_to_dino = {
	"button_Q": {"dino_num": 1, "animation": "D1"},
	"button_W": {"dino_num": 2, "animation": "D2"},
	"button_E": {"dino_num": 3, "animation": "D3"},
	"button_R": {"dino_num": 4, "animation": "D4"}
}

func _ready():
	# Buscar todos los dinosaurios
	for child in get_children():
		if child is AnimatedSprite2D:
			var num = extract_number(child.name)
			if num > 0 and num <= 4:
				dino_nodes[num] = child
				child.visible = true
				child.stop()
				child.frame = 0
				# Configurar animación sin loop
				var anim_name = "D" + str(num)
				if child.sprite_frames and child.sprite_frames.has_animation(anim_name):
					child.sprite_frames.set_animation_loop(anim_name, false)
					print("✅ Dinosaurio ", num, " listo - Animación: ", anim_name)
				else:
					print("⚠️ Dinosaurio ", num, " no tiene animación ", anim_name)
	
	# Conectar señales
	Signals.LastKeyPressed.connect(_on_last_key_pressed)
	Signals.IncrementScore.connect(_on_correct_hit)
	Signals.IncrementCombo.connect(_on_correct_hit)
	Signals.Player1_add_score.connect(_on_correct_hit)
	Signals.Player1_increment_combo.connect(_on_correct_hit)
	Signals.Player2_add_score.connect(_on_correct_hit)
	Signals.Player2_increment_combo.connect(_on_correct_hit)
	
	print("🦖 Dinosaurios listos! Total encontrados: ", dino_nodes.size())

func extract_number(name: String) -> int:
	var match_str = name.replace("Dinosaurio", "").replace("Dino", "").replace("AnimatedSprite2D", "")
	if match_str.is_valid_int():
		return int(match_str)
	return 0

func _on_last_key_pressed(key_name: String):
	last_pressed_key = key_name
	print("📝 Última tecla guardada: ", key_name)

func _on_correct_hit(_value = null):
	print("🎯 ACIERTO DETECTADO! Última tecla: ", last_pressed_key)
	
	if last_pressed_key == "":
		print("⚠️ No hay última tecla guardada")
		return
	
	if not key_to_dino.has(last_pressed_key):
		print("⚠️ Tecla no mapeada: ", last_pressed_key)
		return
	
	var dino_num = key_to_dino[last_pressed_key]["dino_num"]
	var animation_name = key_to_dino[last_pressed_key]["animation"]
	
	print("🦖 Activando Dino", dino_num, " con animación: ", animation_name)
	
	if not dino_nodes.has(dino_num):
		print("❌ Dino", dino_num, " no encontrado")
		return
	
	var dino = dino_nodes[dino_num]
	
	# Activar el dinosaurio
	activate_dino(dino, animation_name, dino_num)

func activate_dino(dino: AnimatedSprite2D, animation_name: String, dino_num: int):
	# Detener cualquier animación actual
	dino.stop()
	
	# Reproducir animación
	if dino.sprite_frames and dino.sprite_frames.has_animation(animation_name):
		dino.play(animation_name)
		print("🎬 Dino", dino_num, " ACTIVADO - Animación: ", animation_name)
	else:
		# Fallback: solo mostrar el frame
		dino.frame = dino_num - 1
		print("⚠️ Animación no encontrada, mostrando frame ", dino.frame)
	
	# Esperar 0.7 segundos
	await get_tree().create_timer(0.7).timeout
	
	# Detener y volver a frame 0
	if dino:
		dino.stop()
		dino.frame = 0
		print("✅ Dino", dino_num, " detenido")
