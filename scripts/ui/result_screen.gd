extends Panel

const API_URL = "https://rhythm-cps0.onrender.com/api"

# Referencias a nodos
@onready var continue_button = $ContinueButton if has_node("ContinueButton") else null
@onready var message_label = $MessageLabel if has_node("MessageLabel") else null

# Labels
var result_label: Label
var combo_label: Label
var time_label: Label
var boss_hp_label: Label
var player_hp_label: Label
var perfect_label: Label
var great_label: Label
var good_label: Label
var ok_label: Label
var miss_label: Label
var accuracy_label: Label
var difficulty_label: Label

var game_data: Dictionary = {}
var is_logged_in: bool = false

func _ready():
	print("=== RESULT SCREEN ===")
	_create_interface()
	_connect_buttons()
	load_results()
	show_animation()

func _create_interface():
	modulate = Color(0, 0, 0, 0.85)
	
	var panel = Panel.new()
	panel.name = "CenterPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 560)
	panel.position = Vector2(-260, -280)
	add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.6, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	
	var title = Label.new()
	title.text = "RESULTADOS"
	title.position = Vector2(160, 20)
	title.size = Vector2(200, 50)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	
	result_label = _create_label(panel, "Resultado", Vector2(160, 80), 36)
	difficulty_label = _create_label(panel, "Dificultad", Vector2(60, 130), 18)
	combo_label = _create_label(panel, "Combo", Vector2(60, 165), 24)
	combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	time_label = _create_label(panel, "Tiempo", Vector2(60, 200), 18)
	boss_hp_label = _create_label(panel, "BossHP", Vector2(60, 235), 16)
	player_hp_label = _create_label(panel, "PlayerHP", Vector2(60, 265), 16)
	
	var separator = HSeparator.new()
	separator.position = Vector2(20, 295)
	separator.size = Vector2(480, 10)
	panel.add_child(separator)
	
	var hits_title = Label.new()
	hits_title.text = "PRECISION"
	hits_title.position = Vector2(160, 310)
	hits_title.size = Vector2(200, 30)
	hits_title.add_theme_font_size_override("font_size", 20)
	hits_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	hits_title.add_theme_constant_override("outline_size", 4)
	hits_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hits_title)
	
	perfect_label = _create_label(panel, "Perfect", Vector2(90, 345), 16)
	great_label = _create_label(panel, "Great", Vector2(210, 345), 16)
	good_label = _create_label(panel, "Good", Vector2(330, 345), 16)
	ok_label = _create_label(panel, "Ok", Vector2(90, 375), 16)
	miss_label = _create_label(panel, "Miss", Vector2(210, 375), 16)
	accuracy_label = _create_label(panel, "Accuracy", Vector2(330, 375), 16)
	
	perfect_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	great_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	good_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
	ok_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	miss_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	accuracy_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1))
	
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "CONTINUAR"
	continue_button.position = Vector2(160, 430)
	continue_button.size = Vector2(200, 45)
	panel.add_child(continue_button)
	
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.position = Vector2(160, 490)
	message_label.size = Vector2(200, 25)
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(message_label)

func _create_label(parent: Node, name: String, position: Vector2, font_size: int) -> Label:
	var label = Label.new()
	label.name = name
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label

func _connect_buttons():
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func load_results():
	print("=== LOADING RESULTS ===")
	
	if not GameManager:
		_show_message("Error: GameManager not found", Color.RED)
		return
	
	is_logged_in = GameManager.is_logged_in() if GameManager.has_method("is_logged_in") else false
	
	game_data = {
		"victory": GameManager.game_completed,
		"max_combo": GameManager.max_combo_achieved,
		"difficulty": GameManager.current_difficulty_name,
		"time": GameManager.time_to_complete,
		"boss_hp_remaining": GameManager.final_boss_hp_remaining,
		"player_hp_remaining": GameManager.final_player_hp_remaining,
		"perfect": GameManager.perfect_count,
		"great": GameManager.great_count,
		"good": GameManager.good_count,
		"ok": GameManager.ok_count,
		"miss": GameManager.miss_count,
		"total_notes": GameManager.total_notes_hit,
		"song": GameManager.current_song_name
	}
	
	print("Victory: ", game_data["victory"])
	print("Max Combo: ", game_data["max_combo"])
	print("Time: ", game_data["time"])
	
	_display_results()
	
	if is_logged_in:
		_save_game_to_server()
	else:
		if message_label:
			message_label.text = "LOGIN TO SAVE YOUR SCORES"
			message_label.add_theme_color_override("font_color", Color.YELLOW)

