extends Sprite2D

var fall_speed: float = 2.0
var init_y_pos: float = -360
var has_passed: bool = false
var pass_threshold = 250.0
var miss_threshold = 350.0  # Aumentado para dar más tiempo
var was_hit: bool = false
var has_damaged: bool = false  # NUEVO: evitar daño múltiple
var owner_key_name: String = ""  # NUEVO: saber qué tecla la creó
var owner_player_id: int = 1  # NUEVO: saber qué jugador

func _init():
	set_process(false)

func _ready():
	add_to_group("falling_notes")
	_setup_difficulty_speed()
	_setup_difficulty_speed()

func _setup_difficulty_speed():
	if DifficultyManager and DifficultyManager.has_method("get_base_note_speed"):
		fall_speed = DifficultyManager.get_base_note_speed()
	else:
		fall_speed = 2.0

func _process(delta):
	if was_hit:
		return
	
	global_position += Vector2(0, fall_speed)
	
	# Cuando pasa el punto de detección (zona de juicio)
	if global_position.y > pass_threshold and not has_passed:
		has_passed = true
		if $Timer:
			$Timer.start()
	
	# Cuando la nota pasa completamente (MISS sin presionar)
	if global_position.y > miss_threshold and not was_hit and not has_damaged:
		has_damaged = true
		_trigger_miss_damage()
		queue_free()

func Setup(target_x: float, target_frame: int, key_name: String = "", player: int = 1):
	global_position = Vector2(target_x, init_y_pos)
	frame = target_frame
	owner_key_name = key_name
	owner_player_id = player
	set_process(true)

func _trigger_miss_damage():
	print("💔 NOTA PERDIDA - Tecla: ", owner_key_name, " (Jugador ", owner_player_id, ")")
	
	# Emitir daño al jugador
	if owner_player_id == 1:
		Signals.PlayerDamage.emit(10)
		Signals.Player1_reset_combo.emit()
	else:
		Signals.Player2_reset_combo.emit()
	
	# Mostrar texto MISS en pantalla (opcional)
	var score_text_scene = preload("res://objects/score_press_text.tscn")
	if score_text_scene:
		var st_inst = score_text_scene.instantiate()
		get_tree().root.add_child(st_inst)
		st_inst.SetTextInfo("MISS")
		st_inst.global_position = global_position + Vector2(0, -20)

func Hit():
	was_hit = true
	queue_free()

func _on_destroy_timer_timeout():
	pass


# Añadir getter
func get_owner_player_id() -> int:
	return owner_player_id
