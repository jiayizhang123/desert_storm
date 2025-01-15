extends Control

var tween1 :Tween
var eventid = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$RichTextLabel.text = Config.dialog1
	clear()


func toggle(txt, eventi): #show message window according to event
	eventid = eventi
	$RichTextLabel.text = txt
	$Button.visible = false
	#$RichTextLabel.visible = false
	self.visible = true
	$RichTextLabel.visible = true
	$RichTextLabel.visible_ratio = 0
	tween1 = create_tween()
	#tween1.bind_node(self)
	tween1.tween_property($RichTextLabel,"visible_ratio",1,1)
	#show confirmation button when total message is showed 
	tween1.connect("finished",Callable(self,"effect_completed")) 
	tween1.play()
	
	
func effect_completed():
	$Button.visible = true
	
func clear(): #hide message window
	self.visible = false
	$RichTextLabel.visible = false
	$Button.visible = false


func _on_button_pressed() -> void:
	if eventid == 1: #after conversation with NPC
		Config.click = ''
		Config.enemyappear = 1
	elif eventid == 2: #after completing the level 1
		get_tree().get_root().get_node("main").level()
	clear()
