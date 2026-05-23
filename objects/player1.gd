extends Node2D

# ===== VARIABAS EXISTENTES =====
@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthLabel

var max_health: int = 100
var current_health: int = 100
var is_dead: bool = false
var is_game_over_handled: bool = false

var miss_damage: int = 10
var combo_miss_penalty: float = 0.2

var original_modulate: Color = Color.WHITE
var damage_flash_tween: Tween = null

# ===== VARIABLES DE ESTADÍSTICAS =====
var game_start_time: float = 0.0
var game_end_time: float = 0.0
var perfect_count: int = 0
var great_count: int = 0
var good_count: int = 0
var ok_count: int = 0
var miss_count: int = 0
var total_notes_hit: int = 0
var game_victory: bool = false
var combo_count: int = 0  # <--- AÑADIDA ESTA VARIABLE

# Control para evitar daño duplicado
var last_damage_time: float = 0
var damage_cooldown: float = 0.3

signal health_changed(current_health, max_health)
signal player_died

func _ready():
	add_to_group("player")
	# Cargar configuración de dificultad
	_load_difficulty_config()
	
	_setup_health_bar()
	_setup_visuals()
	_connect_signals()
	
	# Registrar tiempo de inicio
	game_start_time = Time.get_ticks_msec() / 1000.0
	print("⏱️ Tiempo de inicio: ", game_start_time)
	
	# Conectar señales de estadísticas
	_connect_stats_signals()
	
	print("❤️ Jugador inicializado con ", max_health, " HP (dificultad: ", _get_difficulty_name(), ")")

func _connect_stats_signals():
	# Conectar para contar hits
	if Signals.has_signal("Player1_note_hit"):
		if not Signals.Player1_note_hit.is_connected(_on_note_hit_record):
			Signals.Player1_note_hit.connect(_on_note_hit_record)
	
	# Conectar para contar misses
	if Signals.has_signal("Player1_reset_combo"):
		if not Signals.Player1_reset_combo.is_connected(_on_miss_record):
			Signals.Player1_reset_combo.connect(_on_miss_record)
	
	# Conectar para combo
	if Signals.has_signal("Player1_increment_combo"):
		if not Signals.Player1_increment_combo.is_connected(_on_increment_combo):
			Signals.Player1_increment_combo.connect(_on_increment_combo)
	if Signals.has_signal("Player1_reset_combo"):
		if not Signals.Player1_reset_combo.is_connected(_on_reset_combo):
			Signals.Player1_reset_combo.connect(_on_reset_combo)

func _on_increment_combo():
	combo_count += 1
	# Guardar el maximo combo alcanzado
	if combo_count > GameManager.max_combo_achieved:
		GameManager.max_combo_achieved = combo_count
		print("NUEVO MAXIMO COMBO: ", GameManager.max_combo_achieved)
	print("Combo: ", combo_count)

func _on_reset_combo():
	combo_count = 0
	print("🔄 Combo reiniciado")

func _on_note_hit_record(score_value: int):
	total_notes_hit += 1
	
	# Determinar el tipo de hit basado en el valor del score
	var base_score_approx = float(score_value)
	
	# Si hay combo alto, el score viene multiplicado
	if GameManager and GameManager.best_combo >= 50:
		base_score_approx = score_value / 3.0
	elif GameManager and GameManager.best_combo >= 30:
		base_score_approx = score_value / 2.5
	elif GameManager and GameManager.best_combo >= 20:
		base_score_approx = score_value / 2.0
	elif GameManager and GameManager.best_combo >= 10:
		base_score_approx = score_value / 1.5
	elif GameManager and GameManager.best_combo >= 5:
		base_score_approx = score_value / 1.2
	
	if base_score_approx >= 200:
		perfect_count += 1
		print("📊 PERFECT registrado (", perfect_count, ")")
	elif base_score_approx >= 80:
		great_count += 1
		print("📊 GREAT registrado (", great_count, ")")
	elif base_score_approx >= 40:
		good_count += 1
		print("📊 GOOD registrado (", good_count, ")")
	elif base_score_approx >= 15:
		ok_count += 1
		print("📊 OK registrado (", ok_count, ")")
		
func _on_miss_record():
	miss_count += 1
	print("📊 MISS registrado (", miss_count, ")")

