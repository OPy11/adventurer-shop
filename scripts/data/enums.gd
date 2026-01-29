class_name Enums
extends RefCounted

## Item Categories
enum ItemCategory {
	WEAPON,
	ARMOR,
	POTION,
	ACCESSORY,
	MATERIAL
}

## Item Rarity
enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

## Quality Levels
enum Quality {
	POOR,
	STANDARD,
	GOOD,
	EXCELLENT,
	MASTERWORK
}

## Supplier Types
enum SupplierType {
	BLACKSMITH,
	ALCHEMIST,
	ENCHANTER,
	LEATHERWORKER
}

## Customer Types
enum CustomerType {
	BEGINNER_ADVENTURER,
	EXPERIENCED_ADVENTURER,
	VETERAN_ADVENTURER,
	KNIGHT,
	MAGE,
	MERCHANT
}

## Mission Difficulty
enum MissionDifficulty {
	EASY,
	MEDIUM,
	HARD,
	DEADLY
}

## Customer Mood
enum CustomerMood {
	HAPPY,
	NEUTRAL,
	ANNOYED,
	ANGRY
}

## Transaction Result
enum TransactionResult {
	PURCHASED,
	NEGOTIATED,
	REJECTED,
	LEFT_ANGRY
}

## Helper functions
static func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON: return Color.WHITE
		Rarity.UNCOMMON: return Color.GREEN
		Rarity.RARE: return Color.CORNFLOWER_BLUE
		Rarity.EPIC: return Color.MEDIUM_PURPLE
		Rarity.LEGENDARY: return Color.GOLD
		_: return Color.WHITE

static func get_quality_multiplier(quality: Quality) -> float:
	match quality:
		Quality.POOR: return 0.7
		Quality.STANDARD: return 1.0
		Quality.GOOD: return 1.3
		Quality.EXCELLENT: return 1.6
		Quality.MASTERWORK: return 2.0
		_: return 1.0

static func get_rarity_name(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON: return "عادي"
		Rarity.UNCOMMON: return "غير شائع"
		Rarity.RARE: return "نادر"
		Rarity.EPIC: return "ملحمي"
		Rarity.LEGENDARY: return "أسطوري"
		_: return "غير معروف"

static func get_quality_name(quality: Quality) -> String:
	match quality:
		Quality.POOR: return "رديء"
		Quality.STANDARD: return "قياسي"
		Quality.GOOD: return "جيد"
		Quality.EXCELLENT: return "ممتاز"
		Quality.MASTERWORK: return "تحفة"
		_: return "غير معروف"

static func get_customer_type_name(customer_type: CustomerType) -> String:
	match customer_type:
		CustomerType.BEGINNER_ADVENTURER: return "مغامر مبتدئ"
		CustomerType.EXPERIENCED_ADVENTURER: return "مغامر خبير"
		CustomerType.VETERAN_ADVENTURER: return "مغامر محترف"
		CustomerType.KNIGHT: return "فارس"
		CustomerType.MAGE: return "ساحر"
		CustomerType.MERCHANT: return "تاجر"
		_: return "زبون"
