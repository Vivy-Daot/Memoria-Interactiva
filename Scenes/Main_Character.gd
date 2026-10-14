extends CharacterBody2D
const SPEED = 300.0
const RUN_MULTIPLIER = 1.6
## Aceleración/frenado horizontal (px/s²). Evitan que el personaje cambie de
## velocidad de golpe: al soltar "Correr" no frena al instante y, sobre todo,
## conserva el impulso en el aire para que un salto corriendo llegue más lejos.
const GROUND_ACCEL = 2600.0
const GROUND_DECEL = 3200.0
const AIR_ACCEL = 1400.0
const AIR_DRAG = 220.0
## Multiplicador de velocidad cuando la stamina está agotada (20% más lento).
const NO_STAMINA_SPEED_MULTIPLIER = 0.8
const DASH_SPEED = 900.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.6
const MAX_HEALTH = 100.0
const MAX_STAMINA = 100.0
const STAMINA_DRAIN_RATE = 25.0
const STAMINA_DASH_COST = 20.0
const STAMINA_REGEN_RATE = 15.0

## Respiración en reposo: mientras el personaje está quieto, el sprite se
## estira/encoge y sube/baja (hombros) para simular que respira. Los sprites de
## idle son fotogramas casi idénticos, así que el movimiento se genera por código.
const BREATH_PERIOD = 3.0
const BREATH_SCALE_AMPLITUDE = 0.08
## Desplazamiento vertical del "encogimiento de hombros" (en píxeles de sprite,
## se multiplica por la escala del nodo). Positivo = sube al inhalar / baja al exhalar.
const BREATH_MOVE_AMPLITUDE = 2.0

## Modo de movimiento del personaje.
## TOP_DOWN: comportamiento original (BaseLevel) -> se mueve libre en 4 direcciones, sin gravedad.
## PLATFORMER: comportamiento de plataformas 2D (SegundoNivel) -> solo izquierda/derecha + gravedad + salto real.
enum MovementMode { TOP_DOWN, PLATFORMER }
@export var movement_mode: MovementMode = MovementMode.TOP_DOWN

## Solo se usan en modo PLATFORMER
const GRAVITY = 980.0
const JUMP_VELOCITY = -400.0

signal health_changed(current, max_value)
signal stamina_changed(current, max_value)

@onready var C = $Sprite2D
var direction_facing = "down"
var last_direction = Vector2.DOWN

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0

var health = MAX_HEALTH
var stamina = MAX_STAMINA

## Fase de la respiración (arranca en el punto más bajo para entrar suave).
var _breathe_time = -PI / 2.0
## Escala original del sprite, para volver a ella al caminar.
var _sprite_base_scale = Vector2.ONE
## Offset original del sprite (origen de la respiración vertical).
var _sprite_base_offset = Vector2.ZERO

func _ready():
	health_changed.emit(health, MAX_HEALTH)
	stamina_changed.emit(stamina, MAX_STAMINA)
	_sprite_base_scale = C.scale
	_sprite_base_offset = C.offset

func _physics_process(delta):
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	handle_stamina(delta)

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			if movement_mode == MovementMode.PLATFORMER:
				# El dash no arrastra su exceso de velocidad a la inercia nueva:
				# al terminar, la velocidad vuelve de golpe al valor normal, como
				# antes de añadir la aceleración/frenado.
				velocity.x = Input.get_axis("Left", "Right") * _get_move_speed()
		if movement_mode == MovementMode.PLATFORMER and not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		update_animation()
		return

	match movement_mode:
		MovementMode.PLATFORMER:
			process_movement_platformer(delta)
		_:
			process_movement()
			handle_jump()

	handle_dash()
	update_animation()

func process_movement() -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	var speed := _get_move_speed()

	velocity = direction * speed
	move_and_slide()

	if direction.length() > 0:
		last_direction = direction

	if direction.x > 0:
		direction_facing = "right"
	elif direction.x < 0:
		direction_facing = "left"
	elif direction.y > 0:
		direction_facing = "down"
	elif direction.y < 0:
		direction_facing = "up"

func process_movement_platformer(delta: float) -> void:
	var input_dir := Input.get_axis("Left", "Right")
	var on_floor := is_on_floor()

	if on_floor:
		# En el suelo se acelerá/frena suavemente hacia la velocidad objetivo.
		var target := input_dir * _get_move_speed()
		if input_dir != 0.0:
			velocity.x = move_toward(velocity.x, target, GROUND_ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, GROUND_DECEL * delta)
	else:
		# En el aire se conserva el impulso ya adquirido, pero NO se puede ganar
		# velocidad nueva: el tope de control es la velocidad de caminar (correr
		# solo sirve en el suelo). Así un salto corriendo llega más lejos aunque
		# se suelte "Correr", y pulsar "Correr" en pleno salto no acelera.
		var target := input_dir * _get_air_control_speed()
		if input_dir == 0.0:
			velocity.x = move_toward(velocity.x, 0.0, AIR_DRAG * delta)
		elif absf(target) > absf(velocity.x) or signf(target) != signf(velocity.x):
			velocity.x = move_toward(velocity.x, target, AIR_ACCEL * delta)

	if not on_floor:
		velocity.y += GRAVITY * delta
	elif velocity.y > 0:
		velocity.y = 0

	if Input.is_action_just_pressed("Saltar") and is_on_floor() and stamina > 0.0:
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	if input_dir != 0:
		last_direction = Vector2(input_dir, 0)
		direction_facing = "right" if input_dir > 0 else "left"

