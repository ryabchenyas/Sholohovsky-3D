extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const WORLD_LIMIT := 68.0

var player: CharacterBody3D
var joystick_origin := Vector2.ZERO
var joystick_touch := -1
var look_touch := -1
var last_look_position := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var district_label: Label
var coins_label: Label
var mission_label: Label
var collected_coins := 0
var coin_nodes: Array[Node3D] = []
var traffic: Array[Node3D] = []
var traffic_speeds: Array[float] = []
var traffic_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
	_build_collectibles()
	_build_traffic()

func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = env
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	_add_box(Vector3(0, -0.45, 0), Vector3(150, 0.5, 150), Color("#71965a"), true)
	# Main avenue and cross streets
	_add_box(Vector3(0, -0.12, 0), Vector3(14, 0.18, 138), Color("#34383d"), true)
	_add_box(Vector3(0, -0.015, 0), Vector3(0.18, 0.025, 138), Color("#f5d77a"), false)
	for z in [-48.0, -24.0, 0.0, 24.0, 48.0]:
		_add_box(Vector3(0, -0.11, z), Vector3(138, 0.18, 7), Color("#42464a"), true)
		for x in range(-60, 65, 8):
			_add_box(Vector3(float(x), -0.005, z), Vector3(3.2, 0.025, 0.13), Color("#eee9d9"), false)
	# Sidewalks along the avenue
	for side in [-1.0, 1.0]:
		_add_box(Vector3(side * 8.3, -0.02, 0), Vector3(2.7, 0.18, 138), Color("#c8c2b2"), true)
		_add_box(Vector3(side * 10.0, 0.015, 0), Vector3(0.22, 0.22, 138), Color("#9b9b8b"), true)

	_add_district(-1, Color("#d9b58b"), Color("#784d3a"))
	_add_district(1, Color("#d8dce0"), Color("#536779"))
	_build_parks()
	_build_street_furniture()
	_add_sign("ЦЕНТР", Vector3(-12, 0, -8), Color("#2465a6"))
	_add_sign("ДИЕТКА", Vector3(12, 0, 8), Color("#27834f"))

func _add_district(side: int, wall_color: Color, roof_color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + side
	for row in range(5):
		for col in range(3):
			var x := -20.0 - float(col) * 14.0 if side == -1 else 20.0 + float(col) * 14.0
			var z := (float(row) - 2.0) * 22.0 + (5.0 if side == 1 else -5.0)
			var width := rng.randf_range(8.0, 10.0)
			var depth := rng.randf_range(8.0, 10.0)
			var floors := rng.randi_range(2, 5)
			var height := float(floors) * 2.65
			var facade := wall_color.lerp(Color("#f4e8d4"), rng.randf() * 0.28)
			_build_house(Vector3(x, 0, z), Vector3(width, height, depth), facade, roof_color, floors, rng.randi_range(0, 2))

func _build_house(origin: Vector3, size: Vector3, wall: Color, roof: Color, floors: int, style: int) -> void:
	var x := origin.x
	var z := origin.z
	var w := size.x
	var h := size.y
	var d := size.z
	_add_box(Vector3(x, h * 0.5, z), Vector3(w, h, d), wall, true)
	# Roof, cornice and front entrance
	_add_box(Vector3(x, h + 0.22, z), Vector3(w + 0.7, 0.42, d + 0.7), roof, false)
	_add_box(Vector3(x, h + 0.48, z), Vector3(w * 0.72, 0.18, d * 0.72), roof.darkened(0.18), false)
	_add_box(Vector3(x, 1.05, z - d * 0.5 - 0.08), Vector3(1.15, 2.1, 0.16), Color("#634735"), false)
	_add_box(Vector3(x, 2.15, z - d * 0.5 - 0.16), Vector3(2.0, 0.18, 0.16), Color("#f1d7a5"), false)
	# Windows in rows, with frames and warm reflections
	var floors_count := maxi(1, floors - 1)
	for floor_index in range(floors_count):
		var y := 2.15 + float(floor_index) * 2.55
		for window_index in range(2):
			var wx := x + (float(window_index) - 0.5) * (w * 0.48)
			_add_box(Vector3(wx, y, z - d * 0.5 - 0.075), Vector3(1.25, 1.15, 0.12), Color("#f1dfbd"), false)
			_add_box(Vector3(wx, y, z - d * 0.5 - 0.15), Vector3(0.98, 0.88, 0.08), Color("#79a9bd").lerp(Color("#f5dca0"), 0.22), false)
			_add_box(Vector3(wx, y, z - d * 0.5 - 0.205), Vector3(0.07, 0.92, 0.04), Color("#e8dfcd"), false)
			_add_box(Vector3(wx, y, z - d * 0.5 - 0.21), Vector3(1.0, 0.06, 0.04), Color("#e8dfcd"), false)
			if style == 1 and floor_index % 2 == 0:
				_add_box(Vector3(wx, y - 0.68, z - d * 0.5 - 0.32), Vector3(1.35, 0.09, 0.55), Color("#555b60"), false)
	# Side windows
	for floor_index in range(floors_count):
		_add_box(Vector3(x + w * 0.5 + 0.07, 2.2 + float(floor_index) * 2.55, z), Vector3(0.12, 1.0, 1.25), Color("#80a9b9"), false)
	# Ground-floor shopfront on selected buildings
	if style == 2:
		_add_box(Vector3(x, 1.45, z - d * 0.5 - 0.14), Vector3(w * 0.62, 1.55, 0.08), Color("#355d67"), false)
		_add_box(Vector3(x, 2.35, z - d * 0.5 - 0.22), Vector3(w * 0.75, 0.42, 0.22), Color("#e6b85d"), false)
	# Entrance steps
	_add_box(Vector3(x, 0.16, z - d * 0.5 - 0.55), Vector3(2.2, 0.28, 0.8), Color("#a99b88"), false)

func _build_parks() -> void:
	for center in [Vector3(-39, 0, 0), Vector3(39, 0, 0)]:
		_add_box(center + Vector3(0, 0.02, 0), Vector3(12, 0.12, 15), Color("#83a96a"), false)
		for offset in [Vector3(-4, 0, -5), Vector3(4, 0, -5), Vector3(-4, 0, 5), Vector3(4, 0, 5)]:
			_build_tree(center + offset)
		_add_box(center + Vector3(0, 0.42, 0), Vector3(3.4, 0.22, 0.75), Color("#8a6849"), false)
		_add_box(center + Vector3(0, 0.85, 0), Vector3(0.12, 0.7, 0.12), Color("#8a6849"), false)

func _build_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 2.1
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 1.05, 0)
	trunk.material_override = _mat(Color("#765039"))
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.15
	crown_mesh.height = 2.2
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(0, 2.75, 0)
	crown.material_override = _mat(Color("#39794b"))
	add_child(crown)

