extends Node

# Señales existentes
signal IncrementScore(incr: int)
signal IncrementCombo()
signal ResetCombo()
signal CreateFallingKey(button_name: String)
signal KeyListenerPress(button_name: String, array_num: int)
signal DinoKeyPressed(key_name: String)

# Señales para 2 jugadores
signal Player1_add_score(incr: int)
signal Player1_increment_combo()
signal Player1_reset_combo()
signal Player2_add_score(incr: int)
signal Player2_increment_combo()
signal Player2_reset_combo()
signal LastKeyPressed(key_name: String)

# Señales de control del juego
signal PlayerDamage(amount: int)
signal GameOver()
signal GameRestart()

# Señales de aciertos para el villano 
signal Player1_note_hit(score_value: int) 
signal Player2_note_hit(score_value: int) 


# Daño específico por jugador
signal Player1Damage(amount: int)
signal Player2Damage(amount: int)

# Victoria en modo 2 jugadores
signal VictoryAchieved()
