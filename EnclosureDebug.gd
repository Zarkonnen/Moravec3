extends Node2D

func _draw():
	#for y in range(-10, 10):
	#	for x in range(-10, 10):
	#		if %Walls.g(x, y):
	#			draw_rect(Rect2(x * 128, y * 96, 128, 96), Color.GREEN)
	for enc in %Grid.enclosures:
		#print(str(enc.number))
		#print(enc.hasCeilings)
		var clr = Color(fmod(enc.number * 0.3, 1), fmod(enc.number * 0.1, 1), fmod(enc.number * 0.07, 1))
		for t in enc.tiles:
			draw_rect(Rect2(t[0] * 128 + 16, t[1] * 96 + 16, 128 - 32, 96 - 32), clr)
			if enc.hasCeilings:
				draw_rect(Rect2(t[0] * 128 + 32, t[1] * 96 + 32, 128 - 64, 96 - 64), Color.WHITE)
