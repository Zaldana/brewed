class_name CoffeeBean
extends Resource

# CoffeeBean Resource - Represents individual batches of coffee beans
# Tracks beans through the supply chain from farm to cup

@export var id: String = ""
@export var variety: CoffeeVariety
@export var quantity: float = 0.0  # In pounds
@export var processing_method: CoffeeVariety.ProcessingMethod = CoffeeVariety.ProcessingMethod.WASHED

# Quality tracking
@export var base_quality: float = 1.0  # Initial quality from farm
@export var current_quality: float = 1.0  # Current quality (degradation over time)
@export var processing_quality: float = 1.0  # Quality added by processing
@export var roast_quality: float = 1.0  # Quality added by roasting (if roasted)

# State in supply chain
enum BeanState {
	GREEN,      # Raw beans from farm
	ROASTED,    # Roasted beans from roastery
	GROUND,     # Ground beans ready for brewing
	USED        # Already used in drinks
}

@export var state: BeanState = BeanState.GREEN

# Roasting information (if applicable)
@export var roast_level: String = ""  # light, medium, dark
@export var roast_date: int = 0  # Day when roasted
@export var roast_profile: Dictionary = {}  # Temperature curves, etc.

# Flavor profile (evolves through processing)
@export var acidity: float = 0.5
@export var body: float = 0.5
@export var sweetness: float = 0.5
@export var bitterness: float = 0.5
@export var aroma: float = 0.5

# Age and freshness
@export var creation_date: int = 0  # Day when created
@export var harvest_date: int = 0  # Day when harvested
@export var processing_date: int = 0  # Day when processed

# Storage conditions
@export var storage_temperature: float = 70.0  # Fahrenheit
@export var storage_humidity: float = 60.0  # Percentage
@export var exposure_to_light: float = 0.0  # 0.0 = no light, 1.0 = full light

func _init():
	creation_date = GameManager.get_current_day()

func get_age_days() -> int:
	"""Get age of beans in days"""
	match state:
		BeanState.GREEN:
			return GameManager.get_current_day() - harvest_date
		BeanState.ROASTED:
			return GameManager.get_current_day() - roast_date
		_:
			return GameManager.get_current_day() - creation_date

func get_freshness() -> float:
	"""Calculate freshness score (0.0 to 1.0)"""
	var age_days = get_age_days()
	var max_fresh_days = _get_max_freshness_days()
	
	if age_days >= max_fresh_days:
		return 0.0
	
	return 1.0 - (float(age_days) / float(max_fresh_days))

func _get_max_freshness_days() -> int:
	"""Get maximum days before beans lose freshness"""
	match state:
		BeanState.GREEN:
			return 365  # Green beans can last a year
		BeanState.ROASTED:
			return 30   # Roasted beans last about a month
		BeanState.GROUND:
			return 7    # Ground beans last about a week
		_:
			return 0

func get_quality_score() -> float:
	"""Calculate overall quality score"""
	var freshness = get_freshness()
	var base_quality = current_quality
	var processing_quality = processing_quality
	var roast_quality = roast_quality if state != BeanState.GREEN else 1.0
	
	# Quality degrades over time
	var age_penalty = 1.0 - (get_age_days() * 0.001)  # 0.1% per day
	age_penalty = max(0.1, age_penalty)
	
	# Storage conditions affect quality
	var storage_penalty = _calculate_storage_penalty()
	
	var total_quality = base_quality * processing_quality * roast_quality * freshness * age_penalty * storage_penalty
	return clamp(total_quality, 0.1, 2.0)

func _calculate_storage_penalty() -> float:
	"""Calculate quality penalty from storage conditions"""
	var penalty = 1.0
	
	# Temperature penalty (optimal around 70F)
	var temp_diff = abs(storage_temperature - 70.0)
	penalty -= temp_diff * 0.001
	
	# Humidity penalty (optimal around 60%)
	var humidity_diff = abs(storage_humidity - 60.0)
	penalty -= humidity_diff * 0.002
	
	# Light exposure penalty
	penalty -= exposure_to_light * 0.1
	
	return max(0.5, penalty)

func process_beans(method: CoffeeVariety.ProcessingMethod, processing_quality: float):
	"""Process green beans"""
	if state != BeanState.GREEN:
		print("Error: Can only process green beans")
		return
	
	processing_method = method
	processing_quality = processing_quality
	processing_date = GameManager.get_current_day()
	
	# Update flavor profile based on processing method
	_update_flavor_from_processing(method, processing_quality)
	
	print("Processed ", quantity, " lbs of ", variety.variety_name, " using ", variety.get_processing_method_name(method))

func _update_flavor_from_processing(method: CoffeeVariety.ProcessingMethod, quality: float):
	"""Update flavor profile based on processing method"""
	match method:
		CoffeeVariety.ProcessingMethod.WASHED:
			acidity = min(1.0, acidity * 1.1)  # Washed tends to be brighter
			body = max(0.0, body * 0.95)       # Slightly less body
		CoffeeVariety.ProcessingMethod.NATURAL:
			sweetness = min(1.0, sweetness * 1.2)  # Natural is sweeter
			body = min(1.0, body * 1.1)            # More body
		CoffeeVariety.ProcessingMethod.HONEY:
			sweetness = min(1.0, sweetness * 1.15) # Honey is sweet
			acidity = max(0.0, acidity * 0.9)      # Less acidic
		CoffeeVariety.ProcessingMethod.SEMI_WASHED:
			# Balanced changes
			acidity = min(1.0, acidity * 1.05)
			body = min(1.0, body * 1.05)
	
	# Quality affects the magnitude of changes
	var quality_factor = quality * 0.5 + 0.5  # Scale quality to 0.5-1.0 range
	acidity = lerp(variety.base_acidity, acidity, quality_factor)
	body = lerp(variety.base_body, body, quality_factor)
	sweetness = lerp(variety.base_sweetness, sweetness, quality_factor)
	bitterness = lerp(variety.base_bitterness, bitterness, quality_factor)
	aroma = lerp(variety.base_aroma, aroma, quality_factor)

