extends Node2D

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthLabel
@onready var sprite = $Sprite  # Tu sprite del personaje
@onready var animation_player = $AnimationPlayer  # Opcional


var player_id: int = 1
var player_name: String = "JUGADOR 1"
var max_health: int = 100
var current_health: int = 100
var is_dead: bool = false
var is_game_over_handled: bool = false

var miss_damage: int = 10
var original_modulate: Color = Color.WHITE
var damage_flash_tween: Tween = null

# Estadísticas individuales
var perfect_count: int = 0
var great_count: int = 0
var good_count: int = 0
var ok_count: int = 0
var miss_count: int = 0
var combo_count: int = 0
var best_combo: int = 0
var total_score: int = 0

# Control de daño
var last_damage_time: float = 0
var damage_cooldown: float = 0.3

# Colores del jugador
var player_color = Color(1, 0.5, 0.2)  # Naranja

signal health_changed(current_health, max_health)
signal player_died(player_id)

func _ready():
	add_to_group("players")
	add_to_group("player1")
	
	_load_difficulty_config()
	_setup_health_bar()
	_setup_visuals()
	_connect_signals()
	
	print("❤️ ", player_name, " inicializado con ", max_health, " HP")

func _load_difficulty_config():
	if DifficultyManager:
		max_health = DifficultyManager.get_player_hp()
		miss_damage = DifficultyManager.get_damage_per_miss()
	else:
		max_health = 100
		miss_damage = 10
	
	current_health = max_health

func _setup_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		
		# Estilo personalizado para Jugador 1
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.05, 0.05)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = player_color
		health_bar.add_theme_stylebox_override("bg", style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = player_color
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	if health_label:
		health_label.add_theme_color_override("font_color", player_color)
		_update_health_label()

func _setup_visuals():
	if sprite:
		original_modulate = sprite.modulate
		# Configurar animación idle
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")

func _connect_signals():
	# Conectar señales de daño
	if Signals.has_signal("Player1Damage"):
		if not Signals.Player1Damage.is_connected(_on_damage):
			Signals.Player1Damage.connect(_on_damage)
	
	# Conectar señales de notas
	if Signals.has_signal("Player1_note_hit"):
		if not Signals.Player1_note_hit.is_connected(_on_note_hit):
			Signals.Player1_note_hit.connect(_on_note_hit)
	
	if Signals.has_signal("Player1_increment_combo"):
		if not Signals.Player1_increment_combo.is_connected(_on_increment_combo):
			Signals.Player1_increment_combo.connect(_on_increment_combo)
	
	if Signals.has_signal("Player1_reset_combo"):
		if not Signals.Player1_reset_combo.is_connected(_on_reset_combo):
			Signals.Player1_reset_combo.connect(_on_reset_combo)
	
	if Signals.has_signal("Player1_add_score"):
		if not Signals.Player1_add_score.is_connected(_on_add_score):
			Signals.Player1_add_score.connect(_on_add_score)

func _on_damage(amount: int):
	if is_dead or is_game_over_handled:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time < damage_cooldown:
		return
	
	last_damage_time = current_time
	_take_damage(amount)

func _take_damage(damage: int):
	current_health -= damage
	current_health = max(0, current_health)
	
	_update_health_bar()
	_update_health_label()
	_play_damage_effect()
	_play_hurt_animation()
	
	print("💔 ", player_name, " - Vida: ", current_health, "/", max_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and not is_dead and not is_game_over_handled:
		_player_death()

func _on_note_hit(score_value: int):
	var multiplier = _get_combo_multiplier()
	var base_score = score_value / multiplier if multiplier > 0 else score_value
	
	if base_score >= 200:
		perfect_count += 1
		_play_hit_effect("perfect")
	elif base_score >= 80:
		great_count += 1
		_play_hit_effect("great")
	elif base_score >= 40:
		good_count += 1
		_play_hit_effect("good")
	elif base_score >= 15:
		ok_count += 1
		_play_hit_effect("ok")

func _on_increment_combo():
	combo_count += 1
	if combo_count > best_combo:
		best_combo = combo_count
	
	if GameManager:
		GameManager.update_best_combo_player(1, combo_count)
	
	# Efecto visual cuando el combo es alto
	if combo_count >= 10 and combo_count % 10 == 0:
		_play_combo_effect()

func _on_reset_combo():
	miss_count += 1
	combo_count = 0
	_play_miss_effect()

func _on_add_score(incr: int):
	total_score += incr
	if GameManager:
		GameManager.current_scores.player1 = total_score

func _get_combo_multiplier() -> float:
	if combo_count >= 50:
		return 3.0
	elif combo_count >= 30:
		return 2.5
	elif combo_count >= 20:
		return 2.0
	elif combo_count >= 10:
		return 1.5
	elif combo_count >= 5:
		return 1.2
	return 1.0

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

func _play_damage_effect():
	if sprite:
		if damage_flash_tween and damage_flash_tween.is_valid():
			damage_flash_tween.kill()
		
		damage_flash_tween = create_tween()
		damage_flash_tween.tween_property(sprite, "modulate", Color(2, 0.5, 0.5, 1), 0.08)
		damage_flash_tween.tween_property(sprite, "modulate", original_modulate, 0.2)

func _play_hit_effect(hit_type: String):
	if not sprite:
		return
	
	var tween = create_tween()
	match hit_type:
		"perfect":
			tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.05)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
		"great":
			tween.tween_property(sprite, "scale", Vector2(1.05, 1.05), 0.05)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
		_:
			tween.tween_property(sprite, "scale", Vector2(1.02, 1.02), 0.05)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _play_combo_effect():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.8, 0.2, 1), 0.1)
		tween.tween_property(sprite, "modulate", original_modulate, 0.2)

func _play_miss_effect():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.5, 0.2, 0.2, 1), 0.1)
		tween.tween_property(sprite, "modulate", original_modulate, 0.2)

func _play_hurt_animation():
	if animation_player and animation_player.has_animation("hurt"):
		animation_player.play("hurt")
		await animation_player.animation_finished
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")

func _player_death():
	if is_dead or is_game_over_handled:
		return
	
	is_dead = true
	is_game_over_handled = true
	
	print("💀 ¡", player_name, " DERROTADO! 💀")
	
	# Reproducir animación de muerte
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	
	# Guardar estadísticas
	if GameManager:
		GameManager.perfect_count_p1 = perfect_count
		GameManager.great_count_p1 = great_count
		GameManager.good_count_p1 = good_count
		GameManager.ok_count_p1 = ok_count
		GameManager.miss_count_p1 = miss_count
	
	player_died.emit(player_id)

func reset():
	_load_difficulty_config()
	current_health = max_health
	is_dead = false
	is_game_over_handled = false
	combo_count = 0
	perfect_count = 0
	great_count = 0
	good_count = 0
	ok_count = 0
	miss_count = 0
	total_score = 0
	
	_update_health_bar()
	_update_health_label()
	
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.scale = Vector2(1, 1)
	
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	print("🔄 ", player_name, " reiniciado")

func get_stats() -> Dictionary:
	return {
		"perfect": perfect_count,
		"great": great_count,
		"good": good_count,
		"ok": ok_count,
		"miss": miss_count,
		"combo": best_combo,
		"score": total_score
	}
