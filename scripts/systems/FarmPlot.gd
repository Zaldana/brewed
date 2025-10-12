class_name FarmPlot
extends Node2D

# FarmPlot - Individual plot for growing coffee plants
# Handles: Planting, growing, harvesting, visual representation

signal plot_planted(variety: CoffeeVariety)
signal plot_harvested(variety: CoffeeVariety, amount: float, quality: float)
signal growth_stage_changed(stage: int)

# Plot data
var plot_id: int = 0
var plot_size: Vector2 = Vector2(64, 64)
var variety: CoffeeVariety = null
var planted_date: int = 0
var growth_days: int = 0
var growth_stage: int = 0  # 0 = empty, 1-4 = growing stages, 5 = ready for harvest
var quality_modifier: float = 1.0

# Visual representation
var plot_rect: ColorRect
var plant_sprite: Label

func _ready():
	_create_visual_elements()
	_update_visual()

func _create_visual_elements():
	"""Create visual elements for the plot"""
	# Plot background
	plot_rect = ColorRect.new()
	plot_rect.size = plot_size
	plot_rect.position = -plot_size / 2
	plot_rect.color = Color(0.6, 0.4, 0.2, 1.0)  # Brown soil color
	add_child(plot_rect)
	
	# Plant representation (using text for now)
	plant_sprite = Label.new()
	plant_sprite.text = ""
	plant_sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plant_sprite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plant_sprite.position = -plot_size / 2
	plant_sprite.size = plot_size
	add_child(plant_sprite)

func plant_crop(coffee_variety: CoffeeVariety, quality: float):
	"""Plant a crop in this plot"""
	if not is_empty():
		print("Error: Plot is not empty")
		return false
	
	self.variety = coffee_variety
	self.planted_date = GameManager.get_current_day()
	self.growth_days = 0
	self.growth_stage = 1
	self.quality_modifier = quality
	
	_update_visual()
	plot_planted.emit(coffee_variety)
	print("Planted ", coffee_variety.variety_name, " in plot ", plot_id)
	return true

func grow_daily(altitude: float, rainfall: float, temperature: float, soil_quality: float, equipment_condition: float):
	"""Process daily growth"""
	if is_empty() or is_ready_for_harvest():
		return
	
	growth_days += 1
	
	# Calculate growth rate based on environmental conditions
	var environmental_fitness = variety.get_environmental_suitability(altitude, rainfall, temperature, soil_quality)
	var growth_rate = environmental_fitness * equipment_condition * quality_modifier
	
	# Weather effects
	var weather = EventManager.get_current_weather()
	match weather:
		EventManager.WeatherType.RAIN, EventManager.WeatherType.HEAVY_RAIN:
			growth_rate *= 1.2  # Rain helps growth
		EventManager.WeatherType.DROUGHT:
			growth_rate *= 0.7  # Drought slows growth
		EventManager.WeatherType.FROST:
			growth_rate *= 0.5  # Frost damages crops
		EventManager.WeatherType.STORM:
			growth_rate *= 0.8  # Storms slow growth
	
	# Calculate required growth days for this variety
	var required_growth_days = variety.growth_time_days
	
	# Update growth stage (5 stages total)
	var stage_progress = float(growth_days) / float(required_growth_days)
	var new_stage = int(stage_progress * 5) + 1
	new_stage = clamp(new_stage, 1, 5)
	
	if new_stage != growth_stage:
		growth_stage = new_stage
		growth_stage_changed.emit(growth_stage)
		_update_visual()
	
	# Update quality based on growing conditions
	quality_modifier = lerp(quality_modifier, environmental_fitness, 0.01)

func give_water_boost(efficiency: float):
	"""Give a watering boost to the crop"""
	if is_empty() or is_ready_for_harvest():
		return
	
	# Watering gives a small growth boost
	growth_days += int(efficiency * 2)
	quality_modifier = min(1.2, quality_modifier + 0.01 * efficiency)

