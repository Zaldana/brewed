extends Node

# EventManager - Handles all random events and event dispatching
# Handles: Weather events, equipment breakdowns, employee events, market events

signal game_event(event_type: String, event_data: Dictionary)
signal weather_changed(weather: String, severity: float)
signal equipment_broken(equipment: String, location: String)
signal employee_event(employee_id: String, event_type: String, event_data: Dictionary)

# Weather system
enum WeatherType {
	CLEAR,
	PARTLY_CLOUDY,
	CLOUDY,
	RAIN,
	HEAVY_RAIN,
	STORM,
	DROUGHT,
	FROST
}

var current_weather: WeatherType = WeatherType.CLEAR
var weather_severity: float = 1.0
var weather_duration: int = 1

# Event probabilities (per day)
const EVENT_PROBABILITIES = {
	"weather_change": 0.3,
	"equipment_failure": 0.05,
	"employee_incident": 0.1,
	"market_event": 0.1,
	"special_event": 0.02
}

# Equipment failure data
var equipment_conditions: Dictionary = {}

func _ready():
	_initialize_weather()
	_initialize_equipment()
	
	# Connect to game manager
	GameManager.day_changed.connect(_on_day_changed)

func _initialize_weather():
	"""Initialize weather system"""
	current_weather = WeatherType.CLEAR
	weather_severity = 1.0
	weather_duration = randf_range(3, 7)  # Days
	print("Weather system initialized - Clear skies")

func _initialize_equipment():
	"""Initialize equipment condition tracking"""
	# Farm equipment
	equipment_conditions = {
		"farm_irrigation": {"condition": 1.0, "last_maintenance": 0},
		"farm_tractor": {"condition": 1.0, "last_maintenance": 0},
		"roastery_roaster": {"condition": 1.0, "last_maintenance": 0},
		"roastery_grinder": {"condition": 1.0, "last_maintenance": 0},
		"cafe_espresso_machine": {"condition": 1.0, "last_maintenance": 0},
		"cafe_grinder": {"condition": 1.0, "last_maintenance": 0}
	}
	print("Equipment tracking initialized")

func _on_day_changed(_day: int, _season: String):
	"""Process daily events"""
	_process_weather()
	_process_equipment_aging()
	_generate_random_events()

func _process_weather():
	"""Update weather conditions"""
	weather_duration -= 1
	
	if weather_duration <= 0:
		_change_weather()
	
	# Weather effects on gameplay
	_apply_weather_effects()

func _change_weather():
	"""Change to new weather condition"""
	var season = GameManager.get_current_season()
	var new_weather = _get_seasonal_weather(season)
	
	current_weather = new_weather
	weather_severity = randf_range(0.5, 1.5)
	weather_duration = randi_range(2, 6)
	
	weather_changed.emit(_weather_to_string(current_weather), weather_severity)
	print("Weather changed to: ", _weather_to_string(current_weather))

func _get_seasonal_weather(season: GameManager.Season) -> WeatherType:
	"""Get weather appropriate for the season"""
	var weather_options: Array[WeatherType] = []
	
	match season:
		GameManager.Season.SPRING:
			weather_options = [WeatherType.CLEAR, WeatherType.PARTLY_CLOUDY, WeatherType.RAIN, WeatherType.CLOUDY]
		GameManager.Season.SUMMER:
			weather_options = [WeatherType.CLEAR, WeatherType.PARTLY_CLOUDY, WeatherType.STORM, WeatherType.DROUGHT]
		GameManager.Season.AUTUMN:
			weather_options = [WeatherType.CLEAR, WeatherType.CLOUDY, WeatherType.RAIN, WeatherType.PARTLY_CLOUDY]
		GameManager.Season.WINTER:
			weather_options = [WeatherType.CLOUDY, WeatherType.FROST, WeatherType.CLEAR, WeatherType.RAIN]
	
	return weather_options[randi() % weather_options.size()]

func _apply_weather_effects():
	"""Apply weather effects to gameplay"""
	match current_weather:
		WeatherType.RAIN, WeatherType.HEAVY_RAIN:
			# Good for crops but may cause delays
			game_event.emit("weather_effect", {
				"type": "rain_benefit",
				"effect": "crop_growth_boost",
				"severity": weather_severity
			})
		
		WeatherType.DROUGHT:
			# Bad for crops
			game_event.emit("weather_effect", {
				"type": "drought_penalty",
				"effect": "crop_growth_reduction",
				"severity": weather_severity
			})
		
		WeatherType.STORM:
			# May damage equipment or cause delays
			if randf() < 0.2:  # 20% chance of damage
				var equipment = _get_random_equipment()
				damage_equipment(equipment, 0.1)
		
		WeatherType.FROST:
			# Can damage crops
			game_event.emit("weather_effect", {
				"type": "frost_damage",
				"effect": "crop_damage",
				"severity": weather_severity
			})

func _process_equipment_aging():
	"""Process natural equipment wear and tear"""
	for equipment in equipment_conditions:
		var condition_data = equipment_conditions[equipment]
		var _days_since_maintenance = GameManager.get_current_day() - condition_data["last_maintenance"]
		
		# Equipment degrades over time
		var degradation_rate = 0.001  # 0.1% per day
		condition_data["condition"] = max(0.0, condition_data["condition"] - degradation_rate)
		
		# Higher chance of failure when condition is low
		if condition_data["condition"] < 0.3 and randf() < 0.1:
			_trigger_equipment_failure(equipment)

