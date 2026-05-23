extends Sprite2D

@export var player_id: int = 1
@export var key_name: String = ""
@export var enable_random_spawn: bool = true
var spawn_probability: float = 0.95

@onready var falling_key = preload("res://objects/falling_key.tscn")
@onready var score_text = preload("res://objects/score_press_text.tscn")

var falling_key_queue = []
var is_game_active: bool = true
var spawn_timer: Timer = null

# Combo actual
var current_combo: int = 0

# Multiplicadores por combo
var combo_multiplier_5: float = 1.2
var combo_multiplier_10: float = 1.5
var combo_multiplier_20: float = 2.0
var combo_multiplier_30: float = 2.5
var combo_multiplier_50: float = 3.0

# Spawn delays
var current_min_spawn_delay: float = 0.6
var current_max_spawn_delay: float = 1.0

# Zonas de detección
var perfect_threshold: float = 15
var great_threshold: float = 35
var good_threshold: float = 55
var ok_threshold: float = 80

# Puntajes base
var perfect_score: int = 250
var great_score: int = 100
var good_score: int = 50
var ok_score: int = 20

var random_generator: RandomNumberGenerator = RandomNumberGenerator.new()

# Control para evitar procesamiento múltiple
var is_processing_key: bool = false

func _ready():
	add_to_group("key_listener")
	$GlowOverlay.frame = frame + 4
	
	random_generator.randomize()
	_load_difficulty_config()
	_connect_combo_signals()
	
	Signals.CreateFallingKey.connect(_on_create_falling_key)
	Signals.GameOver.connect(_on_game_over)
	Signals.GameRestart.connect(_on_game_restart)
	
	if enable_random_spawn:
		_setup_random_spawn()
	
	print("✅ KeyListener listo: ", key_name, " | Spawn aleatorio: ", enable_random_spawn)

func _connect_combo_signals():
	if player_id == 1:
		if not Signals.Player1_increment_combo.is_connected(_on_combo_incremented):
			Signals.Player1_increment_combo.connect(_on_combo_incremented)
		if not Signals.Player1_reset_combo.is_connected(_on_combo_reset):
			Signals.Player1_reset_combo.connect(_on_combo_reset)
	else:
		if not Signals.Player2_increment_combo.is_connected(_on_combo_incremented):
			Signals.Player2_increment_combo.connect(_on_combo_incremented)
		if not Signals.Player2_reset_combo.is_connected(_on_combo_reset):
			Signals.Player2_reset_combo.connect(_on_combo_reset)

func _on_combo_incremented():
	current_combo += 1

func _on_combo_reset():
	current_combo = 0

func _get_combo_multiplier() -> float:
	var combo = current_combo
	if combo >= 50:
		return combo_multiplier_50
	elif combo >= 30:
		return combo_multiplier_30
	elif combo >= 20:
		return combo_multiplier_20
	elif combo >= 10:
		return combo_multiplier_10
	elif combo >= 5:
		return combo_multiplier_5
	return 1.0

func _evaluate_hit_with_combo(distance: float) -> Dictionary:
	var hit_type = ""
	var base_score = 0
	
	if distance < perfect_threshold:
		hit_type = "PERFECT"
		base_score = perfect_score
	elif distance < great_threshold:
		hit_type = "GREAT"
		base_score = great_score
	elif distance < good_threshold:
		hit_type = "GOOD"
		base_score = good_score
	elif distance < ok_threshold:
		hit_type = "OK"
		base_score = ok_score
	else:
		hit_type = "MISS"
		base_score = 0
	
	var multiplier = _get_combo_multiplier()
	var final_score = int(base_score * multiplier)
	
	return {"text": hit_type, "score": final_score, "multiplier": multiplier, "base_score": base_score}

