extends Control

## Joystick flotante para pantallas táctiles.
##
## Cuando el jugador toca CUALQUIER punto de la pantalla que no esté ocupado por
## otro elemento de interfaz (botones Correr/Saltar/Impulso/Pausa, barras o
## minimapa), el joystick aparece centrado en ese punto y se controla arrastrando
## el dedo desde ahí. Al soltar, vuelve a su posición de reposo (abajo a la
## izquierda) para seguir sirviendo de guía visual.

const RADIUS = 80.0

## Índice del dedo (touch index) que controla el joystick, o -1 si ninguno.
var touch_index := -1
## Centro del joystick en reposo (posición definida en la escena). Al soltar, el
## joystick vuelve aquí. Guardado porque el nodo se recoloca en cada toque.
var _home_center := Vector2.ZERO

@onready var base: ColorRect = $Base
@onready var knob: ColorRect = $Knob

func _ready() -> void:
	_home_center = base.position + base.size / 2.0
	_reset_knob()

## Si se cambia de escena mientras el dedo sigue sobre el joystick, el evento de
## "soltar" nunca llega a este nodo. Sin liberar aquí las acciones, quedarían
## presionadas y el personaje seguiría moviéndose solo en la nueva escena.
func _exit_tree() -> void:
	_release_all_actions()

## Si la app pierde el foco (p. ej. el jugador cambia de aplicación en el móvil)
## también se pierde el evento de "soltar", así que liberamos igualmente las
## acciones para que el personaje no quede moviéndose solo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_deactivate()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Solo arranca el joystick si el toque no cae sobre otro elemento de
			# interfaz. Así el jugador puede empezar a mover al personaje en
			# cualquier parte libre de la pantalla.
			if touch_index == -1 and not _touches_ui(event.position):
				_activate(event.index, event.position)
		elif event.index == touch_index:
			_deactivate()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_from_touch(event.position)

## Coloca el joystick centrado en el punto tocado y empieza a seguirlo.
func _activate(index: int, pos: Vector2) -> void:
	touch_index = index
	base.position = pos - base.size / 2.0
	_reset_knob()
	# Un toque sin arrastre deja el vector a cero (libera las acciones).
	_update_from_touch(pos)

## Suelta el joystick, lo devuelve a su sitio y libera las direcciones.
func _deactivate() -> void:
	touch_index = -1
	base.position = _home_center - base.size / 2.0
	_reset_knob()
	_release_all_actions()

## Calcula el vector de movimiento a partir de la posición del dedo respecto al
## centro actual del joystick y actualiza el knob y las acciones.
func _update_from_touch(pos: Vector2) -> void:
	var center := base.position + base.size / 2.0
	var offset := pos - center
	if offset.length() > RADIUS:
		offset = offset.normalized() * RADIUS
	knob.position = center - knob.size / 2.0 + offset
	_update_actions(offset / RADIUS)

## ¿El punto cae sobre algún elemento de interfaz que no sea el propio joystick?
## Se recorre a los hermanos dentro del CanvasLayer: los TouchScreenButton (área =
## su textura) y los Control visibles que aceptan mouse (barras, minimapa...).
func _touches_ui(pos: Vector2) -> bool:
	var parent := get_parent()
	if parent == null:
		return false
	for sibling in parent.get_children():
		if sibling == self or not (sibling is CanvasItem):
			continue
		if not sibling.visible:
			continue
		if sibling is TouchScreenButton:
			if _point_in_button(sibling, pos):
				return true
		elif sibling is Control and sibling.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			if sibling.get_global_rect().has_point(pos):
				return true
	return false

## Área de un TouchScreenButton: si no tiene una forma propia, su zona activa es
## el rectángulo de su textura normal, escalado por su escala de nodo.
func _point_in_button(btn: TouchScreenButton, pos: Vector2) -> bool:
	var texture: Texture2D = btn.texture_normal
	if texture == null:
		return false
	var button_size := Vector2(texture.get_size()) * btn.scale
	return Rect2(btn.position, button_size).has_point(pos)

func _reset_knob() -> void:
	var center := base.position + base.size / 2.0
	knob.position = center - knob.size / 2.0

func _update_actions(vector: Vector2) -> void:
	_set_action("Left",  vector.x < -0.2)
	_set_action("Right", vector.x >  0.2)
	_set_action("Up",    vector.y < -0.2)
	_set_action("Down",  vector.y >  0.2)

func _release_all_actions() -> void:
	_set_action("Left",  false)
	_set_action("Right", false)
	_set_action("Up",    false)
	_set_action("Down",  false)

func _set_action(action: String, pressed: bool) -> void:
	if Input.is_action_pressed(action) != pressed:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