func _display_results():
	if result_label:
		if game_data["victory"]:
			result_label.text = "VICTORY!"
			result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		else:
			result_label.text = "DEFEAT"
			result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	
	if difficulty_label:
		difficulty_label.text = "Difficulty: " + game_data["difficulty"]
	
	if combo_label:
		combo_label.text = "Best Combo: x" + str(game_data["max_combo"])
	
	if time_label:
		var minutes = floor(game_data["time"] / 60)
		var seconds = int(game_data["time"]) % 60
		time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	if boss_hp_label:
		var boss_max = _get_boss_max_hp()
		if game_data["boss_hp_remaining"] > 0:
			var percent = (float(game_data["boss_hp_remaining"]) / boss_max) * 100
			boss_hp_label.text = "Boss: %d/%d HP (%.0f%%)" % [game_data["boss_hp_remaining"], boss_max, percent]
		else:
			boss_hp_label.text = "Boss: DEFEATED!"
			boss_hp_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	
	if player_hp_label:
		var player_max = _get_player_max_hp()
		var percent = (float(game_data["player_hp_remaining"]) / player_max) * 100
		player_hp_label.text = "Player: %d/%d HP (%.0f%%)" % [game_data["player_hp_remaining"], player_max, percent]
	
	if perfect_label:
		perfect_label.text = "PERFECT: %d" % game_data["perfect"]
	if great_label:
		great_label.text = "GREAT: %d" % game_data["great"]
	if good_label:
		good_label.text = "GOOD: %d" % game_data["good"]
	if ok_label:
		ok_label.text = "OK: %d" % game_data["ok"]
	if miss_label:
		miss_label.text = "MISS: %d" % game_data["miss"]
	
	if accuracy_label:
		var total_hits = game_data["perfect"] + game_data["great"] + game_data["good"] + game_data["ok"]
		var accuracy = 0.0
		if total_hits > 0:
			accuracy = (total_hits * 100.0) / (total_hits + game_data["miss"])
		accuracy_label.text = "Accuracy: %.1f%%" % accuracy

func _save_game_to_server():
	var username = GameManager.current_user if GameManager else ""
	if username == "" or username == "INVITADO":
		return
	
	_show_message("Saving game data...", Color.YELLOW)
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var body_data = {
		"username": username,
		"song": game_data["song"],
		"combo": game_data["max_combo"],
		"victory": game_data["victory"],
		"time": game_data["time"],
		"difficulty": game_data["difficulty"],
		"perfect": game_data["perfect"],
		"great": game_data["great"],
		"good": game_data["good"],
		"ok": game_data["ok"],
		"miss": game_data["miss"],
		"boss_hp_remaining": game_data["boss_hp_remaining"],
		"player_hp_remaining": game_data["player_hp_remaining"],
		"date": Time.get_datetime_string_from_system()
	}
	
	var body = JSON.stringify(body_data)
	var headers = ["Content-Type: application/json"]
	
	http.request(API_URL + "/save_game_complete", headers, HTTPClient.METHOD_POST, body)
	http.request_completed.connect(_on_save_response.bind(http))

func _on_save_response(result, code, headers, body, http):
	http.queue_free()
	
	if code == 200:
		_show_message("Game saved successfully!", Color.GREEN)
	else:
		_show_message("Error saving game data", Color.RED)
		print("Save error code: ", code)

func _get_boss_max_hp() -> int:
	if DifficultyManager:
		return DifficultyManager.get_boss_hp()
	return 100

func _get_player_max_hp() -> int:
	if DifficultyManager:
		return DifficultyManager.get_player_hp()
	return 100

func _show_message(text: String, color: Color):
	if message_label:
		message_label.text = text
		message_label.add_theme_color_override("font_color", color)
		await get_tree().create_timer(3.0).timeout
		if message_label and message_label.text == text:
			if not is_logged_in:
				message_label.text = "LOGIN TO SAVE YOUR SCORES"
			else:
				message_label.text = ""

func show_animation():
	scale = Vector2(0.8, 0.8)
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_continue_pressed():
	if GameManager:
		GameManager.reset_game_data()
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
