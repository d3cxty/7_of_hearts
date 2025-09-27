extends CharacterBody3D

signal role_updated(role: String, player_name: String)

@export var role: String = "Sheep"
@export var speed := 4.0
@export var sprint_speed := 6.5
@export var accel := 12.0
@export var jump_force := 5.0
@export var mouse_sens := 0.12
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var player_name: String = "Player" + str(get_multiplayer_authority())
var vel: Vector3 = Vector3.ZERO
var yaw: float = 0.0
var pitch: float = 0.0

@onready var label_3d: Label3D = $Label3D
@onready var cam: Camera3D = $Camera3D  # Direct camera for first-person
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var ray: RayCast3D = $Camera3D/RayCast3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Debug: Print which nodes exist
	print("=== Node Debug Info ===")
	print("label_3d exists: ", label_3d != null)
	print("cam exists: ", cam != null)
	print("anim_tree exists: ", anim_tree != null)
	print("ray exists: ", ray != null)
	print("=====================")
	
	# Check if nodes exist before using them
	if anim_tree:
		anim_tree.active = true
		set_state("idle")
	else:
		print("WARNING: AnimationTree not found!")
	
	if label_3d:
		label_3d.text = "[%s] %s" % [role, player_name]
		# Set billboard mode properly
		label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	else:
		print("WARNING: Label3D not found!")
	
	if not cam:
		print("WARNING: Camera3D not found!")
		
	if not ray:
		print("WARNING: RayCast3D not found!")
	
	if is_multiplayer_authority():
		rpc("sync_state", position, rotation.y, role, player_name)

func _unhandled_input(e):
	if e is InputEventMouseMotion and is_multiplayer_authority():
		yaw -= e.relative.x * mouse_sens * 0.01
		pitch -= e.relative.y * mouse_sens * 0.01
		pitch = clamp(pitch, deg_to_rad(-85), deg_to_rad(85))
		
		rotation.y = yaw
		if cam:
			cam.rotation.x = pitch
			rpc("sync_rotation", rotation.y, cam.rotation.x)

func _physics_process(dt):
	if not is_multiplayer_authority():
		return
	
	# Input handling - Fixed movement directions
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var z := Input.get_action_strength("move_front") - Input.get_action_strength("move_back")  # Fixed: front is forward (negative z)
	var input2 := Vector2(x, z).normalized()
	
	# Movement calculation - First person
	var forward := Vector3.ZERO
	var right := Vector3.ZERO
	
	if cam:
		forward = -cam.global_transform.basis.z  # Camera forward
		right = cam.global_transform.basis.x     # Camera right
	else:
		forward = -global_transform.basis.z      # Player forward
		right = global_transform.basis.x         # Player right
	
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var wish := (right * input2.x + forward * input2.y).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else speed
	var target := wish * target_speed
	
	vel.x = lerp(vel.x, target.x, accel * dt)
	vel.z = lerp(vel.z, target.z, accel * dt)
	
	# Gravity and jumping
	if not is_on_floor():
		vel.y -= gravity * dt
	elif Input.is_action_just_pressed("jump"):
		vel.y = jump_force
	
	velocity = vel
	move_and_slide()
	
	# Animation state based on movement and sprint
	var is_moving = (abs(vel.x) + abs(vel.z)) > 0.05
	var is_sprinting = Input.is_action_pressed("sprint")
	
	if is_moving:
		if is_sprinting:
			set_state("run")
		else:
			set_state("walk")
	else:
		set_state("idle")
	
	rpc("sync_position", position)
	
	# Collision detection
	if ray and ray.is_colliding():
		var collider = ray.get_collider()
		if collider is CharacterBody3D and collider.has_method("get_role"):
			if role == "Sheep" and collider.get_role() == "Wolf":
				rpc("swap_roles", get_multiplayer_authority(), collider.get_multiplayer_authority())

func set_state(state_name: String):
	if anim_tree:
		# Use AnimationTree's state machine
		var state_machine = anim_tree.get("parameters/playback")
		if state_machine:
			if state_name == "walk":
				state_machine.travel("CharacterArmature|Walk")
			elif state_name == "run":
				state_machine.travel("CharacterArmature|Run")
			else:  # idle
				state_machine.travel("CharacterArmature|Idle")
			print("AnimationTree: Setting state to ", state_name)
		else:
			print("No state machine found in AnimationTree")
	else:
		print("No AnimationTree found")

func get_role() -> String:
	return role

@rpc("any_peer", "call_local", "unreliable")
func sync_state(pos: Vector3, rot_y: float, new_role: String, new_name: String):
	position = pos
	rotation.y = rot_y
	role = new_role
	player_name = new_name
	if label_3d:
		label_3d.text = "[%s] %s" % [role, player_name]

@rpc("any_peer", "call_local", "unreliable")
func sync_position(pos: Vector3):
	if not is_multiplayer_authority():
		position = pos

@rpc("any_peer", "call_local", "unreliable")
func sync_rotation(rot_y: float, rot_x: float):
	if not is_multiplayer_authority():
		rotation.y = rot_y
		if cam:
			cam.rotation.x = rot_x

@rpc("any_peer", "call_local")
func swap_roles(old_wolf_id: int, new_wolf_id: int):
	if get_multiplayer_authority() == old_wolf_id:
		role = "Sheep"
	if get_multiplayer_authority() == new_wolf_id:
		role = "Wolf"
	
	if label_3d:
		label_3d.text = "[%s] %s" % [role, player_name]
	
	emit_signal("role_updated", role, player_name)
	
	if is_multiplayer_authority():
		rpc("sync_state", position, rotation.y, role, player_name)
