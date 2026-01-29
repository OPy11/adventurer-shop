extends Node

## Central registry for all game data

var items: Dictionary = {} # id: ItemData
var materials: Dictionary = {} # id: MaterialData
var suppliers: Dictionary = {} # id: SupplierData
var dungeons: Dictionary = {} # id: DungeonData

func _ready() -> void:
	print("[DataRegistry] Initializing game data...")
	_create_materials()
	_create_items()
	_create_suppliers()
	_create_dungeons()
	_register_with_economy()
	print("[DataRegistry] Loaded %d items, %d materials, %d suppliers" % [items.size(), materials.size(), suppliers.size()])

func _create_materials() -> void:
	# Common materials
	_add_material("iron_ore", "خام الحديد", "Iron Ore", Enums.Rarity.COMMON, 5, "ite")
	_add_material("copper_ore", "خام النحاس", "Copper Ore", Enums.Rarity.COMMON, 3, "▫")
	_add_material("leather", "جلد", "Leather", Enums.Rarity.COMMON, 8, "▤")
	_add_material("wood", "خشب", "Wood", Enums.Rarity.COMMON, 2, "▦")
	_add_material("cloth", "قماش", "Cloth", Enums.Rarity.COMMON, 4, "▨")

	# Uncommon
	_add_material("steel_ingot", "سبيكة فولاذ", "Steel Ingot", Enums.Rarity.UNCOMMON, 15, "▰")
	_add_material("silver_ore", "خام الفضة", "Silver Ore", Enums.Rarity.UNCOMMON, 20, "◊")
	_add_material("magic_herb", "عشبة سحرية", "Magic Herb", Enums.Rarity.UNCOMMON, 12, "♣")
	_add_material("monster_bone", "عظم وحش", "Monster Bone", Enums.Rarity.UNCOMMON, 18, "♠")

	# Rare
	_add_material("mithril_ore", "خام الميثريل", "Mithril Ore", Enums.Rarity.RARE, 50, "◆")
	_add_material("dragon_scale", "حرشفة تنين", "Dragon Scale", Enums.Rarity.RARE, 80, "◈")
	_add_material("phoenix_feather", "ريشة فينيكس", "Phoenix Feather", Enums.Rarity.RARE, 100, "❦")
	_add_material("arcane_crystal", "بلورة سحرية", "Arcane Crystal", Enums.Rarity.RARE, 60, "◇")

	# Epic
	_add_material("void_essence", "جوهر الفراغ", "Void Essence", Enums.Rarity.EPIC, 200, "●")
	_add_material("titan_heart", "قلب عملاق", "Titan Heart", Enums.Rarity.EPIC, 300, "♥")

	# Legendary
	_add_material("stardust", "غبار النجوم", "Stardust", Enums.Rarity.LEGENDARY, 500, "★")

func _add_material(id: String, name_ar: String, name_en: String, rarity: Enums.Rarity, price: int, icon: String) -> void:
	var mat := MaterialData.new()
	mat.id = id
	mat.name_ar = name_ar
	mat.name_en = name_en
	mat.rarity = rarity
	mat.base_price = price
	mat.icon_char = icon
	materials[id] = mat