func _load_difficulty_config():
	if DifficultyManager and DifficultyManager.has_method("get_spawn_delays"):
		var spawn_delays = DifficultyManager.get_spawn_delays()
		current_min_spawn_delay = spawn_delays["min"]
		current_max_spawn_delay = spawn_delays["max"]
	else:
		current_min_spawn_delay = 0.6
		current_max_spawn_delay = 1.0

func _setup_random_spawn():
	if spawn_timer:
		spawn_timer.queue_free()
		spawn_timer = null
	
	spawn_timer = Timer.new()
	var first_delay = randf_range(0.5, 2.0)
	spawn_timer.wait_time = first_delay
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if not is_game_active or not spawn_timer:
		return
	
	var should_spawn = randf() < 0.95
	
	if should_spawn:
		var fk_inst = falling_key.instantiate()
		get_tree().root.add_child(fk_inst)
		fk_inst.Setup(position.x, frame + 4, key_name, player_id)
		falling_key_queue.append(fk_inst)
		
		var double_spawn = randf() < 0.05
		if double_spawn:
			await get_tree().create_timer(0.1).timeout
			if is_game_active and spawn_timer:
				var fk_inst2 = falling_key.instantiate()
				get_tree().root.add_child(fk_inst2)
				fk_inst2.Setup(position.x, frame + 4, key_name, player_id)
				falling_key_queue.append(fk_inst2)
	
	if spawn_timer:
		var random_wait = randf_range(current_min_spawn_delay, current_max_spawn_delay)
		var variation = randf_range(0.8, 1.2)
		random_wait = random_wait * variation
		random_wait = clamp(random_wait, current_min_spawn_delay * 0.7, current_max_spawn_delay * 1.3)
		spawn_timer.wait_time = random_wait

func _process(delta):
	if not is_game_active:
		return
	
	if Input.is_action_just_pressed(key_name):
		_on_key_pressed()
	
	# Limpiar queue de notas inválidas
	while falling_key_queue.size() > 0 and not is_instance_valid(falling_key_queue[0]):
		falling_key_queue.pop_front()
	
	if falling_key_queue.is_empty():
		return
	
	var front_key = falling_key_queue[0]
	if not is_instance_valid(front_key):
		falling_key_queue.pop_front()
		return
	
	# VERIFICAR MISS - con protección
	if front_key.global_position.y > 500 and not front_key.was_hit:
		front_key.was_hit = true  # Marcar inmediatamente
		var key_that_passed = falling_key_queue.pop_front()
		if is_instance_valid(key_that_passed):
			_handle_miss()

func _on_key_pressed():
	if not is_game_active or is_processing_key:
		return
	
	if falling_key_queue.is_empty():
		_handle_miss()
		return
	
	var front_key = falling_key_queue[0]
	if not is_instance_valid(front_key):
		falling_key_queue.pop_front()
		_handle_miss()
		return
	
	# Evitar procesar la misma nota múltiples veces
	if front_key.was_hit:
		return
	
	front_key.was_hit = true
	is_processing_key = true
	
	var distance = abs(front_key.global_position.y - global_position.y)
	
	if distance < ok_threshold:
		var result = _evaluate_hit_with_combo(distance)
		_process_hit(result, front_key)
	else:
		# FUERA DE RANGO - Destruir la nota y contar como MISS
		print("❌ FUERA DE RANGO - Jugador ", player_id, " - Tecla: ", key_name, " - Distancia: ", distance)
		
		# Eliminar la nota de la cola
		var key_to_remove = falling_key_queue.pop_front()
		if is_instance_valid(key_to_remove):
			key_to_remove.Hit()  # Destruir la nota
		
		# Procesar MISS
		_handle_miss()
	
	is_processing_key = false

