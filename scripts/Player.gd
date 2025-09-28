extends CharacterBody3D

signal role_updated(role: String, player_name: String)

# Export variables for tweaking in editor
@export var role: String = "Prey"  # Changed from "Sheep" for horror theme
@export var speed: float = 3.0  # Adjusted to match walk animation pace
@export var sprint_speed: float = 5.0  # Adjusted to match run animation pace
@export var wolf_speed_multiplier: float = 1.25  # 25% speed boost for wolf
@export var jump_force: float = 5.0
@export var mouse_sens: float = 0.12
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player state variables
var player_name: String = "Player"
var yaw: float = 0.0
var pitch: float = 0.0
var current_anim_state: String = "idle"
var role_swap_cooldown: float = 0.0
var role_swap_cooldown_time: float = 2.0  # 2 second cooldown between swaps

# Radar system variables
var radar_timer: float = 0.0
var radar_interval: float = 30.0  # Ping every 30 seconds
var radar_ping_duration: float = 3.0  # How long the ping lasts
var radar_active: bool = false

# Node references
@onready var label_3d: Label3D = $Label3D
@onready var cam: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var contact_area: Area3D = $ContactArea

func _ready():
	print("Player ready - ID: ", get_multiplayer_authority())
	
	# Setup animations with debugging
	if anim_tree:
		print("AnimationTree found!")
		anim_tree.active = true
		print("AnimationTree activated")
		
		# Check if AnimationPlayer exists
		var anim_player = get_node("Root Scene/AnimationPlayer")
		if anim_player:
			print("AnimationPlayer found: ", anim_player.get_animation_list())
		else:
			print("ERROR: AnimationPlayer not found!")
		
		# Small delay before setting initial animation
		await get_tree().process_frame
		set_animation_state("idle")
	else:
		print("ERROR: AnimationTree not found!")
	
	# Setup label
	if label_3d:
		label_3d.text = "[%s] %s" % [role, player_name]
		label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Setup contact detection for all players
	if contact_area:
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
		if label_3d:
			label_3d.modulate = Color.GRAY.lerp(Color.WHITE, 1.0 - (role_swap_cooldown / role_swap_cooldown_time))
	else:
		if label_3d:
			label_3d.modulate = Color.WHITE
	
	# Radar system - ping players every 30 seconds
	radar_timer += delta
	if radar_timer >= radar_interval:
		radar_timer = 0.0
		trigger_radar_ping()
	
	# Handle radar ping visual effect
	if radar_active:
		radar_ping_duration -= delta
		if radar_ping_duration <= 0:
			radar_active = false
			hide_radar_ping()
	
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	# Manual radar trigger (hold R for emergency ping)
	if Input.is_action_just_pressed("ui_cancel"):  # ESC key for emergency radar
		if radar_timer >= 10.0:  # Can only use emergency radar if normal radar timer is at least 10s
			trigger_emergency_radar()
			radar_timer = max(radar_timer - 10.0, 0.0)  # Reduces next radar by 10 seconds
	
	# Handle movement with smooth physics
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
	
	# Apply hunter speed advantage
	if role == "Hunter":  # Changed from "Wolf" 
		current_speed *= wolf_speed_multiplier
	
	# Smooth movement physics - YOUR SOLUTION IMPLEMENTED
	if direction:
		# Smooth acceleration to target velocity
		var target_velocity_x = direction.x * current_speed
		var target_velocity_z = direction.z * current_speed
		velocity.x = move_toward(velocity.x, target_velocity_x, current_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, target_velocity_z, current_speed * 4.0 * delta)
	else:
		# Smooth deceleration instead of instant stop
		var deceleration = current_speed * 8.0  # Faster deceleration than acceleration
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
	
	move_and_slide()
	
	# Velocity-based animation system for accurate state detection
	if is_multiplayer_authority():
		var is_on_ground = is_on_floor()
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		var speed_magnitude = horizontal_velocity.length()
		
		# Check for movement input (for immediate responsiveness)
		var has_input = (
			Input.is_action_pressed("move_front") or 
			Input.is_action_pressed("move_back") or 
			Input.is_action_pressed("move_left") or 
			Input.is_action_pressed("move_right")
		)
		
		var is_running_input = Input.is_action_pressed("sprint")
		var new_anim_state = "idle"
		
		# Animation based on both input AND actual velocity for accuracy
		if is_on_ground:
			if has_input and speed_magnitude > 0.5:  # Moving threshold
				if is_running_input and speed_magnitude > 4.0:  # Running speed threshold
					new_anim_state = "run"
				elif speed_magnitude > 1.0:  # Walking speed threshold
					new_anim_state = "walk"
			elif speed_magnitude < 0.3:  # Nearly stopped
				new_anim_state = "idle"
		
		# Animation speed scaling to match movement speed (prevents foot sliding)
		if anim_tree:
			var anim_speed_scale = 1.0
			if new_anim_state == "walk" and speed_magnitude > 0.1:
				# Scale walk animation: faster movement = faster animation
				anim_speed_scale = clamp(speed_magnitude / speed, 0.5, 2.0)
			elif new_anim_state == "run" and speed_magnitude > 0.1:
				# Scale run animation: match sprint speed
				anim_speed_scale = clamp(speed_magnitude / sprint_speed, 0.8, 2.0)
			
			# Apply time scale for speed matching (if TimeScale node exists)
			if anim_tree.has_method("set"):
				anim_tree.set("parameters/TimeScale/scale", anim_speed_scale)
			
			print("Speed: ", speed_magnitude, " | Anim scale: ", anim_speed_scale, " | State: ", new_anim_state)
		
		set_animation_state(new_anim_state)
		rpc("sync_animation", new_anim_state)
	
	# Sync position to other players
	rpc("sync_position", position, velocity)

