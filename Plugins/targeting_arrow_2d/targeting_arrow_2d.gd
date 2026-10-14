# targeting_arrow_2d

extends Node2D
class_name TargetingArrow2d

@export_group("Textures")
@export var head_texture: Texture2D
@export var head_texture_offset: Vector2 = Vector2.ZERO
@export var nodes_texture: Texture2D
@export var nodes_texture_offset: Vector2 = Vector2.ZERO

@export_group("Curve")
@export var total_nodes: int = 20:
	set(value):
		total_nodes = value
		delete()

@export var control_point_factors_p1: Vector2 = Vector2(-0.3, 0.8)
@export var control_point_factors_p2: Vector2 = Vector2(0.1, 1.4)
@export var scale_start: float = 1.0
@export var scale_end: float = 0.3
@export var cumulative_dist_max: int = 64

@export_group("Transform")
@export var head_scale: Vector2 = Vector2.ONE
@export var nodes_scale: Vector2 = Vector2.ONE

@export_group("Ordering")
@export var head_z_index: int = 1
@export var nodes_z_index: int = 0

var _nodes: Array = []


func load_sprites() -> void:
	for i in range(total_nodes):
		var sprite = Sprite2D.new()

		if i == 0: # Head node
			sprite.texture = head_texture
			sprite.scale = head_scale
			sprite.z_index = head_z_index
		else:  # Nodes
			sprite.texture = nodes_texture
			sprite.scale = nodes_scale
			sprite.z_index = nodes_z_index
	
		sprite.position = Vector2(0, 0)
		add_child(sprite)
		_nodes.append(sprite)
	
	
func process_arrow(target_position: Vector2) -> void:
	if _nodes.is_empty():
		load_sprites()
		
	var bezier_positions: Array = _compute_bezier_positions(target_position)
	
	for i in range(total_nodes):
		if _nodes[i] == null:
			continue
		
		var t_scale := float(i) / float(total_nodes - 1)
		_apply_node_xform(i, bezier_positions, t_scale)
		
		
func _compute_bezier_positions(target_position) -> Array:
	var p0: Vector2 = global_position
	var p3: Vector2 = target_position
	var p1: Vector2 = p0 + (p3 - p0) * control_point_factors_p1
	var p2: Vector2 = p0 + (p3 - p0) * control_point_factors_p2
	
	var bezier_positions: Array[Vector2] = []
	
	for i in range(total_nodes):
		var t: float = 1.0 - float(i) / float(total_nodes - 1)
		var bx: float = pow(1-t,3)*p0.x + 3*pow(1-t,2)*t*p1.x + 3*(1-t)*pow(t,2)*p2.x + pow(t,3)*p3.x
		var by: float = pow(1-t,3)*p0.y + 3*pow(1-t,2)*t*p1.y + 3*(1-t)*pow(t,2)*p2.y + pow(t,3)*p3.y
		bezier_positions.append(Vector2(bx, by))
	
	return bezier_positions
	
	
func _apply_node_xform(i: int, bezier_positions: Array, t_scale: float):
	var scale_factor := lerp(scale_start, scale_end, t_scale)
	
	if i == 0 and total_nodes == 1: # Head only
		_nodes[i].visible = false
		return
		
	elif i == 0 and total_nodes > 1: # Head
		_nodes[i].visible = true
		var dir: Vector2 = bezier_positions[1] - bezier_positions[0]
		var head_angle: float = signed_angle(Vector2.DOWN, dir)

		var rotation: float = deg_to_rad(head_angle)
		var rotated_offset: Vector2 = head_texture_offset.rotated(rotation)

		_nodes[i].scale = head_scale * scale_factor
		var node_scale: Vector2 = _nodes[i].scale
		var skew: float = 0.0
		var position: Vector2 = bezier_positions[0] - rotated_offset * node_scale
		var new_transform := Transform2D(rotation, node_scale, skew, position)
		_nodes[i].global_transform = new_transform

	else: # Nodes
		var dir: Vector2 = bezier_positions[i] - bezier_positions[i - 1]
		var angle: float = signed_angle(Vector2.DOWN, dir)

		var cumulative_dist: float = 0.0
		for j in range(1, i + 1):
			cumulative_dist += bezier_positions[j].distance_to(bezier_positions[j - 1])

		if cumulative_dist < cumulative_dist_max:
			_nodes[i].visible = false
		else:
			_nodes[i].visible = true

			var rotation: float = deg_to_rad(angle)

			_nodes[i].scale = nodes_scale * scale_factor
			var node_scale: Vector2 = _nodes[i].scale
			var skew: float = 0.0
			var position: Vector2 = bezier_positions[i]
			var new_transform := Transform2D(rotation, node_scale, skew, position)
			_nodes[i].global_transform = new_transform
			
			
func delete() -> void:
	for sprite in _nodes:
		if is_instance_valid(sprite):
			sprite.queue_free()
		
	_nodes.clear()
	
	
func signed_angle(v1: Vector2, v2: Vector2) -> float:
	return rad_to_deg(v1.angle_to(v2))