func roast_beans(roast_level: String, roast_quality: float, profile: Dictionary = {}):
	"""Roast green beans"""
	if state != BeanState.GREEN:
		print("Error: Can only roast green beans")
		return
	
	state = BeanState.ROASTED
	roast_level = roast_level
	roast_quality = roast_quality
	roast_profile = profile
	roast_date = GameManager.get_current_day()
	
	# Update flavor profile based on roast level
	_update_flavor_from_roast(roast_level, roast_quality)
	
	print("Roasted ", quantity, " lbs of ", variety.variety_name, " to ", roast_level)

func _update_flavor_from_roast(level: String, quality: float):
	"""Update flavor profile based on roast level"""
	match level:
		"light":
			acidity = min(1.0, acidity * 1.2)      # Light roast is more acidic
			bitterness = max(0.0, bitterness * 0.7) # Less bitter
			body = max(0.0, body * 0.8)            # Less body
		"medium":
			acidity = min(1.0, acidity * 1.1)      # Slightly more acidic
			bitterness = min(1.0, bitterness * 1.1) # Slightly more bitter
			body = min(1.0, body * 1.1)            # Slightly more body
		"dark":
			acidity = max(0.0, acidity * 0.6)      # Dark roast is less acidic
			bitterness = min(1.0, bitterness * 1.4) # More bitter
			body = min(1.0, body * 1.3)            # More body
			aroma = min(1.0, aroma * 1.2)          # More aromatic
	
	# Quality affects the magnitude of changes
	var quality_factor = quality * 0.3 + 0.7  # Scale quality to 0.7-1.0 range
	acidity = lerp(acidity * 0.8, acidity, quality_factor)
	body = lerp(body * 0.8, body, quality_factor)
	sweetness = lerp(sweetness * 0.8, sweetness, quality_factor)
	bitterness = lerp(bitterness * 0.8, bitterness, quality_factor)
	aroma = lerp(aroma * 0.8, aroma, quality_factor)

func grind_beans():
	"""Grind roasted beans"""
	if state != BeanState.ROASTED:
		print("Error: Can only grind roasted beans")
		return
	
	state = BeanState.GROUND
	
	# Ground beans lose some quality immediately
	current_quality *= 0.95
	
	print("Ground ", quantity, " lbs of roasted ", variety.variety_name)

func use_for_drink(amount: float) -> bool:
	"""Use beans for making a drink"""
	if state != BeanState.GROUND:
		print("Error: Can only use ground beans for drinks")
		return false
	
	if amount > quantity:
		print("Error: Not enough beans (have ", quantity, ", need ", amount, ")")
		return false
	
	quantity -= amount
	
	if quantity <= 0:
		state = BeanState.USED
	
	print("Used ", amount, " lbs of ground ", variety.variety_name, " for drink")
	return true

func get_flavor_description() -> String:
	"""Get a text description of the flavor profile"""
	var descriptions = []
	
	# Acidity descriptions
	if acidity > 0.7:
		descriptions.append("bright and acidic")
	elif acidity < 0.3:
		descriptions.append("mellow and smooth")
	
	# Body descriptions
	if body > 0.7:
		descriptions.append("full-bodied")
	elif body < 0.3:
		descriptions.append("light-bodied")
	
	# Sweetness descriptions
	if sweetness > 0.7:
		descriptions.append("sweet")
	elif sweetness < 0.3:
		descriptions.append("dry")
	
	# Bitterness descriptions
	if bitterness > 0.7:
		descriptions.append("bold and bitter")
	elif bitterness < 0.3:
		descriptions.append("mild")
	
	# Aroma descriptions
	if aroma > 0.7:
		descriptions.append("aromatic")
	
	if descriptions.is_empty():
		return "balanced and pleasant"
	
	return descriptions.join(", ")

func get_quality_rating() -> String:
	"""Get a quality rating as text"""
	var quality = get_quality_score()
	
	if quality >= 1.8:
		return "Outstanding"
	elif quality >= 1.5:
		return "Excellent"
	elif quality >= 1.2:
		return "Very Good"
	elif quality >= 1.0:
		return "Good"
	elif quality >= 0.8:
		return "Fair"
	else:
		return "Poor"

func duplicate_bean(amount: float) -> CoffeeBean:
	"""Create a duplicate of this bean with specified amount"""
	var new_bean = CoffeeBean.new()
	new_bean.variety = variety
	new_bean.quantity = amount
	new_bean.processing_method = processing_method
	new_bean.base_quality = base_quality
	new_bean.current_quality = current_quality
	new_bean.processing_quality = processing_quality
	new_bean.roast_quality = roast_quality
	new_bean.state = state
	new_bean.roast_level = roast_level
	new_bean.roast_date = roast_date
	new_bean.roast_profile = roast_profile.duplicate()
	new_bean.acidity = acidity
	new_bean.body = body
	new_bean.sweetness = sweetness
	new_bean.bitterness = bitterness
	new_bean.aroma = aroma
	new_bean.creation_date = creation_date
	new_bean.harvest_date = harvest_date
	new_bean.processing_date = processing_date
	new_bean.roast_date = roast_date
	new_bean.storage_temperature = storage_temperature
	new_bean.storage_humidity = storage_humidity
	new_bean.exposure_to_light = exposure_to_light
	
	return new_bean
