extends CharacterBody2D

@onready var nav_agent : NavigationAgent2D = get_node("NavigationAgent2D")

@export var nav_agent_radius : float = 15.0
@export var nav_optimize_path : bool = true
@export var nav_avoidance_enabled : bool = true
@export var player_speed_multiplier : float = 60.0

var flip1= false

enum{IDLE, MOVE, DIE}
var state = MOVE

# final navigation destination position/point
#var nav_destination : Vector2 
# next navigation destination position/point
var next_nav_position : Vector2 



func _ready() -> void:
	
	velocity = Vector2.ZERO
	
	# Connect nav agent signal callback functions.
	nav_agent.connect("path_changed",Callable(self,"character_path_changed"))
	nav_agent.connect("target_reached",Callable(self,"character_target_reached"))
	nav_agent.connect("navigation_finished",Callable(self,"character_navigation_finished"))
	nav_agent.connect("velocity_computed",Callable(self,"character_velocity_computed"))
	# config nav agent attributes
	nav_agent.max_speed = player_speed_multiplier
	nav_agent.radius = nav_agent_radius
	nav_agent.avoidance_enabled = true
	#set_navigation_position(get_parent().get_node("Marker2D").global_position)
	$AnimatedSprite2D.animation_finished.connect(_animation_finished)


func _physics_process(_delta : float) -> void:
	if $Timer.is_stopped() :
		$ProgressBar.hide()
	# get the next nav position from the player's navigation agent
	if Config.npc_hitpoint <=0:
		die()
		return
	
	await get_tree().physics_frame
	
	next_nav_position = nav_agent.get_next_path_position()
	
	# calculate the desired velocity, i.e velocity pre nav server calculated
	if(position.x <next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(false)
	if(position.x >next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(true)	
	var desired_velocity = global_position.direction_to(next_nav_position) * player_speed_multiplier
	
	# trigger a callback from velocity_computed signal
	nav_agent.set_velocity(desired_velocity)
	
func set_navigation_position(nav_destination : Vector2) -> void:
		# set the new player target location
	nav_agent.set_target_position(nav_destination)
	
func character_path_changed() -> void:
	pass
	
func character_target_reached() -> void:
	pass
	
func character_navigation_finished() -> void: 
	#if npc arrive at one point, then return
	if !flip1:
		set_navigation_position(get_parent().get_node("mark/Marker2D2").global_position)
		flip1 = true
	else:
		set_navigation_position(get_parent().get_node("mark/Marker2D").global_position)
		flip1=false

func character_velocity_computed(calculated_velocity : Vector2) -> void:
	# check if nav agent target is reached
	if Config.npc_hitpoint <=0:
		die()
		return
	
	if !nav_agent.is_target_reached() and Config.click != 'npc':
		# move and slide with the new calculated velocity
		set_velocity(calculated_velocity)
		move_and_slide()
		change_state(MOVE)
	else:
		change_state(IDLE)
		if(position.x <get_parent().get_node("player").global_position.x):
			$AnimatedSprite2D.set_flip_h(false)
		if(position.x >get_parent().get_node("player").global_position.x):
			$AnimatedSprite2D.set_flip_h(true)	

func die():
	if Config.npc_death == 0:
		change_state(DIE)
		#$Area2D.set_deferred("disabled", true)


func change_state(newState):
	state = newState
	match state: 
		IDLE:
			$AnimatedSprite2D.play("idle")
		MOVE:
			$AnimatedSprite2D.play("walk")
		DIE:
			$AnimatedSprite2D.play("die")

func _animation_finished(): #used for non-loop animation:death
	Config.npc_death = 1


func timer1():
	if $Timer.is_stopped():
		$ProgressBar.show()
		$Timer.one_shot = true
		$Timer.wait_time = Config.progressBarTime
		$Timer.start()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if !Input.is_action_pressed("ui_mouseleftclick"):
		return
	Config.click =  self.name #if player clicks on npc
