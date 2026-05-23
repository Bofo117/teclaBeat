extends Node2D

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthLabel
@onready var animation_player = $AnimationPlayer

var max_health: int = 10000
var current_health: int = 10000

# Daño base por tipo de hit
var perfect_damage: int = 25
var great_damage: int = 15
var good_damage: int = 10
var ok_damage: int = 5

# Multiplicadores por combo
var combo_multiplier_5: float = 1.2
var combo_multiplier_10: float = 1.5
var combo_multiplier_20: float = 2.0
var combo_multiplier_30: float = 2.5
var combo_multiplier_50: float = 3.0

var is_defeated: bool = false
var original_modulate: Color = Color.WHITE
var hit_flash_tween: Tween = null
var defeat_handled: bool = false

signal health_changed(current_health, max_health)
signal villain_defeated

func _ready():
	_load_difficulty_config()
	_setup_health_bar()
	_setup_visuals()
	_connect_signals()
	
	original_modulate = modulate
	print("🦹 Villano 2P inicializado con ", max_health, " HP")

func _load_difficulty_config():
	if DifficultyManager:
		max_health = DifficultyManager.get_boss_hp()
		
		var config = DifficultyManager.get_current_config()
		if config.has("combo_multipliers"):
			var multipliers = config["combo_multipliers"]
			combo_multiplier_5 = multipliers.get(5, 1.2)
			combo_multiplier_10 = multipliers.get(10, 1.5)
			combo_multiplier_20 = multipliers.get(20, 2.0)
			combo_multiplier_30 = multipliers.get(30, 2.5)
			combo_multiplier_50 = multipliers.get(50, 3.0)
	else:
		max_health = 10000
	
	current_health = max_health

func _setup_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.1, 0.1)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.6, 0.2)
		health_bar.add_theme_stylebox_override("bg", style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.9, 0.2, 0.2)
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	if health_label:
		_update_health_label()

func _setup_visuals():
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _connect_signals():
	# Conectar notas de ambos jugadores
	if Signals.has_signal("Player1_note_hit"):
		if not Signals.Player1_note_hit.is_connected(_on_player1_note_hit):
			Signals.Player1_note_hit.connect(_on_player1_note_hit)
	
	if Signals.has_signal("Player2_note_hit"):
		if not Signals.Player2_note_hit.is_connected(_on_player2_note_hit):
			Signals.Player2_note_hit.connect(_on_player2_note_hit)

func _on_player1_note_hit(score_value: int):
	if is_defeated:
		return
	
	var combo = GameManager.best_combo_player1 if GameManager else 0
	var hit_type = _get_hit_type_from_score(score_value, combo)
	_take_damage_with_type(score_value, combo, hit_type, 1)

func _on_player2_note_hit(score_value: int):
	if is_defeated:
		return
	
	var combo = GameManager.best_combo_player2 if GameManager else 0
	var hit_type = _get_hit_type_from_score(score_value, combo)
	_take_damage_with_type(score_value, combo, hit_type, 2)

func _get_hit_type_from_score(score_value: int, combo: int) -> String:
	var multiplier = _get_combo_multiplier(combo)
	var base_score = score_value / multiplier if multiplier > 0 else score_value
	
	if base_score >= 200:
		return "PERFECT"
	elif base_score >= 80:
		return "GREAT"
	elif base_score >= 40:
		return "GOOD"
	elif base_score >= 15:
		return "OK"
	return "MISS"

func _get_combo_multiplier(combo: int) -> float:
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

func _take_damage_with_type(score_value: int, combo: int, hit_type: String, player_id: int):
	if hit_type == "MISS":
		return
	
	var base_damage_value = 0
	match hit_type:
		"PERFECT":
			base_damage_value = perfect_damage
		"GREAT":
			base_damage_value = great_damage
		"GOOD":
			base_damage_value = good_damage
		"OK":
			base_damage_value = ok_damage
	
	var combo_multiplier = _get_combo_multiplier(combo)
	var final_damage = int(base_damage_value * combo_multiplier)
	
	current_health -= final_damage
	current_health = max(0, current_health)
	
	print("🎯 J", player_id, " HIT: ", hit_type, " | Daño: ", final_damage, " | Vida villano: ", current_health)
	
	_update_health_bar()
	_update_health_label()
	_play_hit_effect()
	_shake_villain()
	_show_damage_number(final_damage, hit_type)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and not is_defeated and not defeat_handled:
		_defeat_villain()