## Velocidad de movimiento actual: correr gasta stamina, pero sin stamina el
## jugador ni corre ni mantiene el ritmo normal (se mueve un 20% más lento).
func _get_move_speed() -> float:
	if stamina <= 0.0:
		return SPEED * NO_STAMINA_SPEED_MULTIPLIER
	if Input.is_action_pressed("Recorrido"):
		return SPEED * RUN_MULTIPLIER
	return SPEED


## Velocidad máxima a la que se puede acelerar EN EL AIRE. Ignora "Correr": no se
## debe poder ganar velocidad (ni la de correr) en pleno salto, eso es lo que da
## el botón "Impulso" (Dash). El impulso ya adquirido antes de saltar sí se
## conserva (ver process_movement_platformer).
func _get_air_control_speed() -> float:
	if stamina <= 0.0:
		return SPEED * NO_STAMINA_SPEED_MULTIPLIER
	return SPEED


func handle_jump() -> void:
	if Input.is_action_just_pressed("Saltar") and stamina > 0.0:
		# Top-down: no hay gravedad real, así que el "salto" es un efecto visual
		var tween = create_tween()
		tween.tween_property(C, "position:y", C.position.y - 12, 0.1)
		tween.tween_property(C, "position:y", C.position.y, 0.1)

func handle_dash() -> void:
	if Input.is_action_just_pressed("Dash") and dash_cooldown_timer <= 0.0 and stamina >= STAMINA_DASH_COST:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		if movement_mode == MovementMode.PLATFORMER:
			velocity = Vector2(last_direction.x * DASH_SPEED, velocity.y)
		else:
			velocity = last_direction * DASH_SPEED
		change_stamina(-STAMINA_DASH_COST)

func handle_stamina(delta) -> void:
	var wants_run := Input.is_action_pressed("Recorrido")
	if wants_run and stamina > 0.0:
		change_stamina(-STAMINA_DRAIN_RATE * delta)
	elif not wants_run:
		# Se recupera solo si no se está intentando correr: mantener "Correr" con
		# la stamina agotada la deja en 0 (no alterna correr/andar cada frame).
		change_stamina(STAMINA_REGEN_RATE * delta)

func change_stamina(amount: float) -> void:
	stamina = clamp(stamina + amount, 0.0, MAX_STAMINA)
	stamina_changed.emit(stamina, MAX_STAMINA)

func change_health(amount: float) -> void:
	health = clamp(health + amount, 0.0, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)

func get_max_health() -> float:
	return MAX_HEALTH

func get_max_stamina() -> float:
	return MAX_STAMINA

func take_damage(amount: float) -> void:
	change_health(-amount)

func heal(amount: float) -> void:
	change_health(amount)

func update_animation() -> void:
	var moving: bool
	if movement_mode == MovementMode.PLATFORMER:
		moving = abs(velocity.x) > 1
	else:
		moving = velocity.length() > 1

	var anim = ("walk_" if moving else "idle_") + direction_facing

	if C.animation != anim:
		C.play(anim)

	if moving:
		# Al moverse se cancela la respiración y se recupera la escala original.
		_breathe_time = -PI / 2.0
		C.scale = _sprite_base_scale
		C.offset = _sprite_base_offset
	else:
		_update_breathing()

## Estira el sprite (más alto y un poco más estrecho) y lo sube/baja siguiendo
## una onda suave: el pecho se llena y sube, y al exhalar se encoge y baja.
func _update_breathing() -> void:
	_breathe_time += get_physics_process_delta_time() * TAU / BREATH_PERIOD
	var wave: float = sin(_breathe_time)          # -1 (exhala) .. 1 (inhala)
	var inflate: float = wave * 0.5 + 0.5          # 0 .. 1
	C.scale = Vector2(
		_sprite_base_scale.x * (1.0 - BREATH_SCALE_AMPLITUDE * inflate),
		_sprite_base_scale.y * (1.0 + BREATH_SCALE_AMPLITUDE * inflate)
	)
	C.offset = Vector2(
		_sprite_base_offset.x,
		_sprite_base_offset.y - BREATH_MOVE_AMPLITUDE * wave
	)