func _generate_random_events():
	"""Generate random events based on probabilities"""
	for event_type in EVENT_PROBABILITIES:
		if randf() < EVENT_PROBABILITIES[event_type]:
			_trigger_event(event_type)

func _trigger_event(event_type: String):
	"""Trigger a specific type of event"""
	match event_type:
		"equipment_failure":
			var equipment = _get_random_equipment()
			_trigger_equipment_failure(equipment)
		
		"employee_incident":
			_trigger_employee_event()
		
		"market_event":
			# Market events are handled by EconomyManager
			pass
		
		"special_event":
			_trigger_special_event()

func _trigger_equipment_failure(equipment: String):
	"""Trigger equipment failure"""
	var condition_data = equipment_conditions.get(equipment, {"condition": 1.0})
	var damage_amount = randf_range(0.1, 0.3)
	
	condition_data["condition"] = max(0.0, condition_data["condition"] - damage_amount)
	equipment_conditions[equipment] = condition_data
	
	var location = _get_equipment_location(equipment)
	equipment_broken.emit(equipment, location)
	
	game_event.emit("equipment_failure", {
		"equipment": equipment,
		"location": location,
		"damage": damage_amount,
		"new_condition": condition_data["condition"]
	})
	
	print("Equipment failure: ", equipment, " at ", location)

func _trigger_employee_event():
	"""Trigger random employee event"""
	var event_types = ["mood_boost", "mood_drop", "skill_improvement", "accident", "innovation"]
	var event_type = event_types[randi() % event_types.size()]
	
	# TODO: Select random employee when employee system is implemented
	var employee_id = "temp_employee"
	
	employee_event.emit(employee_id, event_type, {
		"severity": randf_range(0.5, 1.5),
		"description": _get_employee_event_description(event_type)
	})
	
	print("Employee event: ", event_type, " for ", employee_id)

func _trigger_special_event():
	"""Trigger special seasonal or story events"""
	var special_events = [
		"coffee_festival",
		"inspector_visit",
		"new_customer",
		"equipment_sale",
		"weather_forecast"
	]
	
	var event = special_events[randi() % special_events.size()]
	
	game_event.emit("special_event", {
		"type": event,
		"description": _get_special_event_description(event)
	})
	
	print("Special event: ", event)

func damage_equipment(equipment: String, damage: float):
	"""Manually damage equipment"""
	if equipment in equipment_conditions:
		var condition_data = equipment_conditions[equipment]
		condition_data["condition"] = max(0.0, condition_data["condition"] - damage)
		print("Equipment damaged: ", equipment, " - ", damage * 100, "% damage")

func repair_equipment(equipment: String, repair_amount: float = 1.0):
	"""Repair equipment"""
	if equipment in equipment_conditions:
		var condition_data = equipment_conditions[equipment]
		condition_data["condition"] = min(1.0, condition_data["condition"] + repair_amount)
		condition_data["last_maintenance"] = GameManager.get_current_day()
		print("Equipment repaired: ", equipment)

func _get_random_equipment() -> String:
	"""Get a random equipment piece"""
	var equipment_list = equipment_conditions.keys()
	return equipment_list[randi() % equipment_list.size()]

func _get_equipment_location(equipment: String) -> String:
	"""Get the location of equipment"""
	if "farm" in equipment:
		return "Farm"
	elif "roastery" in equipment:
		return "Roastery"
	elif "cafe" in equipment:
		return "Cafe"
	else:
		return "Unknown"

func _weather_to_string(weather: WeatherType) -> String:
	match weather:
		WeatherType.CLEAR: return "Clear"
		WeatherType.PARTLY_CLOUDY: return "Partly Cloudy"
		WeatherType.CLOUDY: return "Cloudy"
		WeatherType.RAIN: return "Rain"
		WeatherType.HEAVY_RAIN: return "Heavy Rain"
		WeatherType.STORM: return "Storm"
		WeatherType.DROUGHT: return "Drought"
		WeatherType.FROST: return "Frost"
		_: return "Unknown"

func _get_employee_event_description(event_type: String) -> String:
	match event_type:
		"mood_boost": return "Employee is feeling great today!"
		"mood_drop": return "Employee seems stressed and distracted."
		"skill_improvement": return "Employee has learned something new!"
		"accident": return "Employee had a minor accident."
		"innovation": return "Employee came up with a creative idea!"
		_: return "Something happened with an employee."

func _get_special_event_description(event: String) -> String:
	match event:
		"coffee_festival": return "The annual coffee festival is coming up!"
		"inspector_visit": return "Health inspectors are visiting this week."
		"new_customer": return "A potential new customer is interested."
		"equipment_sale": return "There's a sale on coffee equipment."
		"weather_forecast": return "Weather forecast predicts unusual conditions."
		_: return "A special event is happening."

# Getters
func get_current_weather() -> WeatherType:
	return current_weather

func get_weather_severity() -> float:
	return weather_severity

func get_equipment_condition(equipment: String) -> float:
	return equipment_conditions.get(equipment, {"condition": 1.0})["condition"]

func get_all_equipment_conditions() -> Dictionary:
	return equipment_conditions
