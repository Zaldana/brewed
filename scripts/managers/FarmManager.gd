class_name FarmManager
extends Node2D

# FarmManager - Manages the coffee farm operations
# Handles: Plot system, growing, harvesting, processing, employee tasks

signal crop_planted(plot_id: int, variety: CoffeeVariety)
signal crop_harvested(plot_id: int, variety: CoffeeVariety, amount: float, quality: float)
signal bean_processed(variety: CoffeeVariety, amount: float, processing_method: CoffeeVariety.ProcessingMethod)
signal employee_hired(employee: Employee)
signal task_assigned(employee_id: String, task: String)

# Farm state
var farm_plots: Array[FarmPlot] = []
var employees: Array[Employee] = []
var equipment_condition: float = 1.0
var soil_quality: float = 0.7
var irrigation_system: bool = false

# Farm statistics
var total_harvested: float = 0.0
var total_planted: int = 0
var days_operating: int = 0

# Environmental conditions
var farm_altitude: float = 0.6
var farm_rainfall: float = 0.5
var farm_temperature: float = 0.6
var farm_soil: float = 0.7

# UI references
@onready var farm_grid: Node2D = $FarmGrid
@onready var hud: Control = $UI/HUD
@onready var plant_button: Button = $UI/HUD/BottomPanel/ActionButtons/PlantButton
@onready var harvest_button: Button = $UI/HUD/BottomPanel/ActionButtons/HarvestButton
@onready var process_button: Button = $UI/HUD/BottomPanel/ActionButtons/ProcessButton
@onready var hire_button: Button = $UI/HUD/BottomPanel/ActionButtons/HireButton
@onready var inventory_label: Label = $UI/HUD/BottomPanel/InventoryLabel
@onready var employee_label: Label = $UI/HUD/BottomPanel/EmployeeLabel
@onready var day_label: Label = $UI/HUD/TopPanel/DayLabel
@onready var weather_label: Label = $UI/HUD/TopPanel/WeatherLabel

# Inventory manager instance
var inventory_manager: InventoryManager
# Coffee data loader instance
var coffee_data_loader: CoffeeDataLoader

func _ready():
	_initialize_farm()
	_setup_ui_connections()
	_connect_to_managers()

func _initialize_farm():
	"""Initialize the farm with plots and basic setup"""
	# Create farm plots (10x8 grid)
	_create_farm_plots()
	
	# Initialize inventory manager
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
	# Initialize coffee data loader
	coffee_data_loader = CoffeeDataLoader.new()
	add_child(coffee_data_loader)
	
	# Set initial farm conditions
	_update_farm_conditions()
	
	print("Farm initialized with ", farm_plots.size(), " plots")

func _create_farm_plots():
	"""Create the farm plot grid"""
	var plot_size = 64  # pixels
	var grid_width = 10
	var grid_height = 8
	var start_x = -grid_width * plot_size / 2
	var start_y = -grid_height * plot_size / 2
	
	for y in range(grid_height):
		for x in range(grid_width):
			var plot = FarmPlot.new()
			plot.plot_id = farm_plots.size()
			plot.position = Vector2(start_x + x * plot_size, start_y + y * plot_size)
			plot.plot_size = Vector2(plot_size, plot_size)
			
			farm_plots.append(plot)
			farm_grid.add_child(plot)

func _setup_ui_connections():
	"""Connect UI buttons to functions"""
	plant_button.pressed.connect(_on_plant_button_pressed)
	harvest_button.pressed.connect(_on_harvest_button_pressed)
	process_button.pressed.connect(_on_process_button_pressed)
	hire_button.pressed.connect(_on_hire_button_pressed)

func _connect_to_managers():
	"""Connect to global managers"""
	GameManager.day_changed.connect(_on_day_changed)
	EventManager.weather_changed.connect(_on_weather_changed)

func _on_day_changed(_day: int, _season: String):
	"""Handle day changes"""
	days_operating += 1
	_update_farm_conditions()
	_process_daily_growth()
	_update_ui()
	
	# Process autonomous employee work
	_process_autonomous_work()

func _on_weather_changed(weather: String, severity: float):
	"""Handle weather changes"""
	_update_farm_conditions()
	_update_ui()