func _create_items() -> void:
	# Weapons - Swords
	_add_item("iron_sword", "سيف حديدي", "Iron Sword", Enums.ItemCategory.WEAPON, Enums.Rarity.COMMON, 50, 2.0, {"iron_ore": 3, "wood": 1}, {"damage": 10}, "⚔")
	_add_item("steel_sword", "سيف فولاذي", "Steel Sword", Enums.ItemCategory.WEAPON, Enums.Rarity.UNCOMMON, 120, 4.0, {"steel_ingot": 2, "leather": 1}, {"damage": 20}, "⚔")
	_add_item("mithril_sword", "سيف ميثريل", "Mithril Sword", Enums.ItemCategory.WEAPON, Enums.Rarity.RARE, 350, 8.0, {"mithril_ore": 3, "arcane_crystal": 1}, {"damage": 40}, "⚔")
	_add_item("dragon_blade", "نصل التنين", "Dragon Blade", Enums.ItemCategory.WEAPON, Enums.Rarity.EPIC, 800, 16.0, {"dragon_scale": 5, "mithril_ore": 2, "void_essence": 1}, {"damage": 70}, "⚔")

	# Weapons - Daggers
	_add_item("iron_dagger", "خنجر حديدي", "Iron Dagger", Enums.ItemCategory.WEAPON, Enums.Rarity.COMMON, 25, 1.0, {"iron_ore": 1, "leather": 1}, {"damage": 5, "speed": 2}, "🗡")
	_add_item("shadow_dagger", "خنجر الظل", "Shadow Dagger", Enums.ItemCategory.WEAPON, Enums.Rarity.RARE, 250, 6.0, {"mithril_ore": 1, "void_essence": 1}, {"damage": 25, "speed": 5}, "🗡")

	# Armor
	_add_item("leather_armor", "درع جلدي", "Leather Armor", Enums.ItemCategory.ARMOR, Enums.Rarity.COMMON, 40, 2.0, {"leather": 5}, {"defense": 8}, "🛡")
	_add_item("chainmail", "درع حلقي", "Chainmail", Enums.ItemCategory.ARMOR, Enums.Rarity.UNCOMMON, 100, 5.0, {"steel_ingot": 4}, {"defense": 18}, "🛡")
	_add_item("plate_armor", "درع صفائح", "Plate Armor", Enums.ItemCategory.ARMOR, Enums.Rarity.RARE, 300, 10.0, {"steel_ingot": 8, "leather": 2}, {"defense": 35}, "🛡")
	_add_item("dragon_armor", "درع التنين", "Dragon Armor", Enums.ItemCategory.ARMOR, Enums.Rarity.EPIC, 1000, 24.0, {"dragon_scale": 10, "titan_heart": 1}, {"defense": 60}, "🛡")

	# Potions
	_add_item("health_potion", "جرعة صحة", "Health Potion", Enums.ItemCategory.POTION, Enums.Rarity.COMMON, 15, 0.5, {"magic_herb": 2}, {"heal": 30}, "🧪")
	_add_item("mana_potion", "جرعة مانا", "Mana Potion", Enums.ItemCategory.POTION, Enums.Rarity.COMMON, 20, 0.5, {"magic_herb": 2, "arcane_crystal": 1}, {"mana": 40}, "🧪")
	_add_item("strength_elixir", "إكسير القوة", "Strength Elixir", Enums.ItemCategory.POTION, Enums.Rarity.UNCOMMON, 60, 1.5, {"monster_bone": 2, "magic_herb": 3}, {"strength": 15}, "🧪")
	_add_item("phoenix_elixir", "إكسير الفينيكس", "Phoenix Elixir", Enums.ItemCategory.POTION, Enums.Rarity.EPIC, 400, 4.0, {"phoenix_feather": 2, "void_essence": 1}, {"revive": 1}, "🧪")

	# Accessories
	_add_item("silver_ring", "خاتم فضي", "Silver Ring", Enums.ItemCategory.ACCESSORY, Enums.Rarity.UNCOMMON, 80, 2.0, {"silver_ore": 2}, {"luck": 5}, "💍")
	_add_item("arcane_amulet", "تميمة سحرية", "Arcane Amulet", Enums.ItemCategory.ACCESSORY, Enums.Rarity.RARE, 200, 4.0, {"arcane_crystal": 3, "silver_ore": 1}, {"magic": 20}, "📿")
	_add_item("star_pendant", "قلادة النجوم", "Star Pendant", Enums.ItemCategory.ACCESSORY, Enums.Rarity.LEGENDARY, 1500, 12.0, {"stardust": 5, "arcane_crystal": 3}, {"all_stats": 10}, "⭐")

func _add_item(id: String, name_ar: String, name_en: String, category: Enums.ItemCategory, rarity: Enums.Rarity, price: int, craft_time: float, mats: Dictionary, stats: Dictionary, icon: String) -> void:
	var item := ItemData.new()
	item.id = id
	item.name_ar = name_ar
	item.name_en = name_en
	item.category = category
	item.rarity = rarity
	item.base_price = price
	item.crafting_time_hours = craft_time
	item.required_materials = mats
	item.stats = stats
	item.icon_char = icon
	items[id] = item

