class_name InventoryManager
extends Node

# InventoryManager - Manages inventory for each business location
# Handles: Storage limits, item tracking, quality degradation, transfers

signal inventory_changed(location: String, item_type: String, amount: float)
signal storage_full(location: String, item_type: String)
signal quality_degraded(item: CoffeeBean, old_quality: float, new_quality: float)

# Storage configuration
var storage_capacities: Dictionary = {
	"farm": {
		"green_beans": 1000.0,  # pounds
		"processed_beans": 500.0,
		"equipment": 50.0
	},
	"roastery": {
		"green_beans": 800.0,
		"roasted_beans": 600.0,
		"equipment": 30.0
	},
	"cafe": {
		"roasted_beans": 200.0,
		"ground_beans": 50.0,
		"drinks": 100.0,
		"equipment": 20.0
	}
}

# Current inventory by location
var inventories: Dictionary = {
	"farm": {},
	"roastery": {},
	"cafe": {}
}

# Item tracking
var item_registry: Dictionary = {}  # item_id -> CoffeeBean
var next_item_id: int = 1

func _ready():
	_initialize_inventories()
	
	# Connect to game manager for daily updates
	GameManager.day_changed.connect(_on_day_changed)

func _initialize_inventories():
	"""Initialize empty inventories for all locations"""
	for location in inventories:
		inventories[location] = {
			"green_beans": [],
			"roasted_beans": [],
			"ground_beans": [],
			"drinks": [],
			"equipment": []
		}

func _on_day_changed(_day: int, _season: String):
	"""Process daily inventory updates"""
	_process_quality_degradation()
	_process_storage_conditions()

func _process_quality_degradation():
	"""Process quality degradation for all stored items"""
	for location in inventories:
		for item_type in inventories[location]:
			if item_type in ["green_beans", "roasted_beans", "ground_beans"]:
				_process_bean_degradation(location, item_type)

func _process_bean_degradation(location: String, item_type: String):
	"""Process quality degradation for coffee beans"""
	var beans_list = inventories[location][item_type]
	
	for bean in beans_list:
		if bean is CoffeeBean:
			var old_quality = bean.get_quality_score()
			
			# Apply daily degradation
			bean.current_quality *= 0.999  # Very small daily degradation
			
			# Check storage conditions
			_apply_storage_effects(bean, location)
			
			var new_quality = bean.get_quality_score()
			
			if new_quality < old_quality * 0.95:  # Significant quality drop
				quality_degraded.emit(bean, old_quality, new_quality)

func _process_storage_conditions():
	"""Process storage condition effects"""
	# This could include temperature, humidity, light exposure effects
	# For now, just ensure proper storage for each location
	
	var storage_conditions = {
		"farm": {"temperature": 75.0, "humidity": 65.0, "light": 0.1},
		"roastery": {"temperature": 70.0, "humidity": 60.0, "light": 0.0},
		"cafe": {"temperature": 72.0, "humidity": 55.0, "light": 0.3}
	}
	
	for location in storage_conditions:
		var conditions = storage_conditions[location]
		_apply_location_storage_conditions(location, conditions)

func _apply_location_storage_conditions(location: String, conditions: Dictionary):
	"""Apply storage conditions to all beans in a location"""
	for item_type in inventories[location]:
		if item_type in ["green_beans", "roasted_beans", "ground_beans"]:
			var beans_list = inventories[location][item_type]
			for bean in beans_list:
				if bean is CoffeeBean:
					bean.storage_temperature = conditions["temperature"]
					bean.storage_humidity = conditions["humidity"]
					bean.exposure_to_light = conditions["light"]

func _apply_storage_effects(bean: CoffeeBean, location: String):
	"""Apply location-specific storage effects"""
	# Different locations may have different storage quality
	match location:
		"farm":
			# Farm storage may be less ideal
			pass  # Use default conditions
		"roastery":
			# Roastery has better storage
			bean.current_quality *= 1.001  # Slight quality preservation
		"cafe":
			# Cafe storage is adequate but beans are used quickly
			pass

# Inventory management functions
func add_item(location: String, item_type: String, item: CoffeeBean, amount: float = -1.0) -> bool:
	"""Add an item to inventory"""
	if not _is_valid_location(location):
		print("Error: Invalid location ", location)
		return false
	
	if not _is_valid_item_type(item_type):
		print("Error: Invalid item type ", item_type)
		return false
	
	# Check storage capacity
	var current_amount = get_item_amount(location, item_type)
	var capacity = storage_capacities[location].get(item_type, 0.0)
	
	var add_amount = amount if amount > 0 else item.quantity
	if current_amount + add_amount > capacity:
		storage_full.emit(location, item_type)
		print("Error: Storage full for ", item_type, " at ", location)
		return false
	
	# Add to inventory
	if location not in inventories:
		inventories[location] = {}
	if item_type not in inventories[location]:
		inventories[location][item_type] = []
	
	# Create new bean with specified amount
	var new_bean = item.duplicate_bean(add_amount)
	new_bean.id = "item_" + str(next_item_id)
	next_item_id += 1
	
	item_registry[new_bean.id] = new_bean
	inventories[location][item_type].append(new_bean)
	
	inventory_changed.emit(location, item_type, add_amount)
	print("Added ", add_amount, " lbs of ", item.variety.variety_name, " to ", location)
	
	return true