func harvest_crop(harvest_quality: float) -> Dictionary:
	"""Harvest the crop from this plot"""
	if not is_ready_for_harvest():
		print("Error: Crop not ready for harvest")
		return {}
	
	# Calculate harvest amount
	var base_yield = variety.yield_per_plant
	var total_quality = quality_modifier * harvest_quality
	var harvest_amount = base_yield * total_quality
	
	# Add some randomness
	harvest_amount *= randf_range(0.8, 1.2)
	
	var result = {
		"variety": variety,
		"amount": harvest_amount,
		"quality": total_quality
	}
	
	plot_harvested.emit(variety, harvest_amount, total_quality)
	
	# Reset plot
	_reset_plot()
	
	print("Harvested ", harvest_amount, " lbs of ", variety.variety_name, " (Quality: ", total_quality, ")")
	return result

func _reset_plot():
	"""Reset plot to empty state"""
	variety = null
	planted_date = 0
	growth_days = 0
	growth_stage = 0
	quality_modifier = 1.0
	
	_update_visual()

func is_empty() -> bool:
	"""Check if plot is empty"""
	return variety == null

func is_planted() -> bool:
	"""Check if plot has a planted crop"""
	return variety != null and growth_stage > 0

func is_ready_for_harvest() -> bool:
	"""Check if crop is ready for harvest"""
	return growth_stage >= 5

func get_growth_progress() -> float:
	"""Get growth progress as percentage (0.0 to 1.0)"""
	if is_empty():
		return 0.0
	if is_ready_for_harvest():
		return 1.0
	
	return float(growth_stage) / 5.0

func get_days_until_harvest() -> int:
	"""Get estimated days until harvest"""
	if is_empty() or is_ready_for_harvest():
		return 0
	
	var required_growth_days = variety.growth_time_days
	return max(0, required_growth_days - growth_days)

func _update_visual():
	"""Update visual representation of the plot"""
	if is_empty():
		# Empty plot - brown soil
		plot_rect.color = Color(0.6, 0.4, 0.2, 1.0)
		plant_sprite.text = ""
	elif growth_stage == 0:
		# Just planted
		plot_rect.color = Color(0.5, 0.3, 0.1, 1.0)
		plant_sprite.text = "."
		plant_sprite.modulate = Color.GREEN
	elif growth_stage == 1:
		# Seedling
		plot_rect.color = Color(0.5, 0.3, 0.1, 1.0)
		plant_sprite.text = "."
		plant_sprite.modulate = Color.GREEN
	elif growth_stage == 2:
		# Small plant
		plot_rect.color = Color(0.4, 0.3, 0.1, 1.0)
		plant_sprite.text = "|"
		plant_sprite.modulate = Color.GREEN
	elif growth_stage == 3:
		# Medium plant
		plot_rect.color = Color(0.4, 0.3, 0.1, 1.0)
		plant_sprite.text = "Y"
		plant_sprite.modulate = Color.DARK_GREEN
	elif growth_stage == 4:
		# Large plant
		plot_rect.color = Color(0.4, 0.3, 0.1, 1.0)
		plant_sprite.text = "¥"
		plant_sprite.modulate = Color.DARK_GREEN
	elif growth_stage >= 5:
		# Ready for harvest
		plot_rect.color = Color(0.4, 0.3, 0.1, 1.0)
		plant_sprite.text = "☕"
		plant_sprite.modulate = Color.YELLOW
	
	# Quality indicator (border color)
	if not is_empty():
		if quality_modifier > 1.1:
			plot_rect.color = plot_rect.color.lightened(0.2)  # High quality - lighter
		elif quality_modifier < 0.9:
			plot_rect.color = plot_rect.color.darkened(0.2)   # Low quality - darker

func get_variety() -> CoffeeVariety:
	"""Get the variety planted in this plot"""
	return variety

func get_quality_modifier() -> float:
	"""Get the current quality modifier"""
	return quality_modifier

func get_planted_date() -> int:
	"""Get the date when this plot was planted"""
	return planted_date

func get_growth_stage() -> int:
	"""Get the current growth stage"""
	return growth_stage
