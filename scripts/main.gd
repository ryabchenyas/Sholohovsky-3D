extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")

var player: CharacterBody3D
var joystick_origin := Vector2.ZERO
var joystick_touch := -1
var look_touch := -1
var last_look_position := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var district_label: Label

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()

func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	world_environment.environment = env
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.15
	add_child(sun)

	_add_box(Vector3(0, -0.35, 0), Vector3(150, 0.5, 150), Color(0.28, 0.52, 0.25), true)
	_add_box(Vector3(0, -0.06, 0), Vector3(12, 0.12, 118), Color(0.16, 0.17, 0.19), true)
	_add_box(Vector3(0, 0.01, 0), Vector3(0.18, 0.03, 118), Color(0.92, 0.83, 0.46), false)

	for z in [-42.0, -20.0, 20.0, 42.0]:
		_add_box(Vector3(0, -0.01, z), Vector3(76, 0.12, 7), Color(0.22, 0.23, 0.24), true)

	_add_district(-1, Color(0.78, 0.55, 0.35), Color(0.82, 0.73, 0.55))
	_add_district(1, Color(0.66, 0.72, 0.82), Color(0.78, 0.64, 0.48))
	_add_sign("ЦЕНТР", Vector3(-12, 0, -8), Color(0.12, 0.35, 0.72))
	_add_sign("ДИЕТКА", Vector3(12, 0, 8), Color(0.16, 0.52, 0.3))

func _add_district(side: int, wall_color: Color, roof_color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + side
	for row in range(4):
		for col in range(4):
			var x := -18.0 - float(col) * 12.0 if side == -1 else 18.0 + float(col) * 12.0
			var z := (float(row) - 1.5) * 20.0 + (6.0 if side == 1 else -6.0)
			var width := rng.randf_range(6.0, 9.0)
			var depth := rng.randf_range(6.0, 9.0)
			var height := rng.randf_range(5.0, 13.0)
			var building_color := wall_color.lerp(Color(0.92, 0.86, 0.72), rng.randf() * 0.35)
			_add_box(Vector3(x, height * 0.5, z), Vector3(width, height, depth), building_color, true)
			_add_box(Vector3(x, height + 0.18, z), Vector3(width + 0.4, 0.35, depth + 0.4), roof_color, false)
			for floor_index in range(1, int(height / 2.8)):
				_add_box(Vector3(x, float(floor_index) * 2.6, z + depth * 0.5 + 0.025), Vector3(width * 0.58, 0.85, 0.06), Color(0.2, 0.38, 0.5), false)

func _add_sign(text_value: String, pos: Vector3, color: Color) -> void:
	_add_box(pos + Vector3(0, 1.25, 0), Vector3(0.18, 2.5, 0.18), Color(0.25, 0.25, 0.25), true)
	_add_box(pos + Vector3(0, 2.45, 0), Vector3(4.8, 1.0, 0.22), color, true)
	var label := Label3D.new()
	label.text = text_value
	label.font_size = 48
	label.pixel_size = 0.012
	label.position = pos + Vector3(0, 2.28, 0.14)
	add_child(label)

func _add_box(pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	add_child(body)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 0.2, -12)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(280, 72)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	district_label = Label.new()
	district_label.text = "ШОЛОХОВСКИЙ  •  ЦЕНТР"
	district_label.add_theme_font_size_override("font_size", 19)
	column.add_child(district_label)
	var info := Label.new()
	info.text = "Добро пожаловать! Исследуй город."
	column.add_child(info)

	var hint := Label.new()
	hint.text = "Слева — движение   •   Справа — обзор камеры"
	hint.anchor_left = 0.5
	hint.anchor_top = 1.0
	hint.anchor_right = 0.5
	hint.anchor_bottom = 1.0
	hint.offset_left = -250
	hint.offset_top = -44
	hint.offset_right = 250
	hint.offset_bottom = -12
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(hint)

	var jump_button := Button.new()
	jump_button.text = "ПРЫЖОК"
	jump_button.custom_minimum_size = Vector2(112, 64)
	jump_button.anchor_left = 1.0
	jump_button.anchor_top = 1.0
	jump_button.anchor_right = 1.0
	jump_button.anchor_bottom = 1.0
	jump_button.offset_left = -142
	jump_button.offset_top = -108
	jump_button.offset_right = -24
	jump_button.offset_bottom = -34
	jump_button.pressed.connect(_jump)
	layer.add_child(jump_button)

func _jump() -> void:
	if player and player.is_on_floor():
		player.velocity.y = player.jump_velocity

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.48 and joystick_touch == -1:
				joystick_touch = event.index
				joystick_origin = event.position
			else:
				look_touch = event.index
				last_look_position = event.position
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				joystick_vector = Vector2.ZERO
				if player:
					player.move_input = Vector2.ZERO
			if event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			joystick_vector = ((event.position - joystick_origin) / 70.0).limit_length(1.0)
			if player:
				player.move_input = Vector2(joystick_vector.x, -joystick_vector.y)
		elif event.index == look_touch and player:
			var delta_pos := event.position - last_look_position
			player.rotate_camera(delta_pos.x, delta_pos.y)
			last_look_position = event.position

func _process(_delta: float) -> void:
	if player:
		district_label.text = "ШОЛОХОВСКИЙ  •  ЦЕНТР" if player.global_position.z < 0 else "ШОЛОХОВСКИЙ  •  ДИЕТКА"