func _show_damage_number(damage: int, hit_type: String):
	var damage_label = Label.new()
	damage_label.text = str(damage)
	damage_label.add_theme_font_size_override("font_size", 28)
	
	match hit_type:
		"PERFECT":
			damage_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		"GREAT":
			damage_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
		"GOOD":
			damage_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1))
		"OK":
			damage_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	damage_label.position = position + Vector2(20, -50)
	add_child(damage_label)
	
	var tween = create_tween()
	tween.tween_property(damage_label, "position", position + Vector2(20, -100), 0.5)
	tween.parallel().tween_property(damage_label, "modulate:a", 0, 0.5)
	tween.tween_callback(damage_label.queue_free)

func _update_health_bar():
	if health_bar:
		health_bar.value = current_health
		
		var fill_style = StyleBoxFlat.new()
		var health_percent = float(current_health) / max_health
		
		if health_percent > 0.6:
			fill_style.bg_color = Color(0.2, 0.8, 0.2)
		elif health_percent > 0.3:
			fill_style.bg_color = Color(0.9, 0.7, 0.2)
		else:
			fill_style.bg_color = Color(0.9, 0.2, 0.2)
		
		health_bar.add_theme_stylebox_override("fill", fill_style)

func _update_health_label():
	if health_label:
		health_label.text = str(current_health) + "/" + str(max_health)

func _play_hit_effect():
	if hit_flash_tween and hit_flash_tween.is_valid():
		hit_flash_tween.kill()
	
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(self, "modulate", Color(2, 1.5, 1.5, 1), 0.05)
	hit_flash_tween.tween_property(self, "modulate", original_modulate, 0.15)

func _shake_villain():
	var original_pos = position
	var shake_tween = create_tween()
	shake_tween.tween_property(self, "position", original_pos + Vector2(8, 0), 0.05)
	shake_tween.tween_property(self, "position", original_pos - Vector2(6, 0), 0.05)
	shake_tween.tween_property(self, "position", original_pos + Vector2(4, 0), 0.05)
	shake_tween.tween_property(self, "position", original_pos - Vector2(2, 0), 0.05)
	shake_tween.tween_property(self, "position", original_pos, 0.05)

func _defeat_villain():
	if defeat_handled:
		return
	
	defeat_handled = true
	is_defeated = true
	print("🏆 ===== VILLANO DERROTADO EN MODO 2P =====")
	
	# Detener todas las notas
	_stop_all_notes_and_timers()
	
	# Anunciar victoria a todos los jugadores
	Signals.VictoryAchieved.emit()
	
	await get_tree().create_timer(0.2).timeout
	
	# Animación de derrota
	for i in range(3):
		var defeat_tween = create_tween()
		defeat_tween.tween_property(self, "modulate", Color(2, 0.5, 0.5, 1), 0.1)
		defeat_tween.tween_property(self, "modulate", original_modulate, 0.1)
		await get_tree().create_timer(0.1).timeout
	
	if animation_player and animation_player.has_animation("defeat"):
		animation_player.play("defeat")
	
	villain_defeated.emit()
	
	await get_tree().create_timer(1.5).timeout
	_go_to_results()

func _stop_all_notes_and_timers():
	print("🛑 Deteniendo TODAS las notas...")
	
	var all_listeners = get_tree().get_nodes_in_group("key_listener")
	for listener in all_listeners:
		if listener.has_method("set_game_active"):
			listener.set_game_active(false)
		if listener.has_method("_on_game_over"):
			listener._on_game_over()
	
	var all_notes = get_tree().get_nodes_in_group("falling_notes")
	for note in all_notes:
		if is_instance_valid(note):
			note.queue_free()

func _go_to_results():
	var scene_path = "res://scenes/menu/result_screen.tscn"
	if GameManager and GameManager.game_mode == 2:
		scene_path = "res://scenes/menu/result_screen_2p.tscn"
	
	print("📺 Cargando escena: ", scene_path)
	get_tree().change_scene_to_file(scene_path) 


func reset_villain():
	_load_difficulty_config()
	current_health = max_health
	is_defeated = false
	defeat_handled = false
	_update_health_bar()
	_update_health_label()
	modulate = original_modulate
	
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
