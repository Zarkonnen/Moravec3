extends Control

var recipe:Recipe = null

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		$/root/Node2D/GUI/Crafts.craft(recipe)
		$/root/Node2D/World.ignoreTimer = 0.5
