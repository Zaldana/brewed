class_name CafeManager
extends Node2D

# CafeManager - Manages the coffee café operations
# Handles: Customer service, drink making, ambiance, employee tasks

signal drink_served(customer: Customer, drink_type: String, quality: float, satisfaction: float)
signal customer_satisfied(customer: Customer, satisfaction: float)
signal reputation_changed(new_reputation: float)
signal employee_hired(employee: Employee)
signal task_assigned(employee_id: String, task: String)

# Café state
var employees: Array[Employee] = []
var customers: Array[Customer] = []
var current_customers: Array[Customer] = []
var cafe_equipment: Dictionary = {}

# Café statistics
var reputation: float = 3.0  # 0.0 to 5.0 stars
var daily_customers: int = 0
var total_revenue: float = 0.0
var days_operating: int = 0

# Ambiance and atmosphere
var ambiance: float = 0.7  # Affects customer satisfaction
var cleanliness: float = 0.8
var decor_level: float = 0.6
var music_volume: float = 0.5

# Customer flow
var customer_arrival_rate: float = 0.3  # Customers per hour
var max_customers: int = 10
var customer_patience: float = 0.7

# Drink recipes
var drink_recipes: Dictionary = {}

# UI references
@onready var cafe_equipment_node: Node2D = $CafeEquipment
@onready var hud: Control = $UI/HUD
@onready var serve_button: Button = $UI/HUD/BottomPanel/ActionButtons/ServeButton
@onready var grind_button: Button = $UI/HUD/BottomPanel/ActionButtons/GrindButton
@onready var clean_button: Button = $UI/HUD/BottomPanel/ActionButtons/CleanButton
@onready var hire_button: Button = $UI/HUD/BottomPanel/ActionButtons/HireButton
@onready var end_day_button: Button = $UI/HUD/BottomPanel/ActionButtons/EndDayButton
@onready var inventory_label: Label = $UI/HUD/BottomPanel/InventoryLabel
@onready var employee_label: Label = $UI/HUD/BottomPanel/EmployeeLabel
@onready var day_label: Label = $UI/HUD/TopPanel/DayLabel
@onready var reputation_label: Label = $UI/HUD/TopPanel/ReputationLabel

# Inventory manager instance
var inventory_manager: InventoryManager

func _ready():
	_initialize_cafe()
	_setup_ui_connections()
	_connect_to_managers()

func _initialize_cafe():
	"""Initialize the café with equipment and basic setup"""
	# Initialize café equipment
	_initialize_equipment()
	
	# Initialize inventory manager
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
	# Initialize drink recipes
	_initialize_drink_recipes()
	
	print("Café initialized")

func _initialize_equipment():
	"""Initialize café equipment"""
	cafe_equipment = {
		"espresso_machine": {
			"condition": 1.0,
			"temperature_control": 1.0,
			"pressure": 1.0
		},
		"grinder": {
			"condition": 1.0,
			"grind_consistency": 1.0,
			"speed": 1.0
		},
		"steam_wand": {
			"condition": 1.0,
			"steam_pressure": 1.0
		},
		"cash_register": {
			"condition": 1.0,
			"efficiency": 1.0
		}
	}

func _initialize_drink_recipes():
	"""Initialize drink recipes"""
	drink_recipes = {
		"espresso": {
			"base_beans": 0.5,  # lbs per drink
			"difficulty": 0.7,
			"price": 3.50,
			"prep_time": 2.0  # minutes
		},
		"latte": {
			"base_beans": 0.4,
			"milk": 0.2,  # cups
			"difficulty": 0.5,
			"price": 4.75,
			"prep_time": 3.0
		},
		"cappuccino": {
			"base_beans": 0.4,
			"milk": 0.15,
			"difficulty": 0.6,
			"price": 4.25,
			"prep_time": 3.5
		},
		"pour_over": {
			"base_beans": 0.6,
			"difficulty": 0.8,
			"price": 5.25,
			"prep_time": 4.0
		},
		"americano": {
			"base_beans": 0.5,
			"water": 0.5,  # cups
			"difficulty": 0.3,
			"price": 3.75,
			"prep_time": 2.5
		}
	}

