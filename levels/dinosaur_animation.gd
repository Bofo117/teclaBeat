extends AnimatedSprite2D

var dino_nodes = {}
var is_animating: bool = false
var animation_duration: float = 0.3
var original_positions = {}
var current_dino_num: int = 1

# Mapeo de teclas
var key_to_dino_num = {
	"button_Q": 1,
	"button_W": 2,
	"button_E": 3,
	"button_R": 4
}

# Movimientos por dinosaurio
var dino_movements = {
	1: Vector2(-50, 0),   # D1 -> izquierda
	2: Vector2(0, 50),    # D2 -> abajo
	3: Vector2(50, 0),    # D3 -> derecha
	4: Vector2(0, -50)    # D4 -> arriba
}

func _ready():
	# Buscar dinosaurios automáticamente (hijos de este nodo)
	for child in get_children():
		if child is AnimatedSprite2D:
			var num = extract_number(child.name)
			if num > 0 and num <= 4:
				dino_nodes[num] = child
				original_positions[child] = child.position
				child.visible = false
				print("✅ Encontrado: ", child.name, " (posición: ", child.position, ")")
	
	# Verificar que encontramos todos
	for i in range(1, 5):
		if not dino_nodes.has(i):
			print("❌ No se encontró Dinosaurio", i)
			# Crear un dinosaurio temporal si falta
			create_temp_dino(i)
	
	if dino_nodes.is_empty():
		print("❌ ERROR: No se encontraron dinosaurios. Crea los nodos manualmente.")
		return
	
	# Mostrar solo el primero
	show_dino_only(1)
	
	# Conectar señal
	Signals.DinoKeyPressed.connect(_on_dino_key_pressed)
	
	print("🦖 Dinosaurios listos! Total: ", dino_nodes.size())

func extract_number(name: String) -> int:
	# Extrae el número del nombre (ej: "Dinosaurio1" -> 1, "Dino2" -> 2)
	var match_str = name.replace("Dinosaurio", "").replace("Dino", "").replace("AnimatedSprite2D", "")
	if match_str.is_valid_int():
		return int(match_str)
	return 0

func create_temp_dino(dino_num: int):
	# Crear un dinosaurio temporal de color
	var temp_dino = AnimatedSprite2D.new()
	temp_dino.name = "Dinosaurio" + str(dino_num)
	temp_dino.position = Vector2(540, 360)  # Centro de pantalla
	add_child(temp_dino)
	dino_nodes[dino_num] = temp_dino
	original_positions[temp_dino] = temp_dino.position
	print("⚠️ Creado dinosaurio temporal ", dino_num)

func show_dino_only(dino_num: int):
	current_dino_num = dino_num
	for i in range(1, 5):
		if dino_nodes.has(i):
			dino_nodes[i].visible = (i == dino_num)
	
	# Reproducir animación idle si existe
	var current_dino = dino_nodes.get(dino_num)
	if current_dino and current_dino.sprite_frames and current_dino.sprite_frames.has_animation("idle"):
		current_dino.play("idle")

func _on_dino_key_pressed(key_name: String):
	print("🔑 Tecla presionada: ", key_name)
	
	if not key_to_dino_num.has(key_name):
		print("⚠️ Tecla no mapeada")
		return
	
	if is_animating:
		print("⏳ Animando...")
		return
	
	var target_dino = key_to_dino_num[key_name]
	
	if not dino_nodes.has(target_dino):
		print("❌ Dinosaurio ", target_dino, " no encontrado")
		return
	
	# Mostrar el dinosaurio correspondiente
	show_dino_only(target_dino)
	
	# Animar movimiento
	animate_dino(target_dino)

func animate_dino(dino_num: int):
	if not dino_nodes.has(dino_num):
		return
	
	is_animating = true
	var dino = dino_nodes[dino_num]
	var original_pos = original_positions[dino]
	var offset = dino_movements[dino_num]
	var target_pos = original_pos + offset
	
	print("🎬 Animando Dino", dino_num, " -> offset: ", offset)
	
	# Reproducir animación de movimiento si existe
	if dino.sprite_frames and dino.sprite_frames.has_animation("move"):
		dino.play("move")
	
	var tween = create_tween()
	tween.tween_property(dino, "position", target_pos, animation_duration * 0.3)
	tween.tween_property(dino, "position", original_pos, animation_duration * 0.7)
	tween.tween_callback(_on_animation_end.bind(dino))

func _on_animation_end(dino: AnimatedSprite2D):
	is_animating = false
	# Volver a animación idle
	if dino and dino.sprite_frames and dino.sprite_frames.has_animation("idle"):
		dino.play("idle")
	print("✅ Animación terminada")
