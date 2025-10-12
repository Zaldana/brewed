class_name SupplyChainManager
extends Node

# SupplyChainManager - Manages the interconnected supply chain between businesses
# Handles: Internal trading, supply/demand, quality tracking, family discounts

signal supply_chain_updated
signal internal_transaction(from_business: String, to_business: String, item: String, amount: float, price: float)
signal quality_chain_broken(item: String, reason: String)

# Business references (will be set by main manager)
var farm_manager: FarmManager = null
var roastery_manager: RoasteryManager = null
var cafe_manager: CafeManager = null

# Supply chain configuration
var family_discount_rate: float = 0.2  # 20% discount for family transactions
var quality_loss_per_transfer: float = 0.05  # 5% quality loss per transfer
var max_transfer_delay_days: int = 3  # Maximum days before quality loss

# Transaction tracking
var pending_transactions: Array[Dictionary] = []
var transaction_history: Array[Dictionary] = []

# Supply chain statistics
var total_internal_transactions: int = 0
var total_family_savings: float = 0.0
var quality_chain_breaks: int = 0

func _ready():
	_initialize_supply_chain()
	_connect_to_managers()

func _initialize_supply_chain():
	"""Initialize the supply chain system"""
	print("Supply chain manager initialized")

func _connect_to_managers():
	"""Connect to global managers"""
	GameManager.day_changed.connect(_on_day_changed)

func set_business_managers(farm: FarmManager, roastery: RoasteryManager, cafe: CafeManager):
	"""Set references to business managers"""
	farm_manager = farm
	roastery_manager = roastery
	cafe_manager = cafe
	print("Business managers connected to supply chain")

func _on_day_changed(_day: int, _season: String):
	"""Process daily supply chain updates"""
	_process_pending_transactions()
	_check_supply_demands()
	_update_quality_chain()

func _process_pending_transactions():
	"""Process pending transactions and apply quality changes"""
	for transaction in pending_transactions:
		transaction["delay_days"] += 1
		
		# Check for quality loss due to delay
		if transaction["delay_days"] > max_transfer_delay_days:
			_apply_quality_loss(transaction)
		
		# Check if transaction should be completed
		if transaction["delay_days"] >= transaction["expected_delay"]:
			_complete_transaction(transaction)
			pending_transactions.erase(transaction)

func _check_supply_demands():
	"""Check for supply and demand imbalances between businesses"""
	if not _are_managers_available():
		return
	
	# Check farm to roastery supply
	var farm_green_beans = farm_manager.get_inventory_manager().get_item_amount("farm", "green_beans")
	var roastery_green_beans = roastery_manager.get_inventory_manager().get_item_amount("roastery", "green_beans")
	
	if farm_green_beans > 50.0 and roastery_green_beans < 20.0:
		_suggest_transfer("farm", "roastery", "green_beans", 20.0)
	
	# Check roastery to cafe supply
	var roastery_roasted_beans = roastery_manager.get_inventory_manager().get_item_amount("roastery", "roasted_beans")
	var cafe_roasted_beans = cafe_manager.get_inventory_manager().get_item_amount("cafe", "roasted_beans")
	
	if roastery_roasted_beans > 30.0 and cafe_roasted_beans < 10.0:
		_suggest_transfer("roastery", "cafe", "roasted_beans", 15.0)

func _suggest_transfer(from_business: String, to_business: String, item_type: String, amount: float):
	"""Suggest a transfer between businesses"""
	print("Supply chain suggests: ", amount, " lbs of ", item_type, " from ", from_business, " to ", to_business)
	# In a full implementation, this would show UI notifications to the player

func _update_quality_chain():
	"""Update quality tracking throughout the supply chain"""
	if not _are_managers_available():
		return
	
	# Check for quality issues in the chain
	_check_quality_consistency()

func _check_quality_consistency():
	"""Check for quality consistency across the supply chain"""
	# This would check if quality is maintained properly throughout transfers
	pass

func initiate_transfer(from_business: String, to_business: String, item_type: String, amount: float) -> bool:
	"""Initiate a transfer between businesses"""
	if not _validate_transfer(from_business, to_business, item_type, amount):
		return false
	
	var from_manager = _get_business_manager(from_business)
	var to_manager = _get_business_manager(to_business)
	
	if not from_manager or not to_manager:
		print("Error: Business manager not found")
		return false
	
	# Remove items from source
	var removed_items = from_manager.get_inventory_manager().remove_item(from_business, item_type, amount)
	
	if removed_items.is_empty():
		print("Error: Not enough items to transfer")
		return false
	
	# Calculate transfer price (family discount)
	var market_price = EconomyManager.get_market_price("green_beans_arabica")  # Use as base
	var family_price = market_price * (1.0 - family_discount_rate)
	var total_price = family_price * amount
	
	# Create transaction record
	var transaction = {
		"from_business": from_business,
		"to_business": to_business,
		"item_type": item_type,
		"amount": amount,
		"price": total_price,
		"items": removed_items,
		"delay_days": 0,
		"expected_delay": 1,  # 1 day delivery
		"quality_at_transfer": _get_average_quality(removed_items)
	}
	
	pending_transactions.append(transaction)
	
	print("Transfer initiated: ", amount, " lbs of ", item_type, " from ", from_business, " to ", to_business, " for $", total_price)
	return true