func _setup_ui_connections():
	"""Connect UI buttons to functions"""
	serve_button.pressed.connect(_on_serve_button_pressed)
	grind_button.pressed.connect(_on_grind_button_pressed)
	clean_button.pressed.connect(_on_clean_button_pressed)
	hire_button.pressed.connect(_on_hire_button_pressed)
	end_day_button.pressed.connect(_on_end_day_button_pressed)

func _connect_to_managers():
	"""Connect to global managers"""
	GameManager.day_changed.connect(_on_day_changed)
	EventManager.weather_changed.connect(_on_weather_changed)

func _on_day_changed(_day: int, _season: String):
	"""Handle day changes"""
	days_operating += 1
	_process_customer_arrivals()
	_update_equipment_condition()
	_update_ui()
	
	# Process autonomous employee work
	_process_autonomous_work()

func _on_weather_changed(_weather: String, _severity: float):
	"""Handle weather changes"""
	_update_customer_arrival_rate()

func _process_customer_arrivals():
	"""Process customer arrivals for the day"""
	var customers_today = int(randf_range(5, 15) * customer_arrival_rate)
	
	for i in range(customers_today):
		var customer = _create_random_customer()
		customers.append(customer)
		current_customers.append(customer)
		daily_customers += 1
	
	print("Arrived ", customers_today, " customers today")

func _create_random_customer() -> Customer:
	"""Create a random customer"""
	var customer = Customer.new()
	customer.name = _generate_customer_name()
	customer.patience = randf_range(0.5, 1.0)
	customer.tip_likelihood = randf_range(0.3, 0.8)
	customer.preferred_drink = _get_random_drink_type()
	customer.quality_expectation = randf_range(0.6, 1.0)
	
	return customer

func _generate_customer_name() -> String:
	"""Generate a random customer name"""
	var first_names = ["Emma", "Liam", "Olivia", "Noah", "Ava", "William", "Sophia", "James", "Isabella", "Benjamin"]
	var last_names = ["Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez"]
	
	var first = first_names[randi() % first_names.size()]
	var last = last_names[randi() % last_names.size()]
	
	return first + " " + last

func _get_random_drink_type() -> String:
	"""Get a random drink type"""
	var drink_types = drink_recipes.keys()
	return drink_types[randi() % drink_types.size()]

func _update_customer_arrival_rate():
	"""Update customer arrival rate based on weather and reputation"""
	var weather = EventManager.get_current_weather()
	
	# Weather affects customer flow
	match weather:
		EventManager.WeatherType.RAIN:
			customer_arrival_rate = 0.2  # Fewer customers in rain
		EventManager.WeatherType.STORM:
			customer_arrival_rate = 0.1  # Very few customers in storms
		EventManager.WeatherType.CLEAR:
			customer_arrival_rate = 0.4  # More customers in nice weather
		_:
			customer_arrival_rate = 0.3  # Normal rate
	
	# Reputation affects customer flow
	customer_arrival_rate *= (reputation / 3.0)

func _update_equipment_condition():
	"""Update equipment condition based on usage and events"""
	for equipment in cafe_equipment:
		var condition_data = cafe_equipment[equipment]
		condition_data["condition"] = max(0.1, condition_data["condition"] - 0.001)

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
	
	# Check for customer service opportunities
	if current_customers.size() > 0:
		tasks.append("customer_service")
		tasks.append("making_drinks")
	
	# Check for grinding opportunities
	var roasted_beans = inventory_manager.get_item_amount("cafe", "roasted_beans")
	if roasted_beans > 0:
		tasks.append("grinding")
	
	# Always available tasks
	tasks.append("cleaning")
	tasks.append("cashier")
	tasks.append("inventory")
	
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
		"customer_service":
			_employee_serve_customer(employee, quality, efficiency)
		"making_drinks":
			_employee_make_drink(employee, quality, efficiency)
		"grinding":
			_employee_grind_beans(employee, quality, efficiency)
		"cleaning":
			_employee_clean(employee, quality, efficiency)
		"cashier":
			_employee_cashier(employee, quality, efficiency)
		"inventory":
			_employee_organize_inventory(employee, quality, efficiency)

func _execute_task_failure(employee: Employee, task: String, result: Dictionary):
	"""Handle a failed task"""
	print(employee.name, " failed at ", task, ": ", result.get("reason", "Unknown reason"))