func _update_farm_conditions():
	"""Update farm environmental conditions"""
	# Weather affects conditions
	var weather = EventManager.get_current_weather()
	var weather_severity = EventManager.get_weather_severity()
	
	match weather:
		EventManager.WeatherType.RAIN, EventManager.WeatherType.HEAVY_RAIN:
			farm_rainfall = min(1.0, farm_rainfall + 0.1 * weather_severity)
		EventManager.WeatherType.DROUGHT:
			farm_rainfall = max(0.0, farm_rainfall - 0.2 * weather_severity)
		EventManager.WeatherType.STORM:
			# Storms can damage equipment
			if randf() < 0.1:
				equipment_condition *= 0.95
	
	# Soil quality changes slowly over time
	soil_quality += randf_range(-0.01, 0.01)
	soil_quality = clamp(soil_quality, 0.1, 1.0)

func _process_daily_growth():
	"""Process daily growth for all planted crops"""
	for plot in farm_plots:
		if plot.is_planted() and not plot.is_ready_for_harvest():
			plot.grow_daily(farm_altitude, farm_rainfall, farm_temperature, soil_quality, equipment_condition)

func _process_autonomous_work():
	"""Process autonomous employee work"""
	for employee in employees:
		if employee.can_work():
			var available_tasks = _get_available_tasks()
			var employee_ai = EmployeeAI.new()
			var result = employee_ai.process_employee_work(employee, available_tasks)
			_handle_employee_work_result(employee, result)

func _get_available_tasks() -> Array[String]:
	"""Get list of available tasks for employees"""
	var tasks: Array[String] = []
	
	# Check for planting opportunities
	var empty_plots = 0
	for plot in farm_plots:
		if plot.is_empty():
			empty_plots += 1
	
	if empty_plots > 0:
		tasks.append("planting")
	
	# Check for harvesting opportunities
	var ready_plots = 0
	for plot in farm_plots:
		if plot.is_ready_for_harvest():
			ready_plots += 1
	
	if ready_plots > 0:
		tasks.append("harvesting")
	
	# Check for processing opportunities
	var green_beans = inventory_manager.get_item_amount("farm", "green_beans")
	if green_beans > 0:
		tasks.append("processing")
	
	# Always available tasks
	tasks.append("watering")
	tasks.append("maintenance")
	
	return tasks

func _handle_employee_work_result(employee: Employee, result: Dictionary):
	"""Handle the result of employee work"""
	match result.get("action", ""):
		"task_success":
			var task = result.get("task", "")
			_execute_task_success(employee, task, result)
		"task_failure":
			var task = result.get("task", "")
			_execute_task_failure(employee, task, result)
		"rest":
			# Employee is resting
			pass
		"idle":
			# Employee has no work
			pass

func _execute_task_success(employee: Employee, task: String, result: Dictionary):
	"""Execute a successful task"""
	var quality = result.get("quality", 1.0)
	var efficiency = result.get("efficiency", 1.0)
	
	match task:
		"planting":
			_employee_plant(employee, quality, efficiency)
		"harvesting":
			_employee_harvest(employee, quality, efficiency)
		"processing":
			_employee_process(employee, quality, efficiency)
		"watering":
			_employee_water(employee, quality, efficiency)
		"maintenance":
			_employee_maintain(employee, quality, efficiency)

func _execute_task_failure(employee: Employee, task: String, result: Dictionary):
	"""Handle a failed task"""
	print(employee.name, " failed at ", task, ": ", result.get("reason", "Unknown reason"))

func _employee_plant(employee: Employee, quality: float, efficiency: float):
	"""Employee plants seeds"""
	var empty_plots = []
	for plot in farm_plots:
		if plot.is_empty():
			empty_plots.append(plot)
	
	if empty_plots.is_empty():
		return
	
	# Employee selects best variety for conditions
	var variety = coffee_data_loader.get_best_variety_for_conditions(farm_altitude, farm_rainfall, farm_temperature, soil_quality)
	if not variety:
		variety = coffee_data_loader.get_random_variety()
	
	# Plant based on efficiency
	var plots_to_plant = int(empty_plots.size() * efficiency * 0.3)  # Max 30% of empty plots per day
	plots_to_plant = max(1, plots_to_plant)
	
	for i in range(min(plots_to_plant, empty_plots.size())):
		var plot = empty_plots[i]
		plot.plant_crop(variety, quality)
		crop_planted.emit(plot.plot_id, variety)
	
	print(employee.name, " planted ", plots_to_plant, " plots")

