extends CharacterBody3D

@export var move_speed: float = 6.2
@export var jump_velocity: float = 5.2
@export var gravity: float = 18.0

var move_input: Vector2 = Vector2.ZERO
var camera_yaw: float = 0.0
var camera_pitch: float = -0.18
var camera_pivot: Node3D
var camera: Camera3D
var body_mesh: MeshInstance3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var walk_time := 0.0

func _ready() -> void:
	_build_character()
	_build_camera()

func _build_character() -> void:
	body_mesh = _capsule_part(0.48, 0.92, Vector3(0, 1.05, 0), Color("#2768ad"))
	add_child(body_mesh)
	var shirt := MeshInstance3D.new()
	var shirt_mesh := BoxMesh.new()
	shirt_mesh.size = Vector3(0.82, 0.68, 0.5)
	shirt.mesh = shirt_mesh
	shirt.position = Vector3(0, 1.3, 0)
	shirt.material_override = _material(Color("#347fc1"))
	add_child(shirt)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.3
	head_mesh.height = 0.62
	head.mesh = head_mesh
	head.position = Vector3(0, 2.02, 0)
	head.material_override = _material(Color("#e9b98e"))
	add_child(head)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.31
	hair_mesh.height = 0.34
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 2.25, 0.02)
	hair.material_override = _material(Color("#49352d"))
	add_child(hair)

	left_arm = _capsule_part(0.13, 0.78, Vector3(-0.52, 1.35, 0), Color("#e9b98e"))
	right_arm = _capsule_part(0.13, 0.78, Vector3(0.52, 1.35, 0), Color("#e9b98e"))
	add_child(left_arm)
	add_child(right_arm)
	left_leg = _capsule_part(0.17, 0.78, Vector3(-0.22, 0.42, 0), Color("#34445a"))
	right_leg = _capsule_part(0.17, 0.78, Vector3(0.22, 0.42, 0), Color("#34445a"))
	add_child(left_leg)
	add_child(right_leg)
	_add_shoe(Vector3(-0.22, 0.08, -0.08))
	_add_shoe(Vector3(0.22, 0.08, -0.08))

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.9
	collision.shape = shape
	collision.position.y = 0.95
	add_child(collision)

func _capsule_part(radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	part.mesh = capsule
	part.position = pos
	part.material_override = _material(color)
	return part

func _add_shoe(pos: Vector3) -> void:
	var shoe := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.38, 0.16, 0.55)
	shoe.mesh = mesh
	shoe.position = pos
	shoe.material_override = _material(Color("#242a30"))
	add_child(shoe)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.4, 6.5)
	camera.rotation = Vector3(-0.18, 0.0, 0.0)
	camera.fov = 72.0
	camera_pivot.add_child(camera)
	camera.current = true
	_update_camera()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_vector := move_input
	if keyboard.length() > input_vector.length():
		input_vector = keyboard
	var forward := Vector3(-sin(camera_yaw), 0, -cos(camera_yaw))
	var right := Vector3(-forward.z, 0, forward.x)
	var direction := (right * input_vector.x + forward * input_vector.y).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	move_and_slide()
	if direction.length() > 0.1:
		rotation.y = atan2(direction.x, direction.z)
		walk_time += delta * 9.0
		left_leg.rotation.x = sin(walk_time) * 0.55
		right_leg.rotation.x = -sin(walk_time) * 0.55
		left_arm.rotation.x = -sin(walk_time) * 0.42
		right_arm.rotation.x = sin(walk_time) * 0.42
	else:
		left_leg.rotation.x = move_toward(left_leg.rotation.x, 0.0, delta * 4.0)
		right_leg.rotation.x = move_toward(right_leg.rotation.x, 0.0, delta * 4.0)
		left_arm.rotation.x = move_toward(left_arm.rotation.x, 0.0, delta * 4.0)
		right_arm.rotation.x = move_toward(right_arm.rotation.x, 0.0, delta * 4.0)

func rotate_camera(delta_x: float, delta_y: float) -> void:
	camera_yaw -= delta_x * 0.006
	camera_pitch = clamp(camera_pitch - delta_y * 0.004, -0.65, 0.15)
	_update_camera()

func _update_camera() -> void:
	if is_instance_valid(camera_pivot):
		camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat
