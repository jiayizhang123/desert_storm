
extends CharacterBody2D

@onready var nav_agent : NavigationAgent2D = get_node("NavigationAgent2D")

@export var nav_agent_radius : float = 15.0
@export var nav_optimize_path : bool = true
@export var nav_avoidance_enabled : bool = true
@export var player_speed_multiplier : float = 60.0

var flip1= false

enum{RUN, ATTACK}
var state = RUN
var hitpoint = Config.enemy1_hitpoint
var npcenter = false
var playerenter =false
var playerbody
var npcbody
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
	#Input.set_use_accumulated_input(false)
	
	$AnimatedSprite2D.animation_finished.connect(_animation_finished)

func _physics_process(_delta : float) -> void:
	# get the next nav position from the player's navigation agent
	if $Timer.is_stopped(): #if timerout, hide progressbar
		$ProgressBar.hide()
	await get_tree().physics_frame
	
	next_nav_position = nav_agent.get_next_path_position()
	
	# calculate the desired velocity, i.e velocity pre nav server calculated
	if(position.x <next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(false)
	if(position.x >next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(true)	
	var desired_velocity = global_position.direction_to(next_nav_position).normalized() * player_speed_multiplier
	
	# trigger a callback from velocity_computed signal
	nav_agent.set_velocity(desired_velocity)
	
	if $hittimer.is_stopped() and hitpoint > 0:
		if npcenter or playerenter:
			$hittimer.start() #use hittimer to control the frequency of hitting
			change_state(ATTACK)
			if npcenter: #if encounter the npc, attack the npc
				Config.npc_hitpoint -= 1
				if npcbody:
					npcbody.timer1() #show progressbar of npc
			if playerenter: #if encounter the player, attack the player
				if Config.player_shell > 0: #hit the shell first 
					Config.player_shell -= 1
					if Config.player_shell == 0:
						get_parent().get_node("player/CollisionShape2D").hide()
				else: 
					Config.player_hitpoint -= 1
					if playerbody:
						playerbody.timer1() #show progressbar of player

func set_navigation_position(nav_destination : Vector2) -> void:
	
	# set the new target location
	nav_agent.set_target_position(nav_destination)
	

func character_path_changed() -> void:
	pass
	#change_state(MOVE)
	
func character_target_reached() -> void:
	pass
	
func character_navigation_finished() -> void:
	pass

func character_velocity_computed(calculated_velocity : Vector2) -> void:
	
	if hitpoint <= 0: #if death, stop moving
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
		RUN:
			$AnimatedSprite2D.play("run")
		ATTACK:
			$AnimatedSprite2D.play("attack")
	pass
	
func hit():
	hitpoint -= 1
	
func _animation_finished(): #used for non-loop animation:death
	if hitpoint <= 0:
		queue_free()
		Config.enemy1num_d += 1
				

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if !Input.is_action_just_pressed("ui_mouseleftclick"):
		return
	Config.click =  'enemy1' #if player clicks on enemy

func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if "npc" in body.name and Config.npc_death == 0:
		npcenter = true
		npcbody = body
		body.timer1() #show progressbar of npc
	if "player" in body.name and Config.player_death == 0:
		playerenter = true
		playerbody = body
		body.timer1() #show progressbar of player


func _on_area_2d_body_exited(body: Node2D) -> void:
	if "npc" in body.name:
		npcenter = false
		npcbody = null
	if "player" in body.name:
		playerenter = false	
		playerbody = null
	
func timer1():
	if $Timer.is_stopped():
		$ProgressBar.show()
		$Timer.one_shot = true
		$Timer.wait_time = Config.progressBarTime
		$Timer.start()

func _on_hittimer_timeout() -> void:
	if hitpoint > 0:
		change_state(RUN)
