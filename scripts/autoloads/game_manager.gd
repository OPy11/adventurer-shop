extends Node

## Main game state manager

signal day_changed(day: int)
signal gold_changed(amount: int)
signal reputation_changed(amount: int)
signal customer_arrived(customer: CustomerData)
signal notification_added(message: String, type: String)

# Game State
var current_day: int = 1
var gold: int = 500
var reputation: int = 50 # 0-100
var shop_name: String = "متجر المغامر"
var is_shop_open: bool = true

# Inventory
var inventory: Array[InventoryItem] = []
var materials: Dictionary = {} # material_id: quantity

# Active entities
var active_customers: Array[CustomerData] = []
var hired_adventurers: Array[AdventurerData] = []

# Statistics
var stats: Dictionary = {
	"total_sales": 0,
	"total_revenue": 0,
	"total_customers": 0,
	"happy_customers": 0,
	"angry_customers": 0,
	"items_crafted": 0,
	"missions_sent": 0,
	"missions_failed": 0
}

func _ready() -> void:
	print("[GameManager] Initialized")

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func remove_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func modify_reputation(amount: int) -> void:
	reputation = clampi(reputation + amount, 0, 100)
	reputation_changed.emit(reputation)

func add_to_inventory(item: InventoryItem) -> void:
	if not item or not item.item_data:
		return
	# Check if similar item exists
	for inv_item in inventory:
		if inv_item.item_data and inv_item.item_data.id == item.item_data.id and inv_item.quality == item.quality:
			inv_item.quantity += item.quantity
			return
	inventory.append(item)

func remove_from_inventory(item: InventoryItem, amount: int = 1) -> bool:
	if not item or not item.item_data:
		return false
	for i in range(inventory.size()):
		var inv_item := inventory[i]
		if inv_item.item_data and inv_item.item_data.id == item.item_data.id and inv_item.quality == item.quality:
			if inv_item.quantity >= amount:
				inv_item.quantity -= amount
				if inv_item.quantity <= 0:
					inventory.remove_at(i)
				return true
	return false

func add_material(material_id: String, amount: int) -> void:
	if material_id in materials:
		materials[material_id] += amount
	else:
		materials[material_id] = amount

func remove_material(material_id: String, amount: int) -> bool:
	if material_id in materials and materials[material_id] >= amount:
		materials[material_id] -= amount
		if materials[material_id] <= 0:
			materials.erase(material_id)
		return true
	return false

func has_materials(required: Dictionary) -> bool:
	for mat_id in required:
		if mat_id not in materials or materials[mat_id] < required[mat_id]:
			return false
	return true

func advance_day() -> void:
	current_day += 1
	# Age inventory
	for item in inventory:
		item.age_days += 1
		item.apply_age_discount()
	day_changed.emit(current_day)
	notify("يوم جديد: اليوم %d" % current_day, "info")

func notify(message: String, type: String = "info") -> void:
	notification_added.emit(message, type)

func record_sale(revenue: int, customer_happy: bool) -> void:
	stats.total_sales += 1
	stats.total_revenue += revenue
	stats.total_customers += 1
	if customer_happy:
		stats.happy_customers += 1
	else:
		stats.angry_customers += 1

func get_save_data() -> Dictionary:
	var inv_data: Array[Dictionary] = []
	for item in inventory:
		inv_data.append(item.to_dict())

	return {
		"current_day": current_day,
		"gold": gold,
		"reputation": reputation,
		"shop_name": shop_name,
		"inventory": inv_data,
		"materials": materials,
		"stats": stats
	}

func load_save_data(data: Dictionary) -> void:
	current_day = data.get("current_day", 1)
	gold = data.get("gold", 500)
	reputation = data.get("reputation", 50)
	shop_name = data.get("shop_name", "متجر المغامر")
	materials = data.get("materials", {})
	stats = data.get("stats", stats)

	# Load inventory
	inventory.clear()
	var inv_data: Array = data.get("inventory", [])
	for item_dict: Dictionary in inv_data:
		var item := InventoryItem.from_dict(item_dict, DataRegistry.items)
		if item.item_data:
			inventory.append(item)
