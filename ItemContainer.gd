class_name ItemContainer

class Slot:
	var type:ItemType = null
	var quantity:int = 0
	var durability:int = 1
	var rotTimer:float = 0
	func update(delta):
		if type and type.rotInterval:
			rotTimer -= delta
			if rotTimer <= 0:
				durability -= 1
				rotTimer = type.rotInterval
				if quantity <= 0:
					var rotInto = ItemType.ofName(type.rotInto)
					if rotInto:
						type = rotInto
						durability = rotInto.durability
					else:
						type = null

var slots:Array = []
var size:int = 0:
	set(value):
		size = value
		slots.resize(value)
		slots = slots.map(func(s): return s if s else Slot.new())

func _init(sz=0):
	size = sz

func isEmpty():
	return slots.all(func(s): return s.quantity <= 0)

func g(index) -> Slot:
	if index >= 0 and index < size:
		return slots[index]
	else:
		return Slot.new()

func has(it:ItemType, quantity:int=1) -> bool:
	for slot in slots:
		if slot.type == it:
			quantity -= slot.quantity
	return quantity <= 0
	
func useTool(i:int, it:ItemType, toolDurabilityChange:int) -> bool:
	if not toolDurabilityChange:
		return false
	var slot = g(i)
	if slot.type != it:
		slot = Util.first(slots, func(s): return s.type == it)
	if not slot:
		return false
	slot.durability += toolDurabilityChange
	if slot.durability <= 0:
		slot.quantity -= 1
	if slot.quantity <= 0:
		slot.type = null
	return true

# Returns the number of successfully added items.
func add(it:ItemType, durability, quantity=1) -> int:
	if not it.canTake:
		return 0
	# Can we stack?
	var remaining = quantity
	for slot in slots:
		if slot.type == it:
			var canPut = min(remaining, it.stacking - slot.quantity)
			remaining -= canPut
			slot.durability = round((slot.durability * slot.quantity + durability * canPut) / (slot.quantity + canPut))
			slot.quantity += canPut
			if remaining == 0:
				return quantity
	for slot in slots:
		if slot.type == null:
			var canPut = min(remaining, it.stacking)
			remaining -= canPut
			slot.type = it
			slot.durability = durability
			slot.quantity = canPut
			slot.rotTimer = it.rotInterval
			if remaining == 0:
				return quantity
	return quantity - remaining

# Returns [item type, durability]
func remove(it:ItemType, quantity:int=1):
	if not has(it, quantity):
		return null
	var q = quantity
	var durabilitySum = 0
	for slot in slots:
		if slot.type == it:
			var rm = min(quantity, slot.quantity)
			slot.quantity -= rm
			quantity -= rm
			durabilitySum += rm * slot.durability
			if slot.quantity == 0:
				slot.type = null
	return [it, round(durabilitySum / q)]