func remove_item(location: String, item_type: String, amount: float) -> Array[CoffeeBean]:
	"""Remove items from inventory (FIFO - First In, First Out)"""
	if not _is_valid_location(location) or not _is_valid_item_type(item_type):
		return []
	
	if item_type not in inventories[location]:
		return []
	
	var beans_list = inventories[location][item_type]
	var removed_beans: Array[CoffeeBean] = []
	var remaining_amount = amount
	
	# Remove beans in order (FIFO)
	var i = 0
	while i < beans_list.size() and remaining_amount > 0:
		var bean = beans_list[i]
		if bean is CoffeeBean:
			if bean.quantity <= remaining_amount:
				# Remove entire bean
				remaining_amount -= bean.quantity
				removed_beans.append(bean)
				beans_list.remove_at(i)
				item_registry.erase(bean.id)
			else:
				# Partial removal
				var partial_bean = bean.duplicate_bean(remaining_amount)
				removed_beans.append(partial_bean)
				bean.quantity -= remaining_amount
				remaining_amount = 0
				i += 1
		else:
			i += 1
	
	if removed_beans.size() > 0:
		inventory_changed.emit(location, item_type, -amount)
		print("Removed ", amount, " lbs from ", location)
	
	return removed_beans

func transfer_item(from_location: String, to_location: String, item_type: String, amount: float) -> bool:
	"""Transfer items between locations"""
	var removed_beans = remove_item(from_location, item_type, amount)
	if removed_beans.is_empty():
		return false
	
	var total_removed = 0.0
	for bean in removed_beans:
		total_removed += bean.quantity
	
	var success = add_item(to_location, item_type, removed_beans[0], total_removed)
	
	if not success:
		# Return items if transfer failed
		for bean in removed_beans:
			add_item(from_location, item_type, bean, bean.quantity)
	
	return success

func get_item_amount(location: String, item_type: String) -> float:
	"""Get total amount of an item type in a location"""
	if not _is_valid_location(location) or not _is_valid_item_type(item_type):
		return 0.0
	
	if item_type not in inventories[location]:
		return 0.0
	
	var total = 0.0
	var beans_list = inventories[location][item_type]
	for bean in beans_list:
		if bean is CoffeeBean:
			total += bean.quantity
	
	return total

func get_storage_usage(location: String, item_type: String) -> float:
	"""Get storage usage as percentage (0.0 to 1.0)"""
	var current = get_item_amount(location, item_type)
	var capacity = storage_capacities[location].get(item_type, 0.0)
	
	if capacity <= 0:
		return 0.0
	
	return current / capacity

func get_available_capacity(location: String, item_type: String) -> float:
	"""Get available storage capacity"""
	var current = get_item_amount(location, item_type)
	var capacity = storage_capacities[location].get(item_type, 0.0)
	
	return max(0.0, capacity - current)

func get_best_quality_items(location: String, item_type: String, amount: float) -> Array[CoffeeBean]:
	"""Get the best quality items from inventory (for premium sales)"""
	if not _is_valid_location(location) or not _is_valid_item_type(item_type):
		return []
	
	if item_type not in inventories[location]:
		return []
	
	var beans_list = inventories[location][item_type]
	if beans_list.is_empty():
		return []
	
	# Sort by quality (highest first)
	beans_list.sort_custom(func(a, b): return a.get_quality_score() > b.get_quality_score())
	
	return remove_item(location, item_type, amount)

func get_oldest_items(location: String, item_type: String, amount: float) -> Array[CoffeeBean]:
	"""Get the oldest items from inventory (FIFO for regular use)"""
	return remove_item(location, item_type, amount)

func get_inventory_summary(location: String) -> Dictionary:
	"""Get a summary of inventory at a location"""
	var summary = {}
	
	for item_type in inventories[location]:
		var amount = get_item_amount(location, item_type)
		var usage = get_storage_usage(location, item_type)
		
		summary[item_type] = {
			"amount": amount,
			"usage": usage,
			"capacity": storage_capacities[location].get(item_type, 0.0)
		}
	
	return summary

func get_all_locations() -> Array:
	"""Get all available locations"""
	return inventories.keys()

func get_item_types_at_location(location: String) -> Array:
	"""Get all item types available at a location"""
	if not _is_valid_location(location):
		return []
	
	return inventories[location].keys()

func upgrade_storage(location: String, item_type: String, additional_capacity: float):
	"""Upgrade storage capacity for a location and item type"""
	if location in storage_capacities and item_type in storage_capacities[location]:
		storage_capacities[location][item_type] += additional_capacity
		print("Upgraded ", location, " storage for ", item_type, " by ", additional_capacity, " lbs")

func _is_valid_location(location: String) -> bool:
	return location in inventories

func _is_valid_item_type(item_type: String) -> bool:
	return item_type in ["green_beans", "roasted_beans", "ground_beans", "drinks", "equipment"]

# Utility functions for external systems
func get_item_by_id(item_id: String) -> CoffeeBean:
	"""Get an item by its ID"""
	return item_registry.get(item_id, null)

func get_items_by_variety(location: String, item_type: String, variety: CoffeeVariety) -> Array[CoffeeBean]:
	"""Get all items of a specific variety at a location"""
	var matching_items: Array[CoffeeBean] = []
	
	if not _is_valid_location(location) or not _is_valid_item_type(item_type):
		return matching_items
	
	if item_type not in inventories[location]:
		return matching_items
	
	var beans_list = inventories[location][item_type]
	for bean in beans_list:
		if bean is CoffeeBean and bean.variety == variety:
			matching_items.append(bean)
	
	return matching_items
