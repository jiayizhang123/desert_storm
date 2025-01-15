extends CollisionShape2D

func _ready():
	hide()

func _draw():
	var cen = Vector2(0,0)
	var rad =  40
	var col = Color(1,0,0,0.2)
	draw_circle(cen, rad, col)