# Enhanced network prediction for smoother multiplayer movement
@rpc("any_peer", "call_local", "unreliable")
func sync_position(pos: Vector3, vel: Vector3):
	if not is_multiplayer_authority():
		var distance = position.distance_to(pos)
		
		if distance > 5.0:  # Teleport if too far (network glitch)
			position = pos
		elif distance > 0.1:  # Smooth interpolation for normal differences
			var interp_speed = 0.15 if distance > 1.0 else 0.25
			position = position.lerp(pos, interp_speed)
		
		# Predict next position based on velocity for smoother movement
		var prediction_factor = 0.1  # Predict 0.1 seconds ahead
		var predicted_pos = pos + (vel * prediction_factor)
		position = position.lerp(predicted_pos, 0.1)
		
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
		
		# GLOBAL ANNOUNCEMENT
		var announcement = "🔄 ROLE SWAP! " + player_name + " (" + role + ") ↔ " + other_player.player_name + " (" + other_player.role + ")"
		rpc("announce_globally", announcement)
		
		print("Role swap! ", player_name, " is now ", role, ", ", other_player.player_name, " is now ", other_player.role)

@rpc("any_peer", "call_local", "reliable")
func announce_globally(message: String):
	# Send announcement to HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_global_announcement"):
		hud.show_global_announcement(message)

func show_role_swap_effect():
	# Create a brief screen flash effect
	if label_3d:
		var original_modulate = label_3d.modulate
		# Flash with horror-themed role colors
		var flash_color = Color(0.7, 0.15, 0.1, 1.0) if role == "Hunter" else Color(0.3, 0.5, 0.7, 1.0)  # Blood red for Hunter, muted blue for Prey
		label_3d.modulate = flash_color
		
		# Scale effect
		var original_scale = label_3d.scale
		var tween = create_tween()
		tween.parallel().tween_property(label_3d, "modulate", original_modulate, 0.8)
		tween.parallel().tween_property(label_3d, "scale", original_scale * 1.5, 0.2)
		tween.tween_property(label_3d, "scale", original_scale, 0.6)

@rpc("any_peer", "call_local", "reliable")
func update_role(new_role: String):
	role = new_role
	if label_3d:
		label_3d.text = "[%s] %s" % [role, player_name]
	emit_signal("role_updated", role, player_name)

