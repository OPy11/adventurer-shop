class_name SupplierData
extends Resource

@export var id: String = ""
@export var name_ar: String = ""
@export var supplier_type: Enums.SupplierType = Enums.SupplierType.BLACKSMITH
@export var quality_level: Enums.Quality = Enums.Quality.STANDARD
@export var mastery: float = 0.5 # 0.0 to 1.0 - affects success rate
@export var contract_cost: int = 100 # Upfront cost
@export var crafting_speed: float = 1.0 # Multiplier for crafting time
@export var specialties: PackedStringArray = [] # Item IDs they excel at
@export var reputation: int = 50 # 0-100
@export var portrait_char: String = "P" # Unicode for portrait

var current_order: Dictionary = {} # Active crafting order
var is_available: bool = true

func get_effective_quality() -> Enums.Quality:
	# Mastery can improve quality
	var quality_boost := int(mastery * 2)
	return mini(quality_level + quality_boost, Enums.Quality.MASTERWORK) as Enums.Quality

func get_crafting_time(base_time: float) -> float:
	return base_time / crafting_speed

func calculate_order_cost(item: ItemData, quantity: int) -> int:
	var base := item.base_price * quantity
	var quality_mult := Enums.get_quality_multiplier(quality_level)
	var specialty_discount := 0.9 if item.id in specialties else 1.0
	return int(base * quality_mult * specialty_discount * 0.6) + contract_cost

func get_type_name() -> String:
	match supplier_type:
		Enums.SupplierType.BLACKSMITH: return "حداد"
		Enums.SupplierType.ALCHEMIST: return "كيميائي"
		Enums.SupplierType.ENCHANTER: return "ساحر تعويذات"
		Enums.SupplierType.LEATHERWORKER: return "صانع جلود"
		_: return "مورد"