func _build_street_furniture() -> void:
	for z in [-54.0, -30.0, -6.0, 18.0, 42.0, 60.0]:
		for side in [-1.0, 1.0]:
			var x := side * 9.4
			_add_box(Vector3(x, 2.2, z), Vector3(0.14, 4.4, 0.14), Color("#444b50"), false)
			_add_box(Vector3(x, 4.45, z), Vector3(0.9, 0.12, 0.45), Color("#f6e2a2"), false)
			_add_box(Vector3(x, 0.52, z + 2.0), Vector3(1.5, 0.9, 0.7), Color("#3f7656"), false)

func _add_sign(text_value: String, pos: Vector3, color: Color) -> void:
	_add_box(pos + Vector3(0, 1.25, 0), Vector3(0.18, 2.5, 0.18), Color("#35383b"), true)
	_add_box(pos + Vector3(0, 2.45, 0), Vector3(4.8, 1.0, 0.22), color, true)
	var label := Label3D.new()
	label.text = text_value
	label.font_size = 48
	label.pixel_size = 0.012
	label.position = pos + Vector3(0, 2.28, 0.14)
	add_child(label)

func _add_box(pos: Vector3, size: Vector3, color: Color, collision: bool) -> Node3D:
	var holder: Node3D
	if collision:
		var body := StaticBody3D.new()
		body.position = pos
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		holder = body
	else:
		holder = MeshInstance3D.new()
		holder.position = pos
	var mesh_instance: MeshInstance3D
	if collision:
		mesh_instance = MeshInstance3D.new()
		(holder as StaticBody3D).add_child(mesh_instance)
	else:
		mesh_instance = holder as MeshInstance3D
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = _mat(color)
	if collision:
		add_child(holder)
	else:
		add_child(mesh_instance)
	return holder

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 0.2, -12)
	add_child(player)

func _build_collectibles() -> void:
	for i in range(18):
		var coin := Area3D.new()
		coin.position = Vector3(0.0, 0.9, -55.0 + float(i) * 6.4)
		coin.set_meta("coin_index", i)
		var mesh := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.42
		cylinder.bottom_radius = 0.42
		cylinder.height = 0.13
		mesh.mesh = cylinder
		mesh.rotation_degrees.z = 90
		mesh.material_override = _mat(Color("#ffd34f"))
		coin.add_child(mesh)
		var glow := OmniLight3D.new()
		glow.light_color = Color("#ffcf52")
		glow.light_energy = 0.45
		glow.omni_range = 2.2
		coin.add_child(glow)
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.0
		collision.shape = sphere
		coin.add_child(collision)
		coin.body_entered.connect(_on_coin_body_entered.bind(coin))
		add_child(coin)
		coin_nodes.append(coin)

