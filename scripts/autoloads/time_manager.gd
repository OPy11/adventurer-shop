extends Node

## Manages game time and day/night cycle

signal hour_changed(hour: int)
signal time_of_day_changed(period: String)
signal shop_hours_changed(is_open: bool)

const HOURS_PER_DAY := 24
const MINUTES_PER_HOUR := 60
const REAL_SECONDS_PER_GAME_MINUTE := 0.5 # 1 game hour = 30 real seconds

var current_hour: int = 8 # Start at 8 AM
var current_minute: int = 0
var time_scale: float = 1.0
var is_paused: bool = false

var shop_open_hour: int = 8
var shop_close_hour: int = 20

var _accumulated_time: float = 0.0

# Scheduled events
var scheduled_events: Array[Dictionary] = []
var active_orders: Array[Dictionary] = [] # Supplier orders
var active_missions: Array[Dictionary] = [] # Guild missions

func _ready() -> void:
	print("[TimeManager] Initialized at %02d:00" % current_hour)

func _process(delta: float) -> void:
	if is_paused:
		return

	_accumulated_time += delta * time_scale
	var minutes_passed := int(_accumulated_time / REAL_SECONDS_PER_GAME_MINUTE)

	if minutes_passed > 0:
		_accumulated_time -= minutes_passed * REAL_SECONDS_PER_GAME_MINUTE
		advance_time(minutes_passed)

func advance_time(minutes: int) -> void:
	current_minute += minutes
	while current_minute >= MINUTES_PER_HOUR:
		current_minute -= MINUTES_PER_HOUR
		_advance_hour()

func _advance_hour() -> void:
	var old_hour := current_hour
	current_hour += 1

	if current_hour >= HOURS_PER_DAY:
		current_hour = 0
		GameManager.advance_day()

	hour_changed.emit(current_hour)
	_check_time_of_day(old_hour, current_hour)
	_check_shop_hours()
	_process_scheduled_events()
	_process_orders_and_missions()

func _check_time_of_day(old: int, new: int) -> void:
	var old_period := _get_time_period(old)
	var new_period := _get_time_period(new)
	if old_period != new_period:
		time_of_day_changed.emit(new_period)

func _get_time_period(hour: int) -> String:
	if hour >= 6 and hour < 12:
		return "صباح"
	elif hour >= 12 and hour < 17:
		return "ظهر"
	elif hour >= 17 and hour < 21:
		return "مساء"
	else:
		return "ليل"

func _check_shop_hours() -> void:
	var should_be_open := current_hour >= shop_open_hour and current_hour < shop_close_hour
	if should_be_open != GameManager.is_shop_open:
		GameManager.is_shop_open = should_be_open
		shop_hours_changed.emit(should_be_open)
		if should_be_open:
			GameManager.notify("المتجر مفتوح!", "info")
		else:
			GameManager.notify("المتجر مغلق. وقت الراحة.", "info")

func _process_scheduled_events() -> void:
	var to_remove: Array[int] = []
	for i in range(scheduled_events.size()):
		var event := scheduled_events[i]
		if event.day == GameManager.current_day and event.hour == current_hour:
			_execute_event(event)
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		scheduled_events.remove_at(to_remove[i])

func _execute_event(event: Dictionary) -> void:
	match event.type:
		"customer_spawn":
			GameManager.customer_arrived.emit(event.customer)
		"supplier_delivery":
			_handle_supplier_delivery(event)
		"mission_return":
			_handle_mission_return(event)

func _process_orders_and_missions() -> void:
	var current_time := GameManager.current_day * 24 + current_hour

	# Check orders
	var completed_orders: Array[int] = []
	for i in range(active_orders.size()):
		var order := active_orders[i]
		if current_time >= order.completion_time:
			_complete_order(order)
			completed_orders.append(i)

	for i in range(completed_orders.size() - 1, -1, -1):
		active_orders.remove_at(completed_orders[i])

	# Check missions
	var completed_missions: Array[int] = []
	for i in range(active_missions.size()):
		var mission := active_missions[i]
		if current_time >= mission.return_time:
			_complete_mission(mission)
			completed_missions.append(i)

	for i in range(completed_missions.size() - 1, -1, -1):
		active_missions.remove_at(completed_missions[i])

func _handle_supplier_delivery(event: Dictionary) -> void:
	GameManager.notify("وصلت شحنة من %s!" % event.supplier_name, "success")

func _handle_mission_return(event: Dictionary) -> void:
	GameManager.notify("عاد %s من المهمة!" % event.adventurer_name, "info")

func _complete_order(order: Dictionary) -> void:
	var success: bool = randf() < float(order.success_rate)
	if success:
		var item := InventoryItem.new(order.item, order.quantity, order.quality)
		item.purchase_price = order.cost
		GameManager.add_to_inventory(item)
		GameManager.stats.items_crafted += order.quantity
		GameManager.notify("تم تصنيع %s!" % order.item.name_ar, "success")
	else:
		GameManager.notify("فشل تصنيع %s..." % order.item.name_ar, "error")
		GameManager.add_gold(int(order.cost * 0.5)) # Partial refund

func _complete_mission(mission: Dictionary) -> void:
	var adventurer: AdventurerData = mission.adventurer
	adventurer.is_available = true

	var success: bool = randf() < float(mission.success_rate)
	if success:
		# Add materials
		for mat_id in mission.rewards:
			var quantity: int = mission.rewards[mat_id]
			var actual := randi_range(int(quantity * 0.7), quantity)
			GameManager.add_material(mat_id, actual)
		GameManager.notify("نجحت مهمة %s! حصلنا على مواد." % adventurer.name_ar, "success")
	else:
		GameManager.stats.missions_failed += 1
		if randf() < 0.1: # 10% chance adventurer is injured
			adventurer.success_rate *= 0.9
			GameManager.notify("أصيب %s في المهمة..." % adventurer.name_ar, "error")
		else:
			GameManager.notify("فشلت مهمة %s." % adventurer.name_ar, "warning")

func schedule_order(order: Dictionary) -> void:
	active_orders.append(order)

func schedule_mission(mission: Dictionary) -> void:
	active_missions.append(mission)
	GameManager.stats.missions_sent += 1

func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_time_of_day_arabic() -> String:
	return _get_time_period(current_hour)

func set_time_scale(scale: float) -> void:
	time_scale = clampf(scale, 0.0, 10.0)

func pause() -> void:
	is_paused = true

func unpause() -> void:
	is_paused = false

func toggle_pause() -> void:
	is_paused = !is_paused