func _employee_harvest(employee: Employee, quality: float, efficiency: float):
	"""Employee harvests crops"""
	var ready_plots = []
	for plot in farm_plots:
		if plot.is_ready_for_harvest():
			ready_plots.append(plot)
	
	if ready_plots.is_empty():
		return
	
	# Harvest based on efficiency
	var plots_to_harvest = int(ready_plots.size() * efficiency * 0.5)  # Max 50% of ready plots per day
	plots_to_harvest = max(1, plots_to_harvest)
	
	for i in range(min(plots_to_harvest, ready_plots.size())):
		var plot = ready_plots[i]
		var harvest_result = plot.harvest_crop(quality)
		
		if harvest_result:
			var variety = harvest_result["variety"]
			var amount = harvest_result["amount"]
			var harvest_quality = harvest_result["quality"]
			
			# Create green beans
			var green_beans = CoffeeBean.new()
			green_beans.variety = variety
			green_beans.quantity = amount
			green_beans.base_quality = harvest_quality
			green_beans.harvest_date = GameManager.get_current_day()
			
			# Add to inventory
			inventory_manager.add_item("farm", "green_beans", green_beans)
			
			crop_harvested.emit(plot.plot_id, variety, amount, harvest_quality)
	
	print(employee.name, " harvested ", plots_to_harvest, " plots")

func _employee_process(employee: Employee, quality: float, efficiency: float):
	"""Employee processes green beans"""
	var green_beans_amount = inventory_manager.get_item_amount("farm", "green_beans")
	if green_beans_amount <= 0:
		return
	
	# Process based on efficiency
	var amount_to_process = green_beans_amount * efficiency * 0.2  # Max 20% of beans per day
	amount_to_process = min(amount_to_process, 10.0)  # Cap at 10 lbs per day
	
	# Remove beans from inventory
	var beans_to_process = inventory_manager.remove_item("farm", "green_beans", amount_to_process)
	
	for bean in beans_to_process:
		if bean is CoffeeBean:
			# Choose processing method (employee preference)
			var processing_method = _choose_processing_method(employee, bean.variety)
			bean.process_beans(processing_method, quality)
			
			# Add processed beans to inventory
			inventory_manager.add_item("farm", "processed_beans", bean)
			
			bean_processed.emit(bean.variety, bean.quantity, processing_method)
	
	print(employee.name, " processed ", amount_to_process, " lbs of beans")

func _employee_water(employee: Employee, quality: float, efficiency: float):
	"""Employee waters crops"""
	# Improve growth conditions
	farm_rainfall = min(1.0, farm_rainfall + 0.05 * efficiency)
	
	# Give growth boost to planted crops
	for plot in farm_plots:
		if plot.is_planted() and not plot.is_ready_for_harvest():
			plot.give_water_boost(efficiency)

func _employee_maintain(employee: Employee, quality: float, efficiency: float):
	"""Employee maintains equipment"""
	equipment_condition = min(1.0, equipment_condition + 0.02 * efficiency)
	
	# Improve soil quality slightly
	soil_quality = min(1.0, soil_quality + 0.01 * efficiency)

func _choose_processing_method(employee: Employee, variety: CoffeeVariety) -> CoffeeVariety.ProcessingMethod:
	"""Employee chooses processing method based on traits and variety"""
	var available_methods = variety.available_processing
	
	if employee.has_trait(Employee.TraitType.CREATIVE):
		# Creative employees might try different methods
		return available_methods[randi() % available_methods.size()]
	else:
		# Conservative employees use the first available method (usually washed)
		return available_methods[0]

# UI Functions
func _on_plant_button_pressed():
	"""Player plants seeds manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "farmer":
		_manual_plant()

func _on_harvest_button_pressed():
	"""Player harvests crops manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "farmer":
		_manual_harvest()

func _on_process_button_pressed():
	"""Player processes beans manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "farmer":
		_manual_process()

func _on_hire_button_pressed():
	"""Player hires a new employee"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "farmer":
		_hire_employee()

func _manual_plant():
	"""Manual planting by player"""
	var empty_plots = []
	for plot in farm_plots:
		if plot.is_empty():
			empty_plots.append(plot)
	
	if empty_plots.is_empty():
		print("No empty plots available")
		return
	
	# Player selects variety (for now, random)
	var variety = coffee_data_loader.get_random_variety()
	var plot = empty_plots[0]  # Plant in first empty plot
	plot.plant_crop(variety, 1.0)  # Player gets perfect quality
	crop_planted.emit(plot.plot_id, variety)
	print("Planted ", variety.variety_name, " in plot ", plot.plot_id)

