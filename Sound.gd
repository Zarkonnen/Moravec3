extends AudioStreamPlayer2D

var byName = {}

func playSound(name, volume):
	if not name:
		return
	if playing:
		stop()
	if not name in byName:
		byName[name] = load("res://sfx/" + name + ".wav")
	self.volume_db = volume
	self.stream = byName[name]
	self.play()
