class_name GameState
extends RefCounted

## Estado global de la partida. Las variables estáticas persisten entre cambios
## de escena (todo el tiempo que el juego está abierto) y se reinician al
## cerrarlo. Guarda el progreso necesario para la condición de victoria.

## Recorridos ("runs") completados en esta sesión. Se incrementa cada vez que el
## jugador termina el Nivel 2 (llega a la "Salida").
static var runs_completed: int = 0

## Recorridos necesarios para ganar.
const RUNS_TO_WIN: int = 3


static func reset() -> void:
	runs_completed = 0