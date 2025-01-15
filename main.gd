extends Control

@onready var enemy_scene = preload("res://enemy1.tscn")
@onready var boss_scene = preload("res://boss1.tscn")
@onready var nav2D : NavigationRegion2D = $NavigationRegion2D
@onready var line2D : Line2D = $Line2D
@onready var player = $player
@onready var npc = $npc


var map
var enemy1number = 0
var boss
var audio_player
var audio_player1
var audio_player2

func _ready() -> void:
	var world_2d = get_viewport().world_2d
	npc.set_navigation_position($mark/Marker2D.global_position)
	#UI menu
	get_tree().get_root().get_node("main/UI/ColorRect").position =get_global_transform().affine_inverse() *Vector2.ZERO
	#initiated
	$UI/ColorRect.show()
	player.hide()
	npc.hide()
	audio_player = AudioStreamPlayer.new() 
	audio_player1 = AudioStreamPlayer.new()
	audio_player2 = AudioStreamPlayer.new()  
	add_child(audio_player)
	add_child(audio_player1)
	add_child(audio_player2)
	audio_player.stream = load('res://asset/templateswise-1003.mp3') #background music
	audio_player1.stream = preload('res://asset/mixkit-winning-chimes-2015.wav') #win sound
	audio_player2.stream = preload('res://asset/mixkit-wrong-answer-fail-notification-946.wav') #lose sound
	audio_player.stream.loop = true
	audio_player.play()
	

func _process(_delta : float) -> void:
	#game lose
	if (Config.player_death == 1 or Config.npc_death == 1) and Config.restart ==0:
		Config.restart = 1
		#if not audio_player2.is_playing() and Config.restart ==0:
		audio_player2.play()
		
		for body in get_tree().get_nodes_in_group("enemy1"):
			body.queue_free()
		for body in get_tree().get_nodes_in_group("boss"):
			body.queue_free()
		$UI/ColorRect/RichTextLabel.text = "[center][b]You lose\nRetry?"
		level()
	#game win
	if Config.player_hitpoint > 0 and Config.boss_death == 1 and Config.restart ==0:
		Config.restart = 1 #stop repeating execute code in process
		#if not audio_player1.is_playing() and Config.restart ==0:
		audio_player1.play()
			
		await get_tree().create_timer(2).timeout #wait 2 seconds
		for body in get_tree().get_nodes_in_group("enemy1"):
			body.queue_free()
		for body in get_tree().get_nodes_in_group("boss"):
			body.queue_free()
		$UI/ColorRect/RichTextLabel.text = "[center][b]You win\nRetry?"
		level()
	#running in level1
	if Config.level == 1:
		if Config.enemyappear ==1 and $enemytimer.is_stopped():
			$enemytimer.wait_time =3
			$enemytimer.start() #start to generate the enemies
		if !$enemytimer.is_stopped(): #if timer stop, stop chasing player
			get_tree().call_group("enemy1","set_navigation_position",npc.global_transform.origin)
		#level complete
		if Config.enemy1num_d == Config.enemy1num and Config.npc_death == 0:
			Config.enemy1num_d = 0
			audio_player1.play()
			Config.enemyappear = 0
			get_tree().get_root().get_node("main/UI/info").position = _get_viewport_center()
			get_tree().get_root().get_node("main/UI/info").toggle(Config.dialog2, 2)
	#running in level2
	if Config.level == 2:
		if Config.enemyappear == 0:
			Config.enemyappear = 1
			$player/Camera2D.limit_left = 1200
			$player/Camera2D.limit_right = 3000
			Config.player_shell = 20 #set shell of player
			Config.player_hitpoint = 10
			player.get_node("CollisionShape2D").show() #show the shell
			player.global_position = $mark/Marker2D3.global_position
			player.set_navigation_position($mark/Marker2D3.global_transform.origin)
			$enemytimer.wait_time =2
			$enemytimer.start() #start to generate the enemies
			boss = boss_scene.instantiate()
			add_child(boss) #add boss
			boss.global_position = $mark/Marker2D4.global_position
			
		get_tree().call_group("enemy1","set_navigation_position",player.global_transform.origin)
		if Config.boss_death == 0 and Config.restart == 0:
			boss.set_navigation_position(player.global_transform.origin)

func _get_viewport_center() -> Vector2:
	var transform : Transform2D = get_viewport_transform()
	var scale : Vector2 = transform.get_scale()
	return get_viewport_rect().size / scale / 2.4
	#return -transform.origin / scale + get_viewport_rect().size / scale / 2

func _input(event): #detect input of mouse
	if Input.is_action_pressed("test"): #right button
		if Config.test == 0:
			Config.test = 1
			$player/Marker2D/Marker2D/Area2D/CollisionShape2D8.show()
		else:
			Config.test = 0
			$player/Marker2D/Marker2D/Area2D/CollisionShape2D8.hide()
	if !Input.is_action_pressed("ui_mouseleftclick"): #left button
		return
	player.set_navigation_position(get_global_mouse_position()) #set player target
	
	Config.click = '' #clear click
	
#when timeout, generate enemies
func _on_enemytimer_timeout() -> void:
	if Config.level == 1:
		if enemy1number < Config.enemy1num:
			var enemy = enemy_scene.instantiate()
			var s = "mark/mark"+str(randi_range(1,4)) #random place
			var enemy_spawn_location = get_node(s)
			
			add_child(enemy)
			
			enemy.position = enemy_spawn_location.global_position
			enemy.set_navigation_position($npc.position)
			enemy1number += 1
	
	if Config.level == 2:
		if enemy1number < Config.enemy2num:
			#random place by path2D
			var enemy = enemy_scene.instantiate()
			var enemy_spawn_location = get_node("enemypath/enemypathfollow")
			enemy_spawn_location.progress_ratio = randf()
			add_child(enemy)
			
			enemy.position = enemy_spawn_location.global_position
			enemy.set_navigation_position(player.position)
			enemy1number += 1

func level(): #show UI and hide playere and npc
	$UI/ColorRect.show()
	player.hide()
	npc.hide()

# when accept button is accepted (restart or next level)
func _on_button_pressed() -> void:
	$UI/ColorRect.hide()
	player.show()
	npc.show()
	if Config.restart == 1: #if game restarts,reset
		Config.level = 1
		Config.restart = 0
		Config.player_hitpoint = 10
		Config.npc_hitpoint = 2
		Config.npc_death = 0
		Config.enemyappear = 0
		Config.enemy1num = 5
		Config.enemy2num = 20
		Config.enemy1num_d = 0
		Config.boss_death = 0
		Config.player_shell = 20
		Config.player_death = 0
		player.get_node("CollisionShape2D").hide()
		enemy1number = 0
		$enemytimer.stop()
		$player/ProgressBar.hide()
		$npc/ProgressBar.hide()
		$player/Camera2D.limit_left = -1000
		$player/Camera2D.limit_right = 1000
		player.global_position = Vector2(-139, -83)
		player.set_navigation_position(Vector2(-139, -83))
		$UI/ColorRect/RichTextLabel.text = "[center][b]Desert Storm\n\nLevel 1"
	else: # or next level
		Config.level +=1
		if Config.level == 1:
			$UI/ColorRect/RichTextLabel.text = "[center][b]Desert Storm\n\nLevel 2"
		