func _process_hit(result: Dictionary, key):
	var key_to_pop = falling_key_queue.pop_front()
	
	$AnimationPlayer.stop()
	$AnimationPlayer.play("key_hit")
	
	if result["text"] != "MISS":
		_emit_score_signal(result["score"])
		_emit_combo_signal("increment")
		_emit_note_hit_signal(result["score"])
		
		var display_text = result["text"]
		if result["multiplier"] > 1:
			display_text += " x" + str(result["multiplier"])
		_show_score_text(display_text)
		
		print("🎯 ", result["text"], " | Base: ", result["base_score"], " | Combo: ", current_combo, " | Multi: x", result["multiplier"], " | Total: ", result["score"])
	else:
		_handle_miss()
	
	if is_instance_valid(key_to_pop):
		key_to_pop.Hit()

func _handle_miss():
	print("❌ MISS - Jugador ", player_id, " - Tecla: ", key_name)
	_emit_combo_signal("reset")
	_show_score_text("MISS")
	
	# Obtener daño según dificultad
	var damage_amount = 10
	if DifficultyManager:
		damage_amount = DifficultyManager.get_damage_per_miss()
		print("💔 Daño al jugador según dificultad: ", damage_amount)
	
	# EMITIR SOLO UNA VEZ el daño
	Signals.PlayerDamage.emit(damage_amount)

func _emit_score_signal(score_value: int):
	if player_id == 1:
		Signals.Player1_add_score.emit(score_value)
		Signals.IncrementScore.emit(score_value)
	else:
		Signals.Player2_add_score.emit(score_value)

func _emit_combo_signal(action: String):
	if action == "increment":
		if player_id == 1:
			Signals.Player1_increment_combo.emit()
			Signals.IncrementCombo.emit()
		else:
			Signals.Player2_increment_combo.emit()
	elif action == "reset":
		if player_id == 1:
			Signals.Player1_reset_combo.emit()
			Signals.ResetCombo.emit()
		else:
			Signals.Player2_reset_combo.emit()

func _emit_note_hit_signal(score_value: int):
	if player_id == 1:
		Signals.Player1_note_hit.emit(score_value)
	else:
		Signals.Player2_note_hit.emit(score_value)

func _show_score_text(text: String):
	var st_inst = score_text.instantiate()
	get_tree().root.add_child(st_inst)
	st_inst.SetTextInfo(text)
	st_inst.global_position = global_position + Vector2(0, -20)

func _on_create_falling_key(button_name: String):
	if not enable_random_spawn and button_name == key_name:
		var fk_inst = falling_key.instantiate()
		get_tree().root.add_child(fk_inst)
		fk_inst.Setup(position.x, frame + 4)
		falling_key_queue.append(fk_inst)

func _on_game_over():
	if not is_game_active:
		return
	
	print("🛑 Game Over en ", key_name)
	is_game_active = false
	
	if spawn_timer:
		spawn_timer.stop()
		spawn_timer.queue_free()
		spawn_timer = null
	
	for key in falling_key_queue:
		if is_instance_valid(key):
			key.queue_free()
	falling_key_queue.clear()
	
	var all_notes = get_tree().get_nodes_in_group("falling_notes")
	for note in all_notes:
		if is_instance_valid(note):
			note.queue_free()

func _on_game_restart():
	print("🔄 Reinicio en ", key_name)
	is_game_active = true
	is_processing_key = false
	
	for key in falling_key_queue:
		if is_instance_valid(key):
			key.queue_free()
	falling_key_queue.clear()
	
	if enable_random_spawn:
		spawn_timer = Timer.new()
		spawn_timer.one_shot = false
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		add_child(spawn_timer)
		var random_wait = randf_range(current_min_spawn_delay, current_max_spawn_delay)
		spawn_timer.wait_time = random_wait
		spawn_timer.start()

func set_key_name(new_key: String):
	key_name = new_key

func set_player_id(id: int):
	player_id = id
	_connect_combo_signals()

func set_game_active(active: bool):
	is_game_active = active
	if not active and spawn_timer:
		spawn_timer.stop()
	elif active and spawn_timer and spawn_timer.is_stopped():
		spawn_timer.start()
