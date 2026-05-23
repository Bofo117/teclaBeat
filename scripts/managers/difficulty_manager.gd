extends Node

enum Difficulty { EASY, MEDIUM, HARD, IMPOSSIBLE }

var current_difficulty: Difficulty = Difficulty.MEDIUM

# Configuración completa por dificultad
var config: Dictionary = {}

func _ready():
	_load_difficulty_config()
	
	# Conectar con GameManager si existe
	if GameManager:
	
		GameManager.game_difficulty = current_difficulty
		GameManager.difficulty_config = get_current_config().duplicate()
		GameManager.current_difficulty_name = get_difficulty_name()

func _load_difficulty_config():
	config = {
		Difficulty.EASY: {
			"name": "FÁCIL",
			"name_en": "EASY",
			"color": Color(0.2, 0.8, 0.2),
			"boss_hp": 500,
			"player_hp": 200,
			"damage_per_miss": 10,
			"base_damage_to_boss": 8,
			"base_note_speed": 1.5,      # Velocidad de caída LENTA
			"min_spawn_delay": 1.1,		#Diferencia entre spawn de flechas
			"max_spawn_delay": 3.0,		#Diferencia entre spawn de flechas
			"spawn_probability": 0.95,      # Fácil: 95% de probabilidad
			"combo_multipliers": {
				10: 1.1,
				20: 1.25,
				30: 1.5,
				50: 2.0
			},
			"description": "Vida jugador: 200 | Daño por fallo: 10 | Vida villano: 500"
		},
		Difficulty.MEDIUM: {
			"name": "MEDIO",
			"name_en": "MEDIUM",
			"color": Color(1, 0.8, 0.2),
			"boss_hp": 1000,
			"player_hp": 150,
			"damage_per_miss": 10,
			"base_damage_to_boss": 5,
			"base_note_speed": 1.7,      # Velocidad de caída NORMAL
			"min_spawn_delay": 0.5,
			"max_spawn_delay": 1.5,
			"spawn_probability": 0.90,      # Medio: 90% de probabilidad  
			"combo_multipliers": {
				10: 1.15,
				20: 1.35,
				30: 1.75,
				50: 2.5
			},
			"description": "Vida jugador: 150 | Daño por fallo: 10 | Vida villano: 1000"
		},
		Difficulty.HARD: {
			"name": "DIFÍCIL",
			"name_en": "HARD",
			"color": Color(1, 0.5, 0.2),
			"boss_hp": 1500,
			"player_hp": 100,
			"damage_per_miss": 10,
			"base_damage_to_boss": 5,
			"base_note_speed": 2.5,      # Velocidad de caída RÁPIDA
			"min_spawn_delay": 0.3,
			"max_spawn_delay": 1.0,
			"spawn_probability": 0.85,      # Difícil: 85% de probabilidad
			"combo_multipliers": {
				10: 1.2,
				20: 1.5,
				30: 2.0,
				50: 3.0
			},
			"description": "Vida jugador: 100 | Daño por fallo: 10 | Vida villano: 1500"
		},
		Difficulty.IMPOSSIBLE: {
			"name": "IMPOSIBLE",
			"name_en": "IMPOSSIBLE",
			"color": Color(1, 0.2, 0.2),
			"boss_hp": 2000,
			"player_hp": 10,
			"damage_per_miss": 10,
			"base_damage_to_boss": 5,
			"base_note_speed": 4.0,      # Velocidad de caída EXTREMA
			"min_spawn_delay": 0.2,
			"max_spawn_delay": 0.6,
			"spawn_probability": 0.80,      # Imposible: 80% de probabilidad
			"combo_multipliers": {
				10: 1.3,
				20: 1.7,
				30: 2.2,
				50: 3.5
			},
			"description": "Vida jugador: 10 | Daño por fallo: 10 | Vida villano: 2000"
		}
	}

func set_difficulty(difficulty: Difficulty):
	current_difficulty = difficulty
	
	if GameManager:
		GameManager.game_difficulty = difficulty
		GameManager.difficulty_config = get_current_config().duplicate()
		GameManager.current_difficulty_name = get_difficulty_name()
	
	print("Dificultad seleccionada: ", get_difficulty_name())

func get_current_config() -> Dictionary:
	return config[current_difficulty].duplicate()

func get_difficulty_name() -> String:
	return config[current_difficulty]["name"]

func get_difficulty_color() -> Color:
	return config[current_difficulty]["color"]

func get_boss_hp() -> int:
	return config[current_difficulty]["boss_hp"]

func get_player_hp() -> int:
	return config[current_difficulty]["player_hp"]

func get_damage_per_miss() -> int:
	return config[current_difficulty]["damage_per_miss"]

func get_base_damage_to_boss() -> int:
	return config[current_difficulty]["base_damage_to_boss"]

# NUEVO: Método que faltaba
func get_base_note_speed() -> float:
	return config[current_difficulty]["base_note_speed"]

# NUEVO: Método que faltaba
func get_spawn_delays() -> Dictionary:
	return {
		"min": config[current_difficulty]["min_spawn_delay"],
		"max": config[current_difficulty]["max_spawn_delay"]
	}

func get_combo_multiplier(combo: int) -> float:
	var multipliers = config[current_difficulty]["combo_multipliers"]
	var highest: float = 1.0
	
	for threshold in multipliers.keys():
		if combo >= threshold:
			highest = multipliers[threshold]
	
	return highest
	
func get_description() -> String:
	return config[current_difficulty]["description"]
	

func get_spawn_probability() -> float:
	return config[current_difficulty]["spawn_probability"]