func _on_coin_body_entered(body: Node3D, coin: Node3D) -> void:
	if body != player or not is_instance_valid(coin):
		return
	collected_coins += 1
	coins_label.text = "МОНЕТЫ: %d / 18" % collected_coins
	coin.queue_free()
	coin_nodes.erase(coin)
	if collected_coins >= 18:
		mission_label.text = "ЗАДАНИЕ ВЫПОЛНЕНО! Ты собрал все монеты!"
	else:
		mission_label.text = "ЗАДАНИЕ: собери монеты по всему городу"

func _build_traffic() -> void:
	var car_specs := [
		[Vector3(-3.0, 0.0, -55.0), Color("#c84e3c"), 8.0],
		[Vector3(3.0, 0.0, 18.0), Color("#3978b8"), -6.5],
		[Vector3(-3.0, 0.0, 45.0), Color("#e5b84f"), 5.5]
	]
	for spec in car_specs:
		var car_position: Vector3 = spec[0]
		var car_color: Color = spec[1]
		var car_speed: float = float(spec[2])
		var car := _make_car(car_color)
		car.position = car_position
		car.rotation.y = 0.0 if car_speed < 0.0 else PI
		add_child(car)
		traffic.append(car)
		traffic_speeds.append(car_speed)

func _make_car(color: Color) -> Node3D:
	var car := Node3D.new()
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.15, 0.72, 4.0)
	body.mesh = body_mesh
	body.position.y = 0.72
	body.material_override = _mat(color)
	car.add_child(body)
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.65, 0.82, 2.05)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 1.42, -0.15)
	cabin.material_override = _mat(Color("#91b7c7"))
	car.add_child(cabin)
	for side in [-1.0, 1.0]:
		for front_back in [-1.0, 1.0]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.43
			wheel_mesh.bottom_radius = 0.43
			wheel_mesh.height = 0.28
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(side * 1.08, 0.45, front_back * 1.25)
			wheel.material_override = _mat(Color("#25282b"))
			car.add_child(wheel)
	for side in [-1.0, 1.0]:
		var lamp := MeshInstance3D.new()
		var lamp_mesh := BoxMesh.new()
		lamp_mesh.size = Vector3(0.42, 0.2, 0.12)
		lamp.mesh = lamp_mesh
		lamp.position = Vector3(side * 0.68, 0.8, -2.02)
		lamp.material_override = _mat(Color("#fff1bd"))
		car.add_child(lamp)
	return car

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(300, 112)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	district_label = Label.new()
	district_label.text = "ШОЛОХОВСКИЙ • ЦЕНТР"
	district_label.add_theme_font_size_override("font_size", 19)
	column.add_child(district_label)
	coins_label = Label.new()
	coins_label.text = "МОНЕТЫ: 0 / 18"
	coins_label.add_theme_color_override("font_color", Color("#b47b12"))
	column.add_child(coins_label)
	mission_label = Label.new()
	mission_label.text = "ЗАДАНИЕ: собери 18 монет"
	column.add_child(mission_label)

	var hint := Label.new()
	hint.text = "ЛЕВАЯ СТОРОНА — ДВИЖЕНИЕ  •  ПРАВАЯ — ОБЗОР"
	hint.anchor_left = 0.5
	hint.anchor_top = 1.0
	hint.anchor_right = 0.5
	hint.anchor_bottom = 1.0
	hint.offset_left = -270
	hint.offset_top = -42
	hint.offset_right = 270
	hint.offset_bottom = -12
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(hint)

	var jump_button := Button.new()
	jump_button.text = "ПРЫЖОК"
	jump_button.custom_minimum_size = Vector2(116, 68)
	jump_button.anchor_left = 1.0
	jump_button.anchor_top = 1.0
	jump_button.anchor_right = 1.0
	jump_button.anchor_bottom = 1.0
	jump_button.offset_left = -146
	jump_button.offset_top = -112
	jump_button.offset_right = -22
	jump_button.offset_bottom = -30
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
				player.move_input = Vector2(joystick_vector.x, joystick_vector.y)
		elif event.index == look_touch and player:
			var delta_pos: Vector2 = event.position - last_look_position
			player.rotate_camera(delta_pos.x, delta_pos.y)
			last_look_position = event.position

func _process(delta: float) -> void:
	if player:
		district_label.text = "ШОЛОХОВСКИЙ • ЦЕНТР" if player.global_position.x < 0 else "ШОЛОХОВСКИЙ • ДИЕТКА"
	for i in range(traffic.size()):
		var car := traffic[i]
		if is_instance_valid(car):
			car.position.z += traffic_speeds[i] * delta
			if car.position.z > WORLD_LIMIT:
				car.position.z = -WORLD_LIMIT
			elif car.position.z < -WORLD_LIMIT:
				car.position.z = WORLD_LIMIT
	for coin in coin_nodes:
		if is_instance_valid(coin):
			coin.rotate_y(delta * 1.8)
