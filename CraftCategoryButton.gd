extends Control

var index = 0

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		$/root/Node2D/GUI/Crafts.category = Recipe.categories[index]
		$/root/Node2D/GUI/Crafts.hideCrafting()
		$/root/Node2D/GUI/Crafts.showCrafting()
		$/root/Node2D/World.ignoreNextClick = true

