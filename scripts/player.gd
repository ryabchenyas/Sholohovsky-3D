extends CharacterBody3D

@export var move_speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var gravity: float = 18.0

var move_input: Vector2 = Vector2.ZERO
var camera_yaw: float = 0.0
var camera_pitch: float = -0.18
var camera_pivot: Node3D
var camera: Camera3D

func _ready() -> void:
	_build_character()
	_build_camera()

func _build_character() -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	body.mesh = capsule
	body.position.y = 0.95
	body.material_override = _material(Color(0.12, 0.38, 0.82))
	add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.29
	head_mesh.height = 0.58
	head.mesh = head_mesh
	head.position = Vector3(0, 1.98, 0)
	head.material_override = _material(Color(0.92, 0.68, 0.48))
	add_child(head)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.92
	add_child(collision)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.4, 6.5)
	camera.current = true
	camera_pivot.add_child(camera)
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
	var forward := Vector3(sin(camera_yaw), 0, cos(camera_yaw))
	var right := Vector3(forward.z, 0, -forward.x)
	var direction := (right * input_vector.x + forward * input_vector.y).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	move_and_slide()
	if direction.length() > 0.1:
		rotation.y = atan2(direction.x, direction.z)

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
	mat.roughness = 0.9
	return mat
