extends Node2D

var t = 90
@export var dayRamp:Texture2D = null

const DAWN_LENGTH = 100
const DAYLIGHT_LENGTH = 600
const DUSK_LENGTH = 100
const NIGHT_LENGTH = 300
const DAY_LENGTH = DAWN_LENGTH + DAYLIGHT_LENGTH + DUSK_LENGTH + NIGHT_LENGTH
const FLOOD_CYCLE_LENGTH = 4000
const WEATHER_MIN_LENGTH = 200
const WEATHER_MAX_LENGTH = 400
const WEATHER_P_PER_SECOND = 0.02
const WEATHER_FADE = 4
const WEATHER_BRIGHTNESS_MULT = 0.7
const WIND_MAX = 0.5

var flooded = false
var weatherT = 0
var weatherLength = 0
var wind = 0

func ambient() -> Color:
	var a:Color = dayNightAmbient()
	var mult = 1.0
	if weatherLength > 0:
		if weatherT < WEATHER_FADE:
			mult = lerp(1.0, WEATHER_BRIGHTNESS_MULT, weatherT / WEATHER_FADE)
		elif weatherT > weatherLength - WEATHER_FADE:
			mult = lerp(WEATHER_BRIGHTNESS_MULT, 1.0, (weatherT - (weatherLength - WEATHER_FADE)) / weatherLength)
		else:
			mult = WEATHER_BRIGHTNESS_MULT
	return Color(a.r * mult, a.g * mult, a.b * mult)
	
func dayNightAmbient() -> Color:
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
	var inPeriod = fmod(t, DAY_LENGTH)
	if inPeriod < DAWN_LENGTH:
		return 5 + 10 * inPeriod / DAWN_LENGTH
	inPeriod -= DAWN_LENGTH
	if inPeriod < DAYLIGHT_LENGTH / 2:
		return 15 + 8 * inPeriod / (DAYLIGHT_LENGTH / 2)
	inPeriod -= DAYLIGHT_LENGTH / 2
	if inPeriod < DAYLIGHT_LENGTH / 2:
		return 23 - 8 * inPeriod / (DAYLIGHT_LENGTH / 2)
	inPeriod -= DAYLIGHT_LENGTH / 2
	if inPeriod < DUSK_LENGTH:
		return 15 - 5 * inPeriod / DUSK_LENGTH
	inPeriod -= DUSK_LENGTH
	return 10 - 5 * inPeriod / NIGHT_LENGTH

func moveSpeedMult() -> float:
	return 1.0 - abs(wind)

func wetnessPerTime() -> float:
	return 2 if weatherLength > 0 else -1

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
	if weatherLength > 0:
		weatherT += delta
		if weatherT >= weatherLength:
			weatherT = 0
			wind = 0
	elif randf_range(0, 1) < delta * WEATHER_P_PER_SECOND:
		weatherLength = randf_range(WEATHER_MIN_LENGTH, WEATHER_MAX_LENGTH)
		weatherT = 0
		wind = randf_range(-WIND_MAX, WIND_MAX)
	if weatherLength > 0:
		$Rain.emitting = temperature() >= 0
		$Snow.emitting = not $Rain.emitting
	else:
		$Rain.emitting = false
		$Snow.emitting = false
	$Rain.process_material.direction.x = wind * 3
	$Snow.process_material.direction.x = wind