func _validate_transfer(from_business: String, to_business: String, item_type: String, amount: float) -> bool:
	"""Validate if a transfer is possible"""
	if amount <= 0:
		print("Error: Invalid transfer amount")
		return false
	
	if not _are_managers_available():
		print("Error: Business managers not available")
		return false
	
	var from_manager = _get_business_manager(from_business)
	if not from_manager:
		print("Error: Source business manager not found")
		return false
	
	var available_amount = from_manager.get_inventory_manager().get_item_amount(from_business, item_type)
	if available_amount < amount:
		print("Error: Insufficient items (have ", available_amount, ", need ", amount, ")")
		return false
	
	return true

func _complete_transaction(transaction: Dictionary):
	"""Complete a pending transaction"""
	var to_manager = _get_business_manager(transaction["to_business"])
	if not to_manager:
		print("Error: Destination business manager not found")
		return
	
	# Add items to destination
	for item in transaction["items"]:
		to_manager.get_inventory_manager().add_item(transaction["to_business"], transaction["item_type"], item)
	
	# Record transaction
	transaction_history.append(transaction)
	total_internal_transactions += 1
	total_family_savings += transaction["price"] * family_discount_rate
	
	internal_transaction.emit(
		transaction["from_business"],
		transaction["to_business"],
		transaction["item_type"],
		transaction["amount"],
		transaction["price"]
	)
	
	supply_chain_updated.emit()
	print("Transaction completed: ", transaction["amount"], " lbs delivered")

func _apply_quality_loss(transaction: Dictionary):
	"""Apply quality loss due to delayed transfer"""
	for item in transaction["items"]:
		if item is CoffeeBean:
			item.current_quality *= (1.0 - quality_loss_per_transfer)
	
	quality_chain_breaks += 1
	quality_chain_broken.emit(transaction["item_type"], "Transfer delayed beyond " + str(max_transfer_delay_days) + " days")

func _get_average_quality(items: Array) -> float:
	"""Get average quality of items"""
	if items.is_empty():
		return 0.0
	
	var total_quality = 0.0
	var count = 0
	
	for item in items:
		if item is CoffeeBean:
			total_quality += item.get_quality_score()
			count += 1
	
	return total_quality / count if count > 0 else 0.0

func _get_business_manager(business: String):
	"""Get the appropriate business manager"""
	match business:
		"farm":
			return farm_manager
		"roastery":
			return roastery_manager
		"cafe":
			return cafe_manager
		_:
			return null

func _are_managers_available() -> bool:
	"""Check if all business managers are available"""
	return farm_manager != null and roastery_manager != null and cafe_manager != null

# Public API functions
func get_supply_chain_status() -> Dictionary:
	"""Get current supply chain status"""
	if not _are_managers_available():
		return {}
	
	var status = {
		"farm_to_roastery": {
			"available": farm_manager.get_inventory_manager().get_item_amount("farm", "green_beans"),
			"needed": max(0, 20.0 - roastery_manager.get_inventory_manager().get_item_amount("roastery", "green_beans"))
		},
		"roastery_to_cafe": {
			"available": roastery_manager.get_inventory_manager().get_item_amount("roastery", "roasted_beans"),
			"needed": max(0, 10.0 - cafe_manager.get_inventory_manager().get_item_amount("cafe", "roasted_beans"))
		},
		"pending_transactions": pending_transactions.size(),
		"total_savings": total_family_savings
	}
	
	return status

func get_transaction_history() -> Array:
	"""Get transaction history"""
	return transaction_history

func get_supply_chain_efficiency() -> float:
	"""Calculate supply chain efficiency"""
	if total_internal_transactions == 0:
		return 1.0
	
	var efficiency = 1.0 - (float(quality_chain_breaks) / float(total_internal_transactions))
	return clamp(efficiency, 0.0, 1.0)

func force_complete_all_transactions():
	"""Force complete all pending transactions (for testing)"""
	while pending_transactions.size() > 0:
		var transaction = pending_transactions[0]
		_complete_transaction(transaction)
		pending_transactions.erase(transaction)
