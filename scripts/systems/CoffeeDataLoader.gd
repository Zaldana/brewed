class_name CoffeeDataLoader
extends Node

# CoffeeDataLoader - Loads and manages coffee variety data
# Handles: Loading varieties from JSON, creating variety instances, data management

var loaded_varieties: Dictionary = {}  # variety_id -> CoffeeVariety

func _ready():
	load_coffee_varieties()

func load_coffee_varieties():
	"""Load all coffee varieties from JSON data"""
	var file = FileAccess.open("res://data/json/coffee_varieties.json", FileAccess.READ)
	if not file:
		print("Error: Could not open coffee varieties JSON file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing coffee varieties JSON: ", json.get_error_message())
		return false
	
	var data = json.data
	if not data.has("coffee_varieties"):
		print("Error: JSON missing 'coffee_varieties' key")
		return false
	
	for variety_data in data["coffee_varieties"]:
		var variety = _create_variety_from_data(variety_data)
		if variety:
			loaded_varieties[variety.variety_id] = variety
			print("Loaded variety: ", variety.variety_name)
	
	print("Loaded ", loaded_varieties.size(), " coffee varieties")
	return true

func _create_variety_from_data(data: Dictionary) -> CoffeeVariety:
	"""Create a CoffeeVariety instance from JSON data"""
	var variety = CoffeeVariety.new()
	
	# Basic properties
	variety.variety_name = data.get("variety_name", "Unknown")
	variety.variety_id = data.get("variety_id", "unknown")
	variety.description = data.get("description", "")
	
	# Growing characteristics
	variety.growth_time_days = data.get("growth_time_days", 180)
	variety.yield_per_plant = data.get("yield_per_plant", 1.0)
	var harvest_seasons_data = data.get("harvest_seasons", [1, 2, 3])
	variety.harvest_seasons.clear()
	for season in harvest_seasons_data:
		variety.harvest_seasons.append(int(season))
	
	# Environmental preferences
	variety.altitude_preference = data.get("altitude_preference", 0.5)
	variety.rainfall_preference = data.get("rainfall_preference", 0.5)
	variety.temperature_preference = data.get("temperature_preference", 0.5)
	variety.soil_preference = data.get("soil_preference", 0.5)
	
	# Quality characteristics
	variety.base_acidity = data.get("base_acidity", 0.5)
	variety.base_body = data.get("base_body", 0.5)
	variety.base_sweetness = data.get("base_sweetness", 0.5)
	variety.base_bitterness = data.get("base_bitterness", 0.5)
	variety.base_aroma = data.get("base_aroma", 0.5)
	
	# Processing methods
	var processing_strings = data.get("available_processing", ["washed"])
	variety.available_processing.clear()
	for processing_str in processing_strings:
		var method = _string_to_processing_method(processing_str)
		if method != -1:
			variety.available_processing.append(method)
	
	# Market characteristics
	variety.rarity = data.get("rarity", 0.5)
	variety.base_price_multiplier = data.get("base_price_multiplier", 1.0)
	variety.demand_trend = data.get("demand_trend", 0.0)
	
	# Visual properties
	var color_data = data.get("color_tint", {"r": 1.0, "g": 1.0, "b": 1.0, "a": 1.0})
	variety.color_tint = Color(
		color_data.get("r", 1.0),
		color_data.get("g", 1.0),
		color_data.get("b", 1.0),
		color_data.get("a", 1.0)
	)
	
	return variety

func _string_to_processing_method(method_string: String) -> CoffeeVariety.ProcessingMethod:
	"""Convert string to ProcessingMethod enum"""
	match method_string.to_lower():
		"washed":
			return CoffeeVariety.ProcessingMethod.WASHED
		"natural":
			return CoffeeVariety.ProcessingMethod.NATURAL
		"honey":
			return CoffeeVariety.ProcessingMethod.HONEY
		"semi_washed":
			return CoffeeVariety.ProcessingMethod.SEMI_WASHED
		_:
			return -1

func get_variety_by_id(variety_id: String) -> CoffeeVariety:
	"""Get a variety by its ID"""
	return loaded_varieties.get(variety_id, null)

func get_variety_by_name(variety_name: String) -> CoffeeVariety:
	"""Get a variety by its name"""
	for variety in loaded_varieties.values():
		if variety.variety_name == variety_name:
			return variety
	return null

func get_all_varieties() -> Array[CoffeeVariety]:
	"""Get all loaded varieties"""
	var varieties: Array[CoffeeVariety] = []
	for variety in loaded_varieties.values():
		varieties.append(variety)
	return varieties

func get_varieties_by_rarity(max_rarity: float) -> Array[CoffeeVariety]:
	"""Get varieties with rarity up to specified level"""
	var varieties: Array[CoffeeVariety] = []
	for variety in loaded_varieties.values():
		if variety.rarity <= max_rarity:
			varieties.append(variety)
	return varieties

func get_varieties_for_season(season: int) -> Array[CoffeeVariety]:
	"""Get varieties that can be harvested in specified season"""
	var varieties: Array[CoffeeVariety] = []
	for variety in loaded_varieties.values():
		if season in variety.harvest_seasons:
			varieties.append(variety)
	return varieties

func get_random_variety() -> CoffeeVariety:
	"""Get a random variety"""
	if loaded_varieties.is_empty():
		return null
	
	var variety_ids = loaded_varieties.keys()
	var random_id = variety_ids[randi() % variety_ids.size()]
	return loaded_varieties[random_id]

func get_best_variety_for_conditions(altitude: float, rainfall: float, temperature: float, soil: float) -> CoffeeVariety:
	"""Get the variety best suited for given environmental conditions"""
	var best_variety: CoffeeVariety = null
	var best_score = 0.0
	
	for variety in loaded_varieties.values():
		var score = variety.get_environmental_suitability(altitude, rainfall, temperature, soil)
		if score > best_score:
			best_score = score
			best_variety = variety
	
	return best_variety

func get_variety_count() -> int:
	"""Get total number of loaded varieties"""
	return loaded_varieties.size()

func reload_varieties():
	"""Reload varieties from JSON (useful for modding)"""
	loaded_varieties.clear()
	return load_coffee_varieties()