func _load_difficulty_config():
	if DifficultyManager:
		max_health = DifficultyManager.get_player_hp()
		miss_damage = DifficultyManager.get_damage_per_miss()
		
		var config = DifficultyManager.get_current_config()
		if config.has("combo_multipliers"):
			var multipliers = config["combo_multipliers"]
			if multipliers.has(10):
				combo_miss_penalty = 0.15
			if multipliers.has(20):
				combo_miss_penalty = 0.2
			if multipliers.has(30):
				combo_miss_penalty = 0.25
	else:
		max_health = 100
		miss_damage = 10
	
	current_health = max_health

func _get_difficulty_name() -> String:
	if DifficultyManager:
		return DifficultyManager.get_difficulty_name()
	return "NORMAL"

func _setup_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.2)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.2, 0.6, 0.8)
		health_bar.add_theme_stylebox_override("bg", style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.2, 0.5, 0.9)
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	if health_label:
		_update_health_label()

func _setup_visuals():
	if get_parent() and get_parent() is CanvasItem:
		original_modulate = get_parent().modulate

func _connect_signals():
	# IMPORTANTE: SOLO conectar PlayerDamage
	if Signals.has_signal("PlayerDamage"):
		if not Signals.PlayerDamage.is_connected(_on_player_damage):
			Signals.PlayerDamage.connect(_on_player_damage)
	
	print("✅ Señales conectadas: SOLO PlayerDamage")

func _on_player_damage(amount: int):
	if is_dead or is_game_over_handled:
		return
	
	# Evitar daño duplicado por cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time < damage_cooldown:
		print("⚠️ Daño ignorado por cooldown")
		return
	
	last_damage_time = current_time
	
	# Usar el daño exacto que viene del KeyListener
	var final_damage = amount
	print("💔 Daño recibido: ", final_damage)
	
	_take_damage_with_value(final_damage)

func _get_current_combo() -> int:
	return combo_count

