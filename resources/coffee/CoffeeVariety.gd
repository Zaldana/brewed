class_name CoffeeVariety
extends Resource

# CoffeeVariety Resource - Defines different types of coffee beans
# Contains all data about growing conditions, flavor profiles, and processing

@export var variety_name: String = ""
@export var variety_id: String = ""
@export var description: String = ""

# Growing characteristics
@export var growth_time_days: int = 180  # Days from planting to harvest
@export var yield_per_plant: float = 1.5  # Pounds of green beans per plant
@export var harvest_seasons: Array[int] = [1, 2, 3]  # Which seasons can be harvested (1=Spring, etc.)

# Environmental preferences (0.0 to 1.0 scale)
@export var altitude_preference: float = 0.5  # Higher = prefers higher altitude
@export var rainfall_preference: float = 0.5  # Higher = prefers more rain
@export var temperature_preference: float = 0.5  # Higher = prefers warmer temps
@export var soil_preference: float = 0.5  # Higher = prefers richer soil

# Quality characteristics (0.0 to 1.0 scale)
@export var base_acidity: float = 0.5
@export var base_body: float = 0.5
@export var base_sweetness: float = 0.5
@export var base_bitterness: float = 0.5
@export var base_aroma: float = 0.5

# Processing methods available
enum ProcessingMethod {
	WASHED,     # Clean, bright flavor
	NATURAL,    # Fruity, complex flavor
	HONEY,      # Sweet, balanced flavor
	SEMI_WASHED # Hybrid approach
}

@export var available_processing: Array[ProcessingMethod] = [ProcessingMethod.WASHED]

# Market characteristics
@export var rarity: float = 0.5  # 0.0 = common, 1.0 = extremely rare
@export var base_price_multiplier: float = 1.0  # Multiplier for base market price
@export var demand_trend: float = 0.0  # -1.0 = declining, 1.0 = rising

# Visual representation
@export var plant_texture: Texture2D
@export var bean_texture: Texture2D
@export var color_tint: Color = Color.WHITE

func _init():
	# Set default processing methods if none specified
	if available_processing.is_empty():
		available_processing = [ProcessingMethod.WASHED]

func get_processing_method_name(method: ProcessingMethod) -> String:
	match method:
		ProcessingMethod.WASHED: return "Washed"
		ProcessingMethod.NATURAL: return "Natural"
		ProcessingMethod.HONEY: return "Honey"
		ProcessingMethod.SEMI_WASHED: return "Semi-Washed"
		_: return "Unknown"

func get_quality_score() -> float:
	"""Calculate overall quality score based on flavor characteristics"""
	return (base_acidity + base_body + base_sweetness + base_aroma - base_bitterness * 0.5) / 4.0

func get_environmental_suitability(altitude: float, rainfall: float, temperature: float, soil: float) -> float:
	"""Calculate how suitable the environment is for this variety (0.0 to 1.0)"""
	var altitude_score = 1.0 - abs(altitude - altitude_preference)
	var rainfall_score = 1.0 - abs(rainfall - rainfall_preference)
	var temperature_score = 1.0 - abs(temperature - temperature_preference)
	var soil_score = 1.0 - abs(soil - soil_preference)
	
	return (altitude_score + rainfall_score + temperature_score + soil_score) / 4.0

func get_seasonal_growth_modifier(season: int) -> float:
	"""Get growth rate modifier for specific season"""
	if season in harvest_seasons:
		return 1.2  # Grows faster during harvest season
	else:
		return 1.0  # Normal growth

func can_harvest_in_season(season: int) -> bool:
	"""Check if this variety can be harvested in the given season"""
	return season in harvest_seasons

func get_market_price() -> float:
	"""Get current market price for this variety"""
	var base_price = EconomyManager.get_market_price("green_beans_arabica")  # Use arabica as base
	var rarity_multiplier = 1.0 + (rarity * 0.5)
	var demand_multiplier = 1.0 + demand_trend * 0.3
	var quality_multiplier = 1.0 + get_quality_score() * 0.4
	
	return base_price * base_price_multiplier * rarity_multiplier * demand_multiplier * quality_multiplier
