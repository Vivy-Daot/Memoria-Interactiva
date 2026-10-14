extends TargetingArrow2d

var _mouse_left_down: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_sprites()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	
	if _mouse_left_down:
		show()
		process_arrow(mouse_position)
	else: 
		hide()


func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.is_pressed():
			# Mouse left down.
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			_mouse_left_down = true
		elif event.button_index == 1 and not event.is_pressed():
			# Mouse left release.
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			_mouse_left_down = false
