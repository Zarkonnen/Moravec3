class_name ItemContainer

const ANY_SLOT = -99

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
				if durability <= 0:
					var rotInto = ItemType.ofName(type.rotInto)
					if rotInto:
						type = rotInto
						durability = rotInto.durability
					else:
						type = null
						quantity = 0

var slots:Array = []
var size:int = 0:
	set(value):
		size = value
		slots.resize(value)
		slots = slots.map(func(s): return s if s else Slot.new())

func _init(sz=0):
	size = sz

func update(delta) -> bool:
	var changed = false
	for slot in slots:
		changed = slot.update(delta) or changed
	return changed

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
func add(it:ItemType, durability, quantity=1, preferredSlot=ANY_SLOT) -> int:
	if not it.canTake:
		return 0
	var remaining = quantity
	# Do we want a specific slot?
	if preferredSlot != ANY_SLOT:
		var slot = slots[preferredSlot]
		if slot.type == it:
			var canPut = min(remaining, it.stacking - slot.quantity)
			remaining -= canPut
			slot.durability = round((slot.durability * slot.quantity + durability * canPut) / (slot.quantity + canPut))
			slot.quantity += canPut
		elif not slot.type:
			var canPut = min(remaining, it.stacking)
			remaining -= canPut
			slot.type = it
			slot.durability = durability
			slot.quantity = canPut
			slot.rotTimer = it.rotInterval
		if remaining == 0:
			return quantity
	# Can we stack?
	for slot in slots:
		if slot.type == it:
			var canPut = min(remaining, it.stacking - slot.quantity)
			remaining -= canPut
			slot.durability = round((slot.durability * slot.quantity + durability * canPut) / (slot.quantity + canPut))
			slot.quantity += canPut
			if remaining == 0:
				return quantity
	# Find a new slot
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
func remove(it:ItemType, quantity:int=1, preferredSlot=ANY_SLOT):
	if not has(it, quantity):
		return null
	var q = quantity
	var durabilitySum = 0
	if preferredSlot != ANY_SLOT:
		var slot = slots[preferredSlot]
		if slot.type == it:
			var rm = min(quantity, slot.quantity)
			slot.quantity -= rm
			quantity -= rm
			durabilitySum += rm * slot.durability
			if slot.quantity == 0:
				slot.type = null
	if quantity:
		for slot in slots:
			if slot.type == it:
				var rm = min(quantity, slot.quantity)
				slot.quantity -= rm
				quantity -= rm
				durabilitySum += rm * slot.durability
				if slot.quantity == 0:
					slot.type = null
	return [it, round(durabilitySum / q)]