func _create_suppliers() -> void:
	_add_supplier("ahmad_blacksmith", "أحمد الحداد", Enums.SupplierType.BLACKSMITH, Enums.Quality.STANDARD, 0.6, 80, 1.0, ["iron_sword", "steel_sword"], "👨‍🔧")
	_add_supplier("master_forge", "الأسطى حسن", Enums.SupplierType.BLACKSMITH, Enums.Quality.EXCELLENT, 0.85, 200, 0.8, ["mithril_sword", "dragon_blade", "plate_armor"], "👴")
	_add_supplier("salma_alchemist", "سلمى الكيميائية", Enums.SupplierType.ALCHEMIST, Enums.Quality.GOOD, 0.7, 60, 1.2, ["health_potion", "mana_potion", "strength_elixir"], "👩‍🔬")
	_add_supplier("old_wizard", "الساحر العجوز", Enums.SupplierType.ENCHANTER, Enums.Quality.MASTERWORK, 0.9, 300, 0.6, ["arcane_amulet", "star_pendant"], "🧙")
	_add_supplier("tarek_leather", "طارق الجلاد", Enums.SupplierType.LEATHERWORKER, Enums.Quality.STANDARD, 0.65, 50, 1.1, ["leather_armor"], "👨‍🏭")

func _add_supplier(id: String, name_ar: String, type: Enums.SupplierType, quality: Enums.Quality, mastery: float, cost: int, speed: float, specs: PackedStringArray, portrait: String) -> void:
	var sup := SupplierData.new()
	sup.id = id
	sup.name_ar = name_ar
	sup.supplier_type = type
	sup.quality_level = quality
	sup.mastery = mastery
	sup.contract_cost = cost
	sup.crafting_speed = speed
	sup.specialties = specs
	sup.portrait_char = portrait
	suppliers[id] = sup

func _create_dungeons() -> void:
	dungeons["goblin_cave"] = {
		"id": "goblin_cave",
		"name_ar": "كهف العفاريت",
		"difficulty": Enums.MissionDifficulty.EASY,
		"duration_hours": 4,
		"rewards": {"iron_ore": 5, "copper_ore": 3, "leather": 2},
		"risk": 0.1
	}
	dungeons["haunted_forest"] = {
		"id": "haunted_forest",
		"name_ar": "الغابة المسكونة",
		"difficulty": Enums.MissionDifficulty.MEDIUM,
		"duration_hours": 8,
		"rewards": {"magic_herb": 4, "monster_bone": 3, "wood": 5},
		"risk": 0.2
	}
	dungeons["dragon_lair"] = {
		"id": "dragon_lair",
		"name_ar": "عرين التنين",
		"difficulty": Enums.MissionDifficulty.HARD,
		"duration_hours": 16,
		"rewards": {"dragon_scale": 2, "mithril_ore": 3, "arcane_crystal": 2},
		"risk": 0.35
	}
	dungeons["void_realm"] = {
		"id": "void_realm",
		"name_ar": "عالم الفراغ",
		"difficulty": Enums.MissionDifficulty.DEADLY,
		"duration_hours": 24,
		"rewards": {"void_essence": 2, "titan_heart": 1, "stardust": 1},
		"risk": 0.5
	}

func _register_with_economy() -> void:
	for item_id in items:
		EconomyManager.register_item(item_id, items[item_id].base_price)
	for mat_id in materials:
		EconomyManager.register_material(mat_id)

func get_item(id: String) -> ItemData:
	return items.get(id)

func get_material(id: String) -> MaterialData:
	return materials.get(id)

func get_supplier(id: String) -> SupplierData:
	return suppliers.get(id)

func get_dungeon(id: String) -> Dictionary:
	return dungeons.get(id, {})

func get_items_by_category(category: Enums.ItemCategory) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in items.values():
		if item.category == category:
			result.append(item)
	return result

func get_craftable_items(available_materials: Dictionary) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in items.values():
		var can_craft := true
		for mat_id in item.required_materials:
			if mat_id not in available_materials or available_materials[mat_id] < item.required_materials[mat_id]:
				can_craft = false
				break
		if can_craft:
			result.append(item)
	return result
