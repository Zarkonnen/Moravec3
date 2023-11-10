@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	ItemType.loadTypes()
	print("Reloaded Item Types")
