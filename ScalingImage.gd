extends TextureRect

@export var offset:Vector2 = Vector2(10, 10)
@export var maxSize:Vector2 = Vector2(40, 40)

func setImage(region:Rect2):
	texture.region = region
	if region.size.x <= maxSize.x and region.size.y <= maxSize.y:
		expand_mode = TextureRect.EXPAND_KEEP_SIZE
		size = region.size
	elif region.size.x / maxSize.x > region.size.y / maxSize.y:
		# Use scaling of x-axis
		expand_mode = TextureRect.EXPAND_FIT_WIDTH
		size = Vector2(maxSize.x, region.size.y * maxSize.x / region.size.x)
	else:
		# Use scaling of y-axis
		expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		size = Vector2(region.size.x * maxSize.y / region.size.y, maxSize.y)
	position = offset + maxSize / 2 - size / 2
