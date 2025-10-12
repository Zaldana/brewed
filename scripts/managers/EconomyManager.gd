extends Node

# EconomyManager - Handles all economic transactions and market dynamics
# Handles: Market pricing, external traders, internal transactions, price fluctuations

signal price_changed(item_type: String, new_price: float)
signal market_updated
signal transaction_completed(from: String, to: String, item: String, amount: int, price: float)

# Market data structure
var market_prices: Dictionary = {}
var market_demand: Dictionary = {}
var market_supply: Dictionary = {}

# External traders
var external_farmers: Array[Dictionary] = []
var external_roasters: Array[Dictionary] = []
var external_cafes: Array[Dictionary] = []

# Internal family discount rate
const FAMILY_DISCOUNT: float = 0.8  # 20% discount for family transactions

# Base prices for different items
const BASE_PRICES = {
	"green_beans_arabica": 8.50,
	"green_beans_robusta": 6.25,
	"green_beans_especialty": 12.00,
	"roasted_beans_light": 15.00,
	"roasted_beans_medium": 16.50,
	"roasted_beans_dark": 18.00,
	"coffee_drink_espresso": 3.50,
	"coffee_drink_latte": 4.75,
	"coffee_drink_pour_over": 5.25
}

# Quality multipliers
const QUALITY_MULTIPLIERS = {
	"poor": 0.6,
	"fair": 0.8,
	"good": 1.0,
	"excellent": 1.3,
	"outstanding": 1.6
}

func _ready():
	_initialize_market()
	_initialize_external_traders()
	
	# Connect to game manager for daily updates
	GameManager.day_changed.connect(_on_day_changed)

func _initialize_market():
	"""Initialize market prices and demand/supply"""
	for item in BASE_PRICES:
		market_prices[item] = BASE_PRICES[item]
		market_demand[item] = 1.0  # Base demand
		market_supply[item] = 1.0  # Base supply
	
	print("Market initialized with base prices")

func _initialize_external_traders():
	"""Initialize external NPC traders"""
	# External farmers selling green beans
	external_farmers = [
		{
			"name": "Mountain View Farms",
			"varieties": ["arabica", "robusta"],
			"quality": "good",
			"reliability": 0.9,
			"price_modifier": 1.1
		},
		{
			"name": "Valley Coffee Co.",
			"varieties": ["arabica", "especialty"],
			"quality": "excellent",
			"reliability": 0.7,
			"price_modifier": 1.4
		}
	]
	
	# External roasters (competition)
	external_roasters = [
		{
			"name": "Artisan Roasters",
			"roast_levels": ["light", "medium"],
			"quality": "excellent",
			"price_modifier": 1.2
		}
	]
	
	# External cafes (walk-in customers)
	external_cafes = [
		{
			"name": "Downtown Cafe",
			"customer_flow": 0.8,
			"quality_preference": "good"
		}
	]
	
	print("External traders initialized")

func _on_day_changed(_day: int, _season: String):
	"""Update market conditions daily"""
	_update_market_dynamics()
	_generate_market_events()

func _update_market_dynamics():
	"""Update supply, demand, and prices based on various factors"""
	for item in market_prices:
		# Random fluctuation
		var fluctuation = randf_range(0.95, 1.05)
		
		# Seasonal effects
		var seasonal_modifier = _get_seasonal_modifier(item)
		
		# Supply/demand pressure
		var demand_pressure = market_demand[item] / max(market_supply[item], 0.1)
		
		# Update price
		var new_price = BASE_PRICES[item] * fluctuation * seasonal_modifier * demand_pressure
		market_prices[item] = clamp(new_price, BASE_PRICES[item] * 0.5, BASE_PRICES[item] * 2.0)
		
		# Update supply/demand (slowly return to equilibrium)
		market_demand[item] = lerp(market_demand[item], 1.0, 0.1)
		market_supply[item] = lerp(market_supply[item], 1.0, 0.1)
	
	market_updated.emit()
	print("Market dynamics updated")

