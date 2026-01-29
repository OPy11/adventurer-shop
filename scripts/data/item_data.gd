class_name ItemData
extends Resource

@export var id: String = ""
@export var name_ar: String = ""
@export var name_en: String = ""
@export var description: String = ""
@export var category: Enums.ItemCategory = Enums.ItemCategory.WEAPON
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON
@export var base_price: int = 10
@export var crafting_time_hours: float = 1.0
@export var required_materials: Dictionary = {} # material_id: quantity
@export var stats: Dictionary = {} # stat_name: value
@export var icon_char: String = "?" # Unicode character for display

func get_display_name() -> String:
	return name_ar if name_ar else name_en

func calculate_price(quality: Enums.Quality, market_modifier: float = 1.0) -> int:
	var quality_mult := Enums.get_quality_multiplier(quality)
	var rarity_mult := 1.0 + (rarity * 0.5)
	return int(base_price * quality_mult * rarity_mult * market_modifier)

func _to_string() -> String:
	return "[ItemData: %s (%s)]" % [name_ar, id]
