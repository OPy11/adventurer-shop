class_name InventoryItem
extends RefCounted

var item_data: ItemData
var quality: Enums.Quality = Enums.Quality.STANDARD
var quantity: int = 1
var purchase_price: int = 0 # What we paid
var listed_price: int = 0 # Our selling price
var age_days: int = 0 # How long in inventory

func _init(data: ItemData = null, qty: int = 1, qual: Enums.Quality = Enums.Quality.STANDARD) -> void:
	item_data = data
	quantity = qty
	quality = qual
	if data:
		listed_price = data.calculate_price(quality)

func get_fair_price() -> int:
	if not item_data:
		return 0
	return item_data.calculate_price(quality)

func get_profit_margin() -> float:
	if purchase_price <= 0:
		return 0.0
	return float(listed_price - purchase_price) / float(purchase_price)

func is_overpriced(market_price: int) -> bool:
	return listed_price > market_price * 1.3

func is_underpriced(market_price: int) -> bool:
	return listed_price < market_price * 0.8

func apply_age_discount() -> void:
	# Old stock gets discounted
	if age_days > 7:
		var discount := minf(age_days * 0.02, 0.4) # Max 40% discount
		listed_price = int(listed_price * (1.0 - discount))

func to_dict() -> Dictionary:
	return {
		"item_id": item_data.id if item_data else "",
		"quality": quality,
		"quantity": quantity,
		"purchase_price": purchase_price,
		"listed_price": listed_price,
		"age_days": age_days
	}

static func from_dict(data: Dictionary, item_registry: Dictionary) -> InventoryItem:
	var item := InventoryItem.new()
	var item_id: String = data.get("item_id", "")
	if item_id in item_registry:
		item.item_data = item_registry[item_id]
	item.quality = data.get("quality", Enums.Quality.STANDARD)
	item.quantity = data.get("quantity", 1)
	item.purchase_price = data.get("purchase_price", 0)
	item.listed_price = data.get("listed_price", 0)
	item.age_days = data.get("age_days", 0)
	return item