func _employee_serve_customer(employee: Employee, quality: float, efficiency: float):
	"""Employee serves customers"""
	if current_customers.is_empty():
		return
	
	# Serve based on efficiency
	var customers_to_serve = int(current_customers.size() * efficiency * 0.5)
	customers_to_serve = max(1, customers_to_serve)
	
	for i in range(min(customers_to_serve, current_customers.size())):
		var customer = current_customers[i]
		var satisfaction = _calculate_customer_satisfaction(customer, quality, employee)
		
		# Customer leaves satisfied
		customer_satisfied.emit(customer, satisfaction)
		current_customers.erase(customer)
		
		# Update reputation based on satisfaction
		_update_reputation_from_satisfaction(satisfaction)
		
		# Add revenue
		var drink_price = drink_recipes[customer.preferred_drink]["price"]
		total_revenue += drink_price
		
		drink_served.emit(customer, customer.preferred_drink, quality, satisfaction)
	
	print(employee.name, " served ", customers_to_serve, " customers")

func _employee_make_drink(employee: Employee, quality: float, efficiency: float):
	"""Employee makes drinks"""
	var roasted_beans_amount = inventory_manager.get_item_amount("cafe", "roasted_beans")
	if roasted_beans_amount <= 0:
		return
	
	# Make drinks based on efficiency
	var drinks_to_make = int(efficiency * 3)  # Max 3 drinks per task
	var beans_needed = drinks_to_make * 0.5  # Average 0.5 lbs per drink
	
	if beans_needed > roasted_beans_amount:
		beans_needed = roasted_beans_amount
		drinks_to_make = int(beans_needed / 0.5)
	
	# Remove beans from inventory
	inventory_manager.remove_item("cafe", "roasted_beans", beans_needed)
	
	print(employee.name, " made ", drinks_to_make, " drinks")

func _employee_grind_beans(employee: Employee, quality: float, efficiency: float):
	"""Employee grinds beans"""
	var roasted_beans_amount = inventory_manager.get_item_amount("cafe", "roasted_beans")
	if roasted_beans_amount <= 0:
		return
	
	# Grind based on efficiency
	var beans_to_grind = min(roasted_beans_amount * efficiency * 0.3, 10.0)
	var beans_to_grind_list = inventory_manager.remove_item("cafe", "roasted_beans", beans_to_grind)
	
	for bean in beans_to_grind_list:
		if bean is CoffeeBean:
			bean.grind_beans()
			inventory_manager.add_item("cafe", "ground_beans", bean)
	
	print(employee.name, " ground ", beans_to_grind, " lbs of beans")

func _employee_clean(employee: Employee, quality: float, efficiency: float):
	"""Employee cleans the café"""
	cleanliness = min(1.0, cleanliness + 0.1 * efficiency)
	ambiance = min(1.0, ambiance + 0.05 * efficiency)
	
	print(employee.name, " cleaned the café")

func _employee_cashier(employee: Employee, quality: float, efficiency: float):
	"""Employee handles cashier duties"""
	# Improve customer satisfaction through good service
	customer_patience = min(1.0, customer_patience + 0.02 * efficiency)
	
	print(employee.name, " handled cashier duties")

func _employee_organize_inventory(employee: Employee, quality: float, efficiency: float):
	"""Employee organizes inventory"""
	# Improve efficiency slightly
	ambiance = min(1.0, ambiance + 0.01 * efficiency)
	
	print(employee.name, " organized inventory")

func _calculate_customer_satisfaction(customer: Customer, drink_quality: float, employee: Employee) -> float:
	"""Calculate customer satisfaction"""
	var base_satisfaction = 0.5
	
	# Drink quality
	base_satisfaction += drink_quality * 0.3
	
	# Employee service quality
	var service_quality = employee.get_work_quality("customer_service")
	base_satisfaction += service_quality * 0.2
	
	# Ambiance
	base_satisfaction += ambiance * 0.15
	
	# Cleanliness
	base_satisfaction += cleanliness * 0.1
	
	# Wait time (simplified)
	base_satisfaction += customer_patience * 0.1
	
	# Customer expectations
	var expectation_factor = customer.quality_expectation
	base_satisfaction *= expectation_factor
	
	return clamp(base_satisfaction, 0.0, 1.0)

