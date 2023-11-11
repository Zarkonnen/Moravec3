extends Node

var t = 5
@export var dayRamp:Texture2D = null

const DAWN_LENGTH = 10
const DAYLIGHT_LENGTH = 60
const DUSK_LENGTH = 10
const NIGHT_LENGTH = 30
const DAY_LENGTH = DAWN_LENGTH + DAYLIGHT_LENGTH + DUSK_LENGTH + NIGHT_LENGTH
const FLOOD_CYCLE_LENGTH = 400

var flooded = false

func ambient() -> Color:
	var inPeriod = fmod(t, DAY_LENGTH)
	var w = dayRamp.get_image().get_width()
	var img = dayRamp.get_image()
	if inPeriod < DAWN_LENGTH:
		return img.get_pixel(int(w / 2 * inPeriod / DAWN_LENGTH), 0)
	inPeriod -= DAWN_LENGTH
	if inPeriod < DAYLIGHT_LENGTH:
		return img.get_pixel(int(w / 2), 0)
	inPeriod -= DAYLIGHT_LENGTH
	if inPeriod < DUSK_LENGTH:
		return img.get_pixel(int(w / 2 + w / 2 * inPeriod / DUSK_LENGTH), 0)
	else:
		return img.get_pixel(w - 1, 0)

func brightness() -> float:
	return ambient().v

func temperature() -> float:
	return 20

func moveSpeedMult() -> float:
	return 1.0

func wetnessPerTime() -> float:
	return 0

func setFlood(flood:bool):
	if flood == flooded:
		return
	flooded = flood
	var from = Vector2i(2, 5) if flood else Vector2i(6, 15)
	var to = Vector2i(2, 5) if not flood else Vector2i(6, 15)
	var w:TileMap = %World 
	var muds = w.get_used_cells_by_id(0, -1, from)
	for c in muds:
		w.set_cell(0, c, 0, to)

func _process(delta):
	t += delta
	$Ambient.color = ambient()
	setFlood(fmod(t, FLOOD_CYCLE_LENGTH) > FLOOD_CYCLE_LENGTH / 2)
