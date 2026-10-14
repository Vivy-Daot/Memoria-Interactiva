class_name PlatformChunk
extends Node2D

## Fragmento ("chunk") reutilizable para la generación procedural del Nivel 2.
##
## Convención de coordenadas locales de cada chunk:
##   - El punto de entrada (por donde llega el jugador) es siempre (0, 0).
##     Por eso la raíz del chunk se coloca directamente en ese punto cuando
##     el generador lo instancia; no hace falta un nodo "Entry" para calcular
##     nada, pero se deja como referencia visual/de depuración en el editor.
##   - El nodo hijo Marker2D llamado "Exit" indica en coordenadas locales
##     dónde debe empezar (pegado) el siguiente fragmento.
##
## Todas las plataformas de un chunk deben tener su superficie superior en
## y = 0 exactamente en x = 0 (entrada) y en x = Exit.position.x (salida),
## para que el suelo quede continuo entre fragmentos sin importar qué forma
## tenga el interior del chunk (huecos, escalones, islas flotantes, etc.).

@export var chunk_name: String = ""


func get_exit_offset() -> Vector2:
	var exit_marker := get_node_or_null("Exit") as Marker2D
	if exit_marker:
		return exit_marker.position
	var label: String = chunk_name if chunk_name != "" else String(name)
	push_warning("PlatformChunk '%s' no tiene un Marker2D hijo llamado 'Exit'." % [label])
	return Vector2.ZERO
