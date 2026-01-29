class_name CustomerData
extends Resource

@export var id: String = ""
@export var name_ar: String = ""
@export var customer_type: Enums.CustomerType = Enums.CustomerType.BEGINNER_ADVENTURER
@export var budget: int = 100
@export var patience: float = 1.0 # How long they wait
@export var haggle_skill: float = 0.3 # 0-1, affects negotiation
@export var portrait_char: String = "C"

var current_mood: Enums.CustomerMood = Enums.CustomerMood.NEUTRAL
var wanted_items: Array[String] = [] # Item IDs they want
var price_tolerance: float = 1.2 # Max price multiplier they accept

func get_budget_range() -> Dictionary:
	match customer_type:
		Enums.CustomerType.BEGINNER_ADVENTURER:
			return {"min": 50, "max": 200}
		Enums.CustomerType.EXPERIENCED_ADVENTURER:
			return {"min": 150, "max": 500}
		Enums.CustomerType.VETERAN_ADVENTURER:
			return {"min": 400, "max": 1500}
		Enums.CustomerType.KNIGHT:
			return {"min": 500, "max": 2000}
		Enums.CustomerType.MAGE:
			return {"min": 300, "max": 1800}
		Enums.CustomerType.MERCHANT:
			return {"min": 200, "max": 3000}
		_:
			return {"min": 50, "max": 500}

func evaluate_price(asking_price: int, fair_price: int, shop_reputation: int) -> Dictionary:
	var price_ratio := float(asking_price) / float(fair_price)
	var reputation_bonus := (shop_reputation - 50) * 0.005 # +/-2.5% at extremes
	var adjusted_tolerance := price_tolerance + reputation_bonus

	var result := {
		"will_buy": false,
		"will_negotiate": false,
		"mood_change": 0,
		"message": ""
	}

	if price_ratio <= 0.9:
		# Great deal!
		result.will_buy = true
		result.mood_change = 1
		result.message = "سعر ممتاز! صفقة رابحة!"
	elif price_ratio <= 1.0:
		# Fair price
		result.will_buy = true
		result.mood_change = 0
		result.message = "سعر عادل."
	elif price_ratio <= adjusted_tolerance:
		# Acceptable but might negotiate
		if randf() < haggle_skill:
			result.will_negotiate = true
			result.message = "هل يمكن تخفيض السعر قليلاً؟"
		else:
			result.will_buy = true
			result.mood_change = -1
			result.message = "غالي شوي... لكن ماشي."
	elif price_ratio <= adjusted_tolerance * 1.2:
		# Too expensive, will negotiate or leave
		result.will_negotiate = true
		result.mood_change = -1
		result.message = "هذا غالي جداً! لازم تخفض."
	else:
		# Way too expensive
		result.will_buy = false
		result.mood_change = -2
		result.message = "أنت تسرق الناس! رايح للمنافسين."

	return result

func update_mood(change: int) -> void:
	var new_mood := clampi(current_mood + change, 0, 3)
	current_mood = new_mood as Enums.CustomerMood
