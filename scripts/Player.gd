extends CharacterBody3D

signal role_updated(role: String, player_name: String)

@export var role: String = "Sheep"
@export var speed: float = 4.0
@export var sprint_speed: float = 6.5
@export var wolf_speed_multiplier: float = 1.25  # 25% speed boost for wolf
@export var jump_force: float = 5.0
@export var mouse_sens: float = 0.12
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var player_name: String = "Player"
var yaw: float = 0.0
var pitch: float = 0.0
var current_anim_state: String = "idle"
var role_swap_cooldown: float = 0.0
var role_swap_cooldown_time: float = 2.0  # 2 second cooldown between swaps

@onready var label_3d: Label3D = $Label3D
@onready var cam: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var contact_area: Area3D = $ContactArea  # Add this to your player scene

func _ready():
	print("Player ready - ID: ", get_multiplayer_authority())
	
	# Setup animations
	if anim_tree:
		anim_tree.active = true
		set_animation_state("idle")
	
	# Setup label
	if label_3d:
		label_3d.text = "[%s] %s" % [role, player_name]
		label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Setup contact detection for all players (not just authority)
	if contact_area:
		# Connect to area_entered instead of body_entered since we're detecting other ContactAreas
		contact_area.area_entered.connect(_on_contact_area_entered)
		print("Contact area connected for player: ", player_name)
	
	# Only enable camera and input for local player
	if is_multiplayer_authority():
		if cam:
			cam.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("Set up local player: ", player_name)
	else:
		if cam:
			cam.current = false
		print("Set up remote player: ", player_name)

func _input(event):
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sens * 0.01
		pitch -= event.relative.y * mouse_sens * 0.01
		pitch = clamp(pitch, deg_to_rad(-85), deg_to_rad(85))
		
		rotation.y = yaw
		if cam:
			cam.rotation.x = pitch
		
		# Sync rotation to other players
		rpc("sync_rotation", yaw, pitch)

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	# Update role swap cooldown
	if role_swap_cooldown > 0:
		role_swap_cooldown -= delta
		# Visual indicator during cooldown
		if label_3d and is_multiplayer_authority():
			label_3d.modulate = Color.GRAY.lerp(Color.WHITE, 1.0 - (role_swap_cooldown / role_swap_cooldown_time))
	else:
		if label_3d and is_multiplayer_authority():
			label_3d.modulate = Color.WHITE
	
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	# Handle movement - Fixed ALL direction mappings
	var input_dir = Input.get_vector("move_left", "move_right", "move_back", "move_front")
	# Use camera-relative movement for first-person feel
	var forward = -cam.global_transform.basis.z if cam else -global_transform.basis.z
	var right = cam.global_transform.basis.x if cam else global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var direction = (right * input_dir.x + forward * input_dir.y).normalized()
	
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else speed
	
	# Apply wolf speed advantage
	if role == "Wolf":
		current_speed *= wolf_speed_multiplier
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
	# Update animations based on movement - only for authority
	if is_multiplayer_authority():
		var speed = velocity.length()
		var is_sprinting = Input.is_action_pressed("sprint")
		
		var new_anim_state = "idle"
		if speed > 0.5:  # Higher threshold to prevent spam
			if is_sprinting and speed > 3.0:
				new_anim_state = "run" 
			else:
				new_anim_state = "walk"
		
		# Only change animation if it's different
		if new_anim_state != current_anim_state:
			set_animation_state(new_anim_state)
			rpc("sync_animation", new_anim_state)
	
	# Sync position to other players
	rpc("sync_position", position, velocity)

@rpc("any_peer", "call_local", "unreliable")
func sync_position(pos: Vector3, vel: Vector3):
	if not is_multiplayer_authority():
		# Smooth interpolation to reduce shaking
		position = position.lerp(pos, 0.3)
		velocity = vel

@rpc("any_peer", "call_local", "unreliable") 
func sync_rotation(y_rot: float, x_pitch: float):
	if not is_multiplayer_authority():
		rotation.y = y_rot
		if cam:
			cam.rotation.x = x_pitch

@rpc("any_peer", "call_local", "unreliable")
func sync_animation(anim_state: String):
	if not is_multiplayer_authority():
		set_animation_state(anim_state)

func _on_contact_area_entered(area: Area3D):
	print("CONTACT DETECTED by ", player_name, " with area: ", area.name)
	
	# Only process on authority and if cooldown is over
	if not is_multiplayer_authority() or role_swap_cooldown > 0:
		print("Skipping swap - not authority or cooldown active")
		return
	
	# Get the other player from the area's parent
	var other_player = area.get_parent()
	if other_player and other_player.is_in_group("players") and other_player != self:
		if other_player.has_method("get_role"):
			print("*** INITIATING ROLE SWAP between ", player_name, " and ", other_player.player_name, " ***")
			rpc("swap_roles_with", other_player.get_multiplayer_authority())

@rpc("any_peer", "call_local", "reliable")
func swap_roles_with(other_player_id: int):
	# Find the other player
	var other_player = null
	for player in get_tree().get_nodes_in_group("players"):
		if player.get_multiplayer_authority() == other_player_id:
			other_player = player
			break
	
	if other_player and other_player != self:
		# Swap roles
		var my_old_role = role
		var other_old_role = other_player.role
		
		# Update roles
		update_role(other_old_role)
		other_player.update_role(my_old_role)
		
		# Set cooldown for both players
		role_swap_cooldown = role_swap_cooldown_time
		other_player.role_swap_cooldown = role_swap_cooldown_time
		
		# Visual feedback for role swap
		show_role_swap_effect()
		other_player.show_role_swap_effect()
		
		print("Role swap! ", player_name, " is now ", role, ", ", other_player.player_name, " is now ", other_player.role)

func show_role_swap_effect():
	# Create a brief screen flash effect
	if is_multiplayer_authority():
		# Flash the label
		if label_3d:
			var original_modulate = label_3d.modulate
			label_3d.modulate = Color.YELLOW
			var tween = create_tween()
			tween.tween_property(label_3d, "modulate", original_modulate, 0.5)

@rpc("any_peer", "call_local", "reliable")
func update_role(new_role: String):
	role = new_role
	if label_3d:
		label_3d.text = "[%s] %s" % [role, player_name]
	emit_signal("role_updated", role, player_name)

func set_animation_state(state: String):
	if state != current_anim_state and anim_tree:
		current_anim_state = state
		var playback = anim_tree.get("parameters/playback")
		if playback:
			var anim_name = "CharacterArmature|" + state.capitalize()
			playback.travel(anim_name)
			print("Animation: ", anim_name)

func get_role() -> String:
	return role