func _take_damage_with_value(damage: int):
	current_health -= damage
	current_health = max(0, current_health)
	
	_update_health_bar()
	_update_health_label()
	_play_damage_effect()
	
	print("💔 Vida restante: ", current_health, "/", max_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and not is_dead and not is_game_over_handled:
		_player_death()

func _update_health_bar():
	if health_bar:
		health_bar.value = current_health
		
		var fill_style = StyleBoxFlat.new()
		var health_percent = float(current_health) / max_health
		
		if health_percent > 0.6:
			fill_style.bg_color = Color(0.2, 0.5, 0.9)
		elif health_percent > 0.3:
			fill_style.bg_color = Color(0.9, 0.7, 0.2)
		else:
			fill_style.bg_color = Color(0.9, 0.2, 0.2)
		
		health_bar.add_theme_stylebox_override("fill", fill_style)

func _update_health_label():
	if health_label:
		health_label.text = str(current_health) + "/" + str(max_health)

func _play_damage_effect():
	var player_node = get_parent()
	if player_node and player_node is CanvasItem:
		if damage_flash_tween and damage_flash_tween.is_valid():
			damage_flash_tween.kill()
		
		damage_flash_tween = create_tween()
		damage_flash_tween.tween_property(player_node, "modulate", Color(2, 0.5, 0.5, 1), 0.08)
		damage_flash_tween.tween_property(player_node, "modulate", original_modulate, 0.2)

# ===== FUNCIÓN MODIFICADA: DERROTA DEL JUGADOR =====
func _player_death():
	if is_dead or is_game_over_handled:
		return
	
	is_dead = true
	is_game_over_handled = true
	game_end_time = Time.get_ticks_msec() / 1000.0
	game_victory = false
	
	print("💀 ¡JUGADOR DERROTADO! 💀")
	print("⏱️ Tiempo de partida: ", game_end_time - game_start_time, " segundos")
	print("📊 Estadísticas finales:")
	print("   - PERFECT: ", perfect_count)
	print("   - GREAT: ", great_count)
	print("   - GOOD: ", good_count)
	print("   - OK: ", ok_count)
	print("   - MISS: ", miss_count)
	print("   - Total notas: ", total_notes_hit)
	
	# Guardar datos en GameManager
	_save_game_data_to_manager()
	
	Signals.GameOver.emit()
	player_died.emit()
	
	_show_death_message()
	await get_tree().create_timer(1.5).timeout
	_go_to_results()

# ===== FUNCIÓN GUARDAR DATOS =====
func _save_game_data_to_manager():
	print("💾 ===== GUARDANDO DATOS =====")
	
	if not GameManager:
		print("❌ GameManager es NULL!")
		return
	
	# Obtener referencia al villano
	var villain_node = get_node("/root/GameLevel/Villain")
	if not villain_node:
		villain_node = get_node("../Villain")
	
	var boss_hp = 0
	if villain_node:
		boss_hp = villain_node.current_health
		print("   ✅ Vida del jefe: ", boss_hp)
	
	# Guardar TODOS los datos
	GameManager.game_completed = game_victory
	GameManager.current_scores.player1 = 0
	GameManager.current_song_name = GameManager.selected_song_key if GameManager.selected_song_key else "RHYTHM_HELL"
	GameManager.time_to_complete = game_end_time - game_start_time
	GameManager.final_boss_hp_remaining = boss_hp
	GameManager.final_player_hp_remaining = current_health
	GameManager.max_combo_achieved = max(combo_count, GameManager.max_combo_achieved)  # Tomar el mayor
	
	GameManager.total_notes_hit = total_notes_hit
	GameManager.perfect_count = perfect_count
	GameManager.great_count = great_count
	GameManager.good_count = good_count
	GameManager.ok_count = ok_count
	GameManager.miss_count = miss_count
	
	print("📊 DATOS GUARDADOS:")
	print("   - game_completed: ", GameManager.game_completed)
	print("   - time: ", GameManager.time_to_complete)
	print("   - max_combo: ", GameManager.max_combo_achieved)
	print("   - perfect: ", GameManager.perfect_count)
	print("   - great: ", GameManager.great_count)
	print("   - good: ", GameManager.good_count)
	print("   - ok: ", GameManager.ok_count)
	print("   - miss: ", GameManager.miss_count)
	
func _show_death_message():
	var message_label = Label.new()
	message_label.text = "GAME OVER"
	message_label.add_theme_font_size_override("font_size", 48)
	message_label.add_theme_color_override("font_color", Color(1, 0, 0))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var screen_size = get_viewport().get_visible_rect().size
	message_label.position = Vector2((screen_size.x - 1400) / 2, (screen_size.y - 1000) / 2)
	message_label.size = Vector2(300, 60)
	message_label.z_index = 100
	get_tree().root.add_child(message_label)
	
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(message_label):
		message_label.queue_free()

func _go_to_results():
	var scene_path = "res://scenes/menu/result_screen.tscn"
	if GameManager and GameManager.game_mode == 2:
		scene_path = "res://scenes/menu/result_screen_2p.tscn"
	
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file(scene_path)

func reset_health():
	_load_difficulty_config()
	current_health = max_health
	is_dead = false
	is_game_over_handled = false
	_update_health_bar()
	_update_health_label()
	
	var player_node = get_parent()
	if player_node:
		player_node.modulate = Color(1, 1, 1, 1)
	
	print("❤️ Jugador reiniciado")

# ===== FUNCIÓN PARA VICTORIA =====
func register_victory():
	print("🏆 ===== REGISTER_VICTORY LLAMADO =====")
	
	if is_game_over_handled:
		print("⚠️ register_victory ignorado - game_over ya manejado")
		return
	
	game_end_time = Time.get_ticks_msec() / 1000.0
	game_victory = true
	is_game_over_handled = true
	if combo_count > GameManager.max_combo_achieved:
		GameManager.max_combo_achieved = combo_count
	print("📊 DATOS DE VICTORIA:")
	print("   - game_victory: ", game_victory)
	print("   - Tiempo: ", game_end_time - game_start_time)
	print("   - Perfect: ", perfect_count)
	print("   - Great: ", great_count)
	print("   - Good: ", good_count)
	print("   - OK: ", ok_count)
	print("   - Miss: ", miss_count)
	print("   - Max Combo: ", combo_count)
	
	# Guardar datos en GameManager
	_save_game_data_to_manager()
	
	print("✅ register_victory COMPLETADO")