func _manual_harvest():
	"""Manual harvesting by player"""
	var ready_plots = []
	for plot in farm_plots:
		if plot.is_ready_for_harvest():
			ready_plots.append(plot)
	
	if ready_plots.is_empty():
		print("No crops ready for harvest")
		return
	
	# Harvest first ready plot
	var plot = ready_plots[0]
	var harvest_result = plot.harvest_crop(1.0)  # Player gets perfect quality
	
	if harvest_result:
		var variety = harvest_result["variety"]
		var amount = harvest_result["amount"]
		var harvest_quality = harvest_result["quality"]
		
		# Create green beans
		var green_beans = CoffeeBean.new()
		green_beans.variety = variety
		green_beans.quantity = amount
		green_beans.base_quality = harvest_quality
		green_beans.harvest_date = GameManager.get_current_day()
		
		# Add to inventory
		inventory_manager.add_item("farm", "green_beans", green_beans)
		
		crop_harvested.emit(plot.plot_id, variety, amount, harvest_quality)
		print("Harvested ", amount, " lbs of ", variety.variety_name)

func _manual_process():
	"""Manual processing by player"""
	var green_beans_amount = inventory_manager.get_item_amount("farm", "green_beans")
	if green_beans_amount <= 0:
		print("No green beans to process")
		return
	
	# Process 5 lbs
	var amount_to_process = min(5.0, green_beans_amount)
	var beans_to_process = inventory_manager.remove_item("farm", "green_beans", amount_to_process)
	
	for bean in beans_to_process:
		if bean is CoffeeBean:
			# Use washed processing (most common)
			bean.process_beans(CoffeeVariety.ProcessingMethod.WASHED, 1.0)  # Player gets perfect quality
			inventory_manager.add_item("farm", "processed_beans", bean)
			bean_processed.emit(bean.variety, bean.quantity, CoffeeVariety.ProcessingMethod.WASHED)
	
	print("Processed ", amount_to_process, " lbs of beans")

func _hire_employee():
	"""Hire a new employee"""
	if employees.size() >= 5:  # Max 5 employees
		print("Farm is at maximum capacity")
		return
	
	var employee = _create_random_employee()
	employees.append(employee)
	employee_hired.emit(employee)
	print("Hired new employee: ", employee.name)

func _create_random_employee() -> Employee:
	"""Create a random employee with random traits"""
	var employee = Employee.new()
	employee.name = _generate_random_name()
	employee.age = randi_range(20, 50)
	
	# Add random traits (2-4 traits)
	var trait_count = randi_range(2, 4)
	var all_traits = Employee.TraitType.values()
	for i in range(trait_count):
		var trait_type = all_traits[randi() % all_traits.size()]
		employee.add_trait(trait_type)
	
	return employee

func _generate_random_name() -> String:
	"""Generate a random employee name"""
	var first_names = ["Alex", "Jordan", "Casey", "Riley", "Morgan", "Taylor", "Avery", "Quinn"]
	var last_names = ["Smith", "Johnson", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor"]
	
	var first = first_names[randi() % first_names.size()]
	var last = last_names[randi() % last_names.size()]
	
	return first + " " + last

func _update_ui():
	"""Update the UI with current farm information"""
	day_label.text = "Day " + str(GameManager.get_current_day())
	weather_label.text = EventManager._weather_to_string(EventManager.get_current_weather())
	
	var green_beans = inventory_manager.get_item_amount("farm", "green_beans")
	var processed_beans = inventory_manager.get_item_amount("farm", "processed_beans")
	inventory_label.text = "Green: " + str(int(green_beans)) + " lbs | Processed: " + str(int(processed_beans)) + " lbs"
	
	employee_label.text = "Employees: " + str(employees.size()) + "/5"

# Getters for external systems
func get_farm_plots() -> Array[FarmPlot]:
	return farm_plots

func get_employees() -> Array[Employee]:
	return employees

func get_inventory_manager() -> InventoryManager:
	return inventory_manager

func get_soil_quality() -> float:
	return soil_quality

func get_equipment_condition() -> float:
	return equipment_condition
