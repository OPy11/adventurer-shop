class_name MaterialData
extends Resource

@export var id: String = ""
@export var name_ar: String = ""
@export var name_en: String = ""
@export var description: String = ""
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON
@export var base_price: int = 5
@export var icon_char: String = "*"
@export var dungeon_source: String = "" # Which dungeon drops this
@export var drop_chance: float = 0.5 # Base drop chance

func get_display_name() -> String:
	return name_ar if name_ar else name_en

func get_market_price(scarcity: float = 1.0) -> int:
	var rarity_mult := 1.0 + (rarity * 0.3)
	return int(base_price * rarity_mult * scarcity)

func _to_string() -> String:
	return "[MaterialData: %s (%s)]" % [name_ar, id]
