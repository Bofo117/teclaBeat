# scripts/managers/database.gd
extends Node

const SAVE_FILE_PATH = "user://scores.json"
var scores: Array = []

func _ready():
	load_scores()

func load_scores():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		scores = []
		save_scores()
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var result = json.parse(content)
	
	if result == OK:
		scores = json.data
		print("Cargados ", scores.size(), " scores")
	else:
		scores = []

func save_scores():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(scores, "\t")
	file.store_string(json_string)
	file.close()

# Normalizar nombre: mayúsculas y sin espacios
func normalize_name(name: String) -> String:
	var normalized = name.strip_edges().to_upper()
	if normalized.length() > 5:
		normalized = normalized.substr(0, 5)
	return normalized

# Normalizar nombre de canción
func normalize_song_name(song_name: String) -> String:
	match song_name:
		"RHYTHM_HELL":
			return "Rhythm Hell"
		_:
			var words = song_name.split("_")
			var readable = ""
			for w in words:
				readable += w.capitalize() + " "
			return readable.strip_edges()

# Verificar si un nombre ya existe en la base de datos
func name_exists(player_name: String) -> bool:
	var normalized_name = normalize_name(player_name)
	for entry in scores:
		if entry["name"] == normalized_name:
			return true
	return false

# Verificar si un nombre ya existe para una canción específica
func name_exists_for_song(player_name: String, song_name: String) -> bool:
	var normalized_name = normalize_name(player_name)
	var normalized_song = normalize_song_name(song_name)
	for entry in scores:
		if entry["name"] == normalized_name and entry["song"] == normalized_song:
			return true
	return false

# Agregar score solo si el nombre no existe
func add_score_if_name_available(player_name: String, score: int, best_combo: int, song_name: String, player_id: int = 1) -> bool:
	var normalized_name = normalize_name(player_name)
	var normalized_song = normalize_song_name(song_name)
	
	# Verificar si el nombre ya existe
	if name_exists(normalized_name):
		print("Nombre ", normalized_name, " ya existe en la base de datos")
		return false
	
	var new_entry = {
		"name": normalized_name,
		"score": score,
		"combo": best_combo,
		"song": normalized_song,
		"player": player_id,
		"date": Time.get_datetime_string_from_system()
	}
	
	scores.append(new_entry)
	sort_scores()
	save_scores()
	print("Nuevo score guardado: ", normalized_name, " - ", score, " pts")
	return true

# Agregar o actualizar score (permite sobrescribir si es mejor puntaje)
func add_or_update_score(player_name: String, score: int, best_combo: int, song_name: String, player_id: int = 1):
	var normalized_name = normalize_name(player_name)
	var normalized_song = normalize_song_name(song_name)
	
	# Buscar si ya existe un score del mismo jugador en la misma canción
	var existing_index = -1
	for i in range(scores.size()):
		if scores[i]["name"] == normalized_name and scores[i]["song"] == normalized_song:
			existing_index = i
			break
	
	var new_entry = {
		"name": normalized_name,
		"score": score,
		"combo": best_combo,
		"song": normalized_song,
		"player": player_id,
		"date": Time.get_datetime_string_from_system()
	}
	
	if existing_index != -1:
		# Si el nuevo score es mayor, actualizar
		if score > scores[existing_index]["score"]:
			scores[existing_index] = new_entry
			print("Actualizado score de ", normalized_name, ": ", score, " pts")
		else:
			print("Score no supera el récord anterior de ", normalized_name)
	else:
		scores.append(new_entry)
		print("Nuevo score guardado: ", normalized_name, " - ", score, " pts")
	
	sort_scores()
	save_scores()

func sort_scores():
	scores.sort_custom(func(a, b): return a["score"] > b["score"])

func get_top_scores(limit: int = 10) -> Array:
	var top = scores.duplicate()
	if top.size() > limit:
		top = top.slice(0, limit)
	return top

func get_all_scores() -> Array:
	return scores

func get_best_score_by_player(player_name: String) -> Dictionary:
	var normalized_name = normalize_name(player_name)
	var best = {"score": 0}
	for entry in scores:
		if entry["name"] == normalized_name and entry["score"] > best["score"]:
			best = entry
	return best

func clear_all_scores():
	scores = []
	save_scores()
	print("Todos los scores han sido eliminados")

func get_player_scores(player_name: String) -> Array:
	var normalized_name = normalize_name(player_name)
	var result = []
	for entry in scores:
		if entry["name"] == normalized_name:
			result.append(entry)
	return result