func _get_seasonal_modifier(item: String) -> float:
	"""Get seasonal price modifier for items"""
	var season = GameManager.get_current_season()
	
	match item:
		"green_beans_arabica", "green_beans_robusta", "green_beans_especialty":
			match season:
				GameManager.Season.SPRING: return 1.2  # Planting season
				GameManager.Season.SUMMER: return 0.9  # Growing season
				GameManager.Season.AUTUMN: return 1.1  # Harvest season
				GameManager.Season.WINTER: return 1.0  # Off season
		"roasted_beans_light", "roasted_beans_medium", "roasted_beans_dark":
			match season:
				GameManager.Season.WINTER: return 1.3  # Coffee season
				_: return 1.0
		"coffee_drink_espresso", "coffee_drink_latte", "coffee_drink_pour_over":
			match season:
				GameManager.Season.WINTER: return 1.2  # Cold weather
				GameManager.Season.SUMMER: return 0.8  # Iced coffee season
				_: return 1.0
	
	return 1.0

func _generate_market_events():
	"""Generate random market events"""
	if randf() < 0.1:  # 10% chance per day
		var event_type = ["supply_shortage", "demand_surge", "quality_premium", "competition_enters"][randi() % 4]
		_apply_market_event(event_type)

func _apply_market_event(event_type: String):
	"""Apply a market event"""
	match event_type:
		"supply_shortage":
			# Increase prices for green beans
			for item in market_prices:
				if "green_beans" in item:
					market_supply[item] *= 0.7
			print("Market event: Supply shortage for green beans")
		
		"demand_surge":
			# Increase demand for coffee drinks
			for item in market_prices:
				if "coffee_drink" in item:
					market_demand[item] *= 1.5
			print("Market event: Demand surge for coffee drinks")
		
		"quality_premium":
			# Premium for high-quality items
			for item in market_prices:
				if "excellent" in item or "outstanding" in item:
					market_prices[item] *= 1.2
			print("Market event: Quality premium in effect")
		
		"competition_enters":
			# Decrease prices due to competition
			for item in market_prices:
				market_prices[item] *= 0.95
			print("Market event: New competition entered market")

# Transaction functions
func buy_from_family(from_sibling: String, to_sibling: String, item: String, amount: int) -> bool:
	"""Handle internal family transaction"""
	var base_price = market_prices.get(item, 0.0)
	if base_price == 0.0:
		print("Error: Unknown item ", item)
		return false
	
	var family_price = base_price * FAMILY_DISCOUNT
	var total_cost = family_price * amount
	
	# TODO: Implement actual inventory transfer and money exchange
	# This will be implemented when we have the business managers
	
	transaction_completed.emit(from_sibling, to_sibling, item, amount, family_price)
	print("Family transaction: ", amount, " ", item, " for $", total_cost)
	return true

func buy_from_market(_buyer: String, item: String, amount: int, quality: String = "good") -> bool:
	"""Handle external market purchase"""
	var base_price = market_prices.get(item, 0.0)
	if base_price == 0.0:
		print("Error: Unknown item ", item)
		return false
	
	var quality_multiplier = QUALITY_MULTIPLIERS.get(quality, 1.0)
	var market_price = base_price * quality_multiplier
	var total_cost = market_price * amount
	
	# TODO: Implement actual purchase logic
	
	print("Market purchase: ", amount, " ", item, " (", quality, ") for $", total_cost)
	return true

func sell_to_market(_seller: String, item: String, amount: int, quality: String = "good") -> float:
	"""Handle external market sale"""
	var base_price = market_prices.get(item, 0.0)
	if base_price == 0.0:
		print("Error: Unknown item ", item)
		return 0.0
	
	var quality_multiplier = QUALITY_MULTIPLIERS.get(quality, 1.0)
	var market_price = base_price * quality_multiplier
	var total_earnings = market_price * amount
	
	# TODO: Implement actual sale logic
	
	print("Market sale: ", amount, " ", item, " (", quality, ") earned $", total_earnings)
	return total_earnings

# Getters
func get_market_price(item: String) -> float:
	return market_prices.get(item, 0.0)

func get_family_price(item: String) -> float:
	return market_prices.get(item, 0.0) * FAMILY_DISCOUNT

func get_market_demand(item: String) -> float:
	return market_demand.get(item, 1.0)

func get_market_supply(item: String) -> float:
	return market_supply.get(item, 1.0)

func get_external_farmers() -> Array:
	return external_farmers

func get_external_roasters() -> Array:
	return external_roasters

func get_external_cafes() -> Array:
	return external_cafes