func _update_reputation_from_satisfaction(satisfaction: float):
	"""Update reputation based on customer satisfaction"""
	var reputation_change = (satisfaction - 0.5) * 0.01  # Small changes
	reputation += reputation_change
	reputation = clamp(reputation, 0.0, 5.0)
	
	if abs(reputation_change) > 0.001:  # Only emit if significant change
		reputation_changed.emit(reputation)

# UI Functions
func _on_serve_button_pressed():
	"""Player serves customer manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "cafe_owner":
		_manual_serve_customer()

func _on_grind_button_pressed():
	"""Player grinds beans manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "cafe_owner":
		_manual_grind_beans()

func _on_clean_button_pressed():
	"""Player cleans café manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "cafe_owner":
		_manual_clean()

func _on_hire_button_pressed():
	"""Player hires a new employee"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "cafe_owner":
		_hire_employee()

func _on_end_day_button_pressed():
	"""Player ends the current day"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "cafe_owner":
		print("Player ended the day from cafe")
		GameManager.request_end_day()

func _manual_serve_customer():
	"""Manual customer service by player"""
	if current_customers.is_empty():
		print("No customers to serve")
		return
	
	# Serve first customer
	var customer = current_customers[0]
	var satisfaction = _calculate_customer_satisfaction(customer, 1.0, null)  # Player gets perfect quality
	
	customer_satisfied.emit(customer, satisfaction)
	current_customers.erase(customer)
	
	_update_reputation_from_satisfaction(satisfaction)
	
	var drink_price = drink_recipes[customer.preferred_drink]["price"]
	total_revenue += drink_price
	
	drink_served.emit(customer, customer.preferred_drink, 1.0, satisfaction)
	print("Served customer ", customer.name, " (Satisfaction: ", satisfaction, ")")

func _manual_grind_beans():
	"""Manual bean grinding by player"""
	var roasted_beans_amount = inventory_manager.get_item_amount("cafe", "roasted_beans")
	if roasted_beans_amount <= 0:
		print("No roasted beans to grind")
		return
	
	# Grind 2 lbs
	var beans_to_grind = min(2.0, roasted_beans_amount)
	var beans_to_grind_list = inventory_manager.remove_item("cafe", "roasted_beans", beans_to_grind)
	
	for bean in beans_to_grind_list:
		if bean is CoffeeBean:
			bean.grind_beans()
			inventory_manager.add_item("cafe", "ground_beans", bean)
	
	print("Ground ", beans_to_grind, " lbs of beans")

func _manual_clean():
	"""Manual cleaning by player"""
	cleanliness = min(1.0, cleanliness + 0.2)
	ambiance = min(1.0, ambiance + 0.1)
	print("Cleaned the café")

func _hire_employee():
	"""Hire a new employee"""
	if employees.size() >= 4:  # Max 4 employees for café
		print("Café is at maximum capacity")
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
	"""Update the UI with current café information"""
	day_label.text = "Day " + str(GameManager.get_current_day())
	
	# Update reputation display
	var stars = int(reputation)
	var half_star = (reputation - stars) >= 0.5
	var star_display = "★".repeat(stars)
	if half_star:
		star_display += "☆"
	star_display += "☆".repeat(5 - stars - (1 if half_star else 0))
	reputation_label.text = "Reputation: " + star_display
	
	var roasted_beans = inventory_manager.get_item_amount("cafe", "roasted_beans")
	var ground_beans = inventory_manager.get_item_amount("cafe", "ground_beans")
	inventory_label.text = "Roasted: " + str(int(roasted_beans)) + " lbs | Ground: " + str(int(ground_beans)) + " lbs | Customers: " + str(current_customers.size())
	
	employee_label.text = "Employees: " + str(employees.size()) + "/4"

# Getters for external systems
func get_employees() -> Array[Employee]:
	return employees

func get_inventory_manager() -> InventoryManager:
	return inventory_manager

func get_reputation() -> float:
	return reputation

func get_customers() -> Array[Customer]:
	return customers

func get_current_customers() -> Array[Customer]:
	return current_customers
