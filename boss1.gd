
extends CharacterBody2D


@onready var nav_agent : NavigationAgent2D = get_node("NavigationAgent2D")

@export var nav_agent_radius : float = 15.0
@export var nav_optimize_path : bool = true
@export var nav_avoidance_enabled : bool = true
@export var player_speed_multiplier : float = 60.0

var flip1= false

enum{WALK, ATTACK}
var state = WALK
var hitpoint = Config.boss_hitpoint
var playerenter = false
var attack = true

# navigation destination position
#var nav_destination : Vector2 
# next navigation destination position
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
	
	$AnimatedSprite2D.animation_finished.connect(_animation_finished)

func _physics_process(_delta : float) -> void:
	# get the next nav position from the player's navigation agent
	if $Timer.is_stopped() : #if timerout, hide progressbar
		$ProgressBar.hide()
	await get_tree().physics_frame
	
	next_nav_position = nav_agent.get_next_path_position()
	
	if(position.x <next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(false)
	if(position.x >next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(true)	
	var desired_velocity = global_position.direction_to(next_nav_position).normalized() * player_speed_multiplier
	
	#trigger a callback from velocity_computed signal
	nav_agent.set_velocity(desired_velocity)
	
	if $hittimer.is_stopped() and hitpoint > 0:
		if playerenter:
			$hittimer.start() #use hittimer to control the frequency of hitting
			change_state(ATTACK)
			get_parent().get_node("player").timer1() #show progressbar of player
			if Config.player_shell > 0: #hit the shell first 
				Config.player_shell -= 1
				if Config.player_shell == 0:
					get_parent().get_node("player/CollisionShape2D").hide()
			else: 
				Config.player_hitpoint -= 1

func set_navigation_position(nav_destination : Vector2) -> void:
	
	# set the new target location
	nav_agent.set_target_position(nav_destination)
	
	
func character_path_changed() -> void:
	pass
		
func character_target_reached() -> void:
	pass
	
func character_navigation_finished() -> void:
	pass

func character_velocity_computed(calculated_velocity : Vector2) -> void:
	
	if hitpoint <= 0:
		$AnimatedSprite2D.play("death")
		return
	## check if nav agent target is reached
	if !nav_agent.is_target_reached()  :
		## move and slide with the new calculated velocity
		velocity = velocity.move_toward(calculated_velocity,.15)
		move_and_slide()
	
func change_state(newState):
	state = newState
	match state: 
		WALK:
			$AnimatedSprite2D.play("walk")
		ATTACK:
			$AnimatedSprite2D.play("attack")
	pass
	
func hit():
	hitpoint -= 1
	

func _animation_finished():
	if hitpoint <= 0:
		queue_free()
		Config.boss_death = 1

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if !Input.is_action_just_pressed("ui_mouseleftclick"):
		return
	Config.click =  'boss1' #if player clicks on boss
	
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if "player" in body.name and Config.npc_death == 0:
		playerenter = true
		body.timer1()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if "player" in body.name:
		playerenter = false
	
func timer1():
	if $Timer.is_stopped():
		$ProgressBar.show()
		$Timer.one_shot = true
		$Timer.wait_time = Config.progressBarTime
		$Timer.start()

func _on_hittimer_timeout() -> void:
	if hitpoint>0:
		change_state(WALK)
