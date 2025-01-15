
extends CharacterBody2D

@onready var nav_agent : NavigationAgent2D = get_node("NavigationAgent2D")

@export var nav_agent_radius : float = 15.0
@export var nav_optimize_path : bool = true
@export var nav_avoidance_enabled : bool = true
@export var player_speed_multiplier : float = 150.0

enum{IDLE, MOVE, DIE,ATTACK0, ATTACK45, ATTACK90,ATTACK135,ATTACK180}
var state = IDLE
var enemy1body = []
var enemy1enter = false
var bossbody
var bossenter = false
var attack = true
var audio_player

#  navigation destination position
#var nav_destination : Vector2 
# next navigation destination position
var next_nav_position : Vector2 

# The normal path to the destination
var player_nav_path : Array = []

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
	
	audio_player = AudioStreamPlayer.new() 
	add_child(audio_player)
	audio_player.stream = load('res://asset/sword-sound-2-36274.wav') #sword swing sound
	$AnimatedSprite2D.animation_finished.connect(_animation_finished)
	
	#nav_agent.avoidance_enabled = true
	
func _physics_process(_delta : float) -> void:
	if $Timer.is_stopped() : #if timerout, hide progressbar
		$ProgressBar.hide()
	if Config.player_hitpoint <=0: #check if player is dead
		if Config.player_death == 0:
			die()
		return
	# get the next nav position from the player's navigation agent
	await get_tree().physics_frame
	next_nav_position = nav_agent.get_next_path_position()
	
	# calculate the desired velocity, i.e velocity pre nav server calculated
	var d =  (get_angle_to(get_global_mouse_position( ))/3.14)*180
	#print(d)
	$Marker2D.rotation = get_angle_to( get_global_mouse_position( ))
	if(position.x <next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(false)
				
	if(position.x >next_nav_position.x):
		$AnimatedSprite2D.set_flip_h(true)	
	var desired_velocity = global_position.direction_to(next_nav_position).normalized() * player_speed_multiplier
	
	#trigger a callback from velocity_computed signal
	nav_agent.set_velocity(desired_velocity)
	#if player arrive the target
	if nav_agent.is_navigation_finished() and Config.click.length() > 0:
		if Config.click == 'npc' and Config.enemyappear == 0: #if click on npc
			get_tree().get_root().get_node("main/UI/info").position = get_global_transform_with_canvas().origin
			get_tree().get_root().get_node("main/UI/info").toggle(Config.dialog1, 1)
		# if click on enemy1
		elif (Config.click == 'enemy1' or Config.click == 'boss1') : #and Input.is_action_just_released("ui_mouseleftclick"):
			if $hittimer.is_stopped() and (enemy1enter or bossenter) and attack:
				$hittimer.start() #use hittimer to control the frequency of attacking
				Config.click = '' #clear the click
				audio_player.play() #play the slash sound
				if enemy1enter: #if enemies enter into area2D of player 
					for enemy in enemy1body:
						enemy.hit()
						enemy.timer1() #show progressbar of enemy
				if bossenter:  #if boss enters into area2D of player 
					bossbody.hit()
					bossbody.timer1() #show progressbar of boss
				attack = false #wait for the hittimer
				#calculate the direction of attacking
				if (d>-22.5 and d<= 22.5) or ((d>-180 and d<-157.5) or (d>157.5 and d<180)):
					change_state(ATTACK90)
				elif (d>-67.5 and d<=-22.5) or (d>-157.5 and d<=-112.5):
					change_state(ATTACK45)
				elif (d>22.5 and d<=67.5) or (d>112.5 and d<=157.5):
					change_state(ATTACK135)
				elif (d>-112.5 and d<=-67.5):
					change_state(ATTACK0)
				else:
					change_state(ATTACK180)
			

func set_navigation_position(nav_destination : Vector2) -> void:
		
	# set the new player target location
	nav_agent.set_target_position(nav_destination)
	
	# calculate a new map path with the navigationserver
	player_nav_path = NavigationServer2D.map_get_path(nav_agent.get_navigation_map(), global_position, nav_destination, nav_optimize_path)
	

func character_path_changed() -> void:
	if $hittimer.is_stopped() and Config.player_death == 0:
		change_state(MOVE)
	
func character_target_reached() -> void:
	
	pass
	
func character_navigation_finished() -> void:
	
	if $hittimer.is_stopped() and Config.player_death == 0:
		change_state(IDLE)

func character_velocity_computed(calculated_velocity : Vector2) -> void:
	# check if nav agent target is reached
	if !nav_agent.is_target_reached() and Config.player_death == 0:
		# move and slide with the new calculated velocity
		set_velocity(calculated_velocity)
		move_and_slide()
		
func die():
	if Config.player_hitpoint <= 0:
		change_state(DIE)

func change_state(newState):
	state = newState
	match state: 
		DIE:
			$AnimatedSprite2D.play("death")
		IDLE:
			$AnimatedSprite2D.play("idle")
		MOVE:
			$AnimatedSprite2D.play("walk")
		ATTACK0:
			$AnimatedSprite2D.play("attack0")
		ATTACK45:
			$AnimatedSprite2D.play("attack45")
		ATTACK90:
			$AnimatedSprite2D.play("attack90")
		ATTACK135:
			$AnimatedSprite2D.play("attack135")
		ATTACK180:
			$AnimatedSprite2D.play("attack180")


func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("enemy1") :
		enemy1enter = true
		if not body in enemy1body: #if this one is not exsted in targets array, then add it
			enemy1body.append(body)
			body.timer1()
	if "boss" in body.name:
		bossenter = true
		bossbody = body
		body.timer1()


func _on_area_2d_body_exited(body: Node2D) -> void:
	
	if body.is_in_group("enemy1") :
		if body in enemy1body:
			enemy1body.erase(body)
		if enemy1body.size() == 0:
			enemy1enter = false
			attack = true
				
	if "boss" in body.name:
		bossenter = false

func _animation_finished():
	if $AnimatedSprite2D.animation == 'death':
		Config.player_death = 1
		#$CollisionShape2D.set_deferred("disabled", true)

func timer1():
	if $Timer.is_stopped():
		$ProgressBar.show()
		$Timer.one_shot = true
		$Timer.wait_time = Config.progressBarTime
		$Timer.start()

func _on_hittimer_timeout() -> void:
	attack = true
	