func set_animation_state(state: String):
	if anim_tree and state != current_anim_state:
		current_anim_state = state
		# Try both simple StateMachine and BlendTree approaches
		var state_machine = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		if not state_machine:
			state_machine = anim_tree.get("parameters/StateMachine/playbook") as AnimationNodeStateMachinePlayback
		
		if state_machine:
			var target_state = ""
			if state == "idle":
				target_state = "CharacterArmature|Idle_Neutral"
			elif state == "walk":
				target_state = "CharacterArmature|Walk"  
			elif state == "run":
				target_state = "CharacterArmature|Run"
			
			if target_state != "":
				# Use travel() for smooth state machine transitions
				state_machine.travel(target_state)
				print("Traveling to state: ", target_state)

func trigger_radar_ping():
	# Only ping if there are other players
	var all_players = get_tree().get_nodes_in_group("players")
	if all_players.size() <= 1:
		return
	
	# Send radar ping to all players
	rpc("show_radar_ping", player_name, position)
	
	# Show announcement
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_global_announcement"):
		hud.show_global_announcement("📡 RADAR PING! All player positions revealed for 3 seconds!")

func trigger_emergency_radar():
	# Emergency radar with shorter duration
	var all_players = get_tree().get_nodes_in_group("players")
	if all_players.size() <= 1:
		return
	
	# Send emergency ping
	rpc("show_emergency_radar_ping", player_name, position)
	
	# Show announcement
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_global_announcement"):
		hud.show_global_announcement("🚨 EMERGENCY RADAR! " + player_name + " used emergency ping! (2s duration)")

@rpc("any_peer", "call_local", "reliable")
func show_radar_ping(pinging_player: String, ping_position: Vector3):
	radar_active = true
	radar_ping_duration = 3.0  # Reset duration
	
	# Enhanced visual effect for radar ping
	if label_3d:
		# Create pulsing radar effect
		var original_scale = label_3d.scale
		var tween = create_tween()
		tween.set_loops(6)  # Pulse 6 times over 3 seconds
		tween.tween_property(label_3d, "scale", original_scale * 1.8, 0.25)
		tween.tween_property(label_3d, "scale", original_scale, 0.25)
		
		# Radar color effect - bright green for visibility
		var original_modulate = label_3d.modulate
		label_3d.modulate = Color(0.2, 1.0, 0.2, 1.0)  # Bright radar green
		
		# Fade back to normal
		var color_tween = create_tween()
		color_tween.tween_delay(3.0)
		color_tween.tween_property(label_3d, "modulate", original_modulate, 0.5)

@rpc("any_peer", "call_local", "reliable")
func show_emergency_radar_ping(pinging_player: String, ping_position: Vector3):
	radar_active = true
	radar_ping_duration = 2.0  # Shorter duration for emergency
	
	# More intense visual effect for emergency radar
	if label_3d:
		# Faster, more intense pulsing
		var original_scale = label_3d.scale
		var tween = create_tween()
		tween.set_loops(8)  # More pulses, faster
		tween.tween_property(label_3d, "scale", original_scale * 2.2, 0.125)
		tween.tween_property(label_3d, "scale", original_scale, 0.125)
		
		# Emergency red color
		var original_modulate = label_3d.modulate
		label_3d.modulate = Color(1.0, 0.2, 0.2, 1.0)  # Bright emergency red
		
		# Fade back to normal
		var color_tween = create_tween()
		color_tween.tween_delay(2.0)
		color_tween.tween_property(label_3d, "modulate", original_modulate, 0.5)

func hide_radar_ping():
	# Reset any remaining visual effects
	if label_3d:
		var original_scale = Vector3.ONE
		var original_modulate = Color.WHITE
		label_3d.scale = original_scale
		label_3d.modulate = original_modulate

func get_radar_time_remaining() -> float:
	return radar_interval - radar_timer

func get_role() -> String:
	return role
