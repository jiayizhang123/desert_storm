extends Node

var click = ''
var enemyappear = 0 #flag for starting of enemies
var enemy1num = 5 #number of enemies in level1
var enemy2num = 20 #number of enemies in level2
var enemy1num_d = 0 #number of dead enemies 
var npc_hitpoint = 2 
var enemy1_hitpoint = 2
var boss_hitpoint = 30
var player_hitpoint = 10
var player_attack = 0 #attack control flag
var player_attackd = 0 #0,45, 90, 135,180,225,270,315
var player_death = 0
var player_shell = 0
var level= 0
var npc_death = 0
var boss_death = 0
var progressBarTime = 3 
var restart = 0
var dialog1 = "Please help us, monsters are coming..."
var dialog2 = "Enhanced protection armed..."
var test = 0 #debug for showing the attack direction
