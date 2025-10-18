class_name RoasteryManager
extends Node2D

# RoasteryManager - Manages the coffee roastery operations
# Handles: Roasting, quality control, blending, employee tasks

signal beans_roasted(variety: CoffeeVariety, amount: float, roast_level: String, quality: float)
signal blend_created(blend_name: String, varieties: Array, amount: float, quality: float)
signal quality_controlled(beans: CoffeeBean, quality_score: float, passed: bool)
signal employee_hired(employee: Employee)
signal task_assigned(employee_id: String, task: String)

# Roastery state
var employees: Array[Employee] = []
var roasting_equipment: Dictionary = {}
var blending_recipes: Array[Dictionary] = []

# Equipment condition
var roaster_condition: float = 1.0
var grinder_condition: float = 1.0
var storage_condition: float = 1.0

# Roastery statistics
var total_roasted: float = 0.0
var total_blends_created: int = 0
var days_operating: int = 0

# Current roasting batch
var current_batch: CoffeeBean = null
var roasting_in_progress: bool = false
var roasting_start_time: float = 0.0
var roasting_duration: float = 0.0

# UI references
@onready var roastery_equipment: Node2D = $RoasteryEquipment
@onready var hud: Control = $UI/HUD
@onready var roast_button: Button = $UI/HUD/BottomPanel/ActionButtons/RoastButton
@onready var qc_button: Button = $UI/HUD/BottomPanel/ActionButtons/QCButton
@onready var blend_button: Button = $UI/HUD/BottomPanel/ActionButtons/BlendButton
@onready var hire_button: Button = $UI/HUD/BottomPanel/ActionButtons/HireButton
@onready var end_day_button: Button = $UI/HUD/BottomPanel/ActionButtons/EndDayButton
@onready var inventory_label: Label = $UI/HUD/BottomPanel/InventoryLabel
@onready var employee_label: Label = $UI/HUD/BottomPanel/EmployeeLabel
@onready var day_label: Label = $UI/HUD/TopPanel/DayLabel
@onready var equipment_label: Label = $UI/HUD/TopPanel/EquipmentLabel

# Inventory manager instance
var inventory_manager: InventoryManager

func _ready():
	_initialize_roastery()
	_setup_ui_connections()
	_connect_to_managers()

func _initialize_roastery():
	"""Initialize the roastery with equipment and basic setup"""
	# Initialize roasting equipment
	_initialize_equipment()
	
	# Initialize inventory manager
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
	# Initialize blending recipes
	_initialize_blending_recipes()
	
	print("Roastery initialized")

func _initialize_equipment():
	"""Initialize roasting equipment"""
	roasting_equipment = {
		"roaster": {
			"capacity": 50.0,  # pounds per batch
			"condition": 1.0,
			"temperature_control": 1.0,
			"precision": 1.0
		},
		"grinder": {
			"capacity": 20.0,  # pounds per hour
			"condition": 1.0,
			"grind_consistency": 1.0
		},
		"storage": {
			"capacity": 500.0,  # pounds
			"condition": 1.0,
			"temperature_control": 1.0
		}
	}

func _initialize_blending_recipes():
	"""Initialize blending recipes"""
	blending_recipes = [
		{
			"name": "Morning Blend",
			"description": "A balanced blend for morning coffee",
			"varieties": ["arabica_classic", "colombian_supremo"],
			"ratios": [0.7, 0.3],
			"roast_level": "medium"
		},
		{
			"name": "Espresso Blend",
			"description": "A rich blend perfect for espresso",
			"varieties": ["arabica_classic", "robusta_bold"],
			"ratios": [0.6, 0.4],
			"roast_level": "dark"
		},
		{
			"name": "House Blend",
			"description": "Our signature house blend",
			"varieties": ["ethiopian_yirgacheffe", "colombian_supremo"],
			"ratios": [0.5, 0.5],
			"roast_level": "medium"
		}
	]

func _setup_ui_connections():
	"""Connect UI buttons to functions"""
	roast_button.pressed.connect(_on_roast_button_pressed)
	qc_button.pressed.connect(_on_qc_button_pressed)
	blend_button.pressed.connect(_on_blend_button_pressed)
	hire_button.pressed.connect(_on_hire_button_pressed)
	end_day_button.pressed.connect(_on_end_day_button_pressed)

func _connect_to_managers():
	"""Connect to global managers"""
	GameManager.day_changed.connect(_on_day_changed)
	EventManager.weather_changed.connect(_on_weather_changed)

func _on_day_changed(_day: int, _season: String):
	"""Handle day changes"""
	days_operating += 1
	_update_equipment_condition()
	_update_ui()
	
	# Process autonomous employee work
	_process_autonomous_work()

func _on_weather_changed(_weather: String, _severity: float):
	"""Handle weather changes"""
	_update_equipment_condition()

func _update_equipment_condition():
	"""Update equipment condition based on usage and events"""
	# Equipment degrades over time
	roaster_condition = max(0.1, roaster_condition - 0.001)
	grinder_condition = max(0.1, grinder_condition - 0.001)
	storage_condition = max(0.1, storage_condition - 0.001)
	
	# Update equipment dictionary
	roasting_equipment["roaster"]["condition"] = roaster_condition
	roasting_equipment["grinder"]["condition"] = grinder_condition
	roasting_equipment["storage"]["condition"] = storage_condition

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
	
	# Check for roasting opportunities
	var green_beans = inventory_manager.get_item_amount("roastery", "green_beans")
	if green_beans > 0 and not roasting_in_progress:
		tasks.append("roasting")
	
	# Check for quality control opportunities
	var roasted_beans = inventory_manager.get_item_amount("roastery", "roasted_beans")
	if roasted_beans > 0:
		tasks.append("quality_control")
	
	# Check for blending opportunities
	if roasted_beans > 10.0:  # Need at least 10 lbs for blending
		tasks.append("blending")
	
	# Check for packaging opportunities
	if roasted_beans > 5.0:
		tasks.append("packaging")
	
	# Always available tasks
	tasks.append("maintenance")
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
		"roasting":
			_employee_roast(employee, quality, efficiency)
		"quality_control":
			_employee_quality_control(employee, quality, efficiency)
		"blending":
			_employee_blend(employee, quality, efficiency)
		"packaging":
			_employee_package(employee, quality, efficiency)
		"maintenance":
			_employee_maintain(employee, quality, efficiency)
		"inventory":
			_employee_organize_inventory(employee, quality, efficiency)

func _execute_task_failure(employee: Employee, task: String, result: Dictionary):
	"""Handle a failed task"""
	print(employee.name, " failed at ", task, ": ", result.get("reason", "Unknown reason"))

func _employee_roast(employee: Employee, quality: float, efficiency: float):
	"""Employee roasts beans"""
	var green_beans_amount = inventory_manager.get_item_amount("roastery", "green_beans")
	if green_beans_amount <= 0:
		return
	
	# Determine batch size based on equipment and efficiency
	var max_batch_size = roasting_equipment["roaster"]["capacity"] * roaster_condition
	var batch_size = min(green_beans_amount * efficiency * 0.5, max_batch_size)
	batch_size = max(5.0, batch_size)  # Minimum 5 lbs
	
	# Remove beans from inventory
	var beans_to_roast = inventory_manager.remove_item("roastery", "green_beans", batch_size)
	
	for bean in beans_to_roast:
		if bean is CoffeeBean:
			# Choose roast level based on employee preference and variety
			var roast_level = _choose_roast_level(employee, bean.variety)
			bean.roast_beans(roast_level, quality)
			
			# Add roasted beans to inventory
			inventory_manager.add_item("roastery", "roasted_beans", bean)
			
			total_roasted += bean.quantity
			beans_roasted.emit(bean.variety, bean.quantity, roast_level, quality)
	
	print(employee.name, " roasted ", batch_size, " lbs of beans")

func _employee_quality_control(employee: Employee, quality: float, efficiency: float):
	"""Employee performs quality control"""
	var roasted_beans_amount = inventory_manager.get_item_amount("roastery", "roasted_beans")
	if roasted_beans_amount <= 0:
		return
	
	# Check based on efficiency
	var amount_to_check = min(roasted_beans_amount * efficiency * 0.3, 20.0)
	var beans_to_check = inventory_manager.remove_item("roastery", "roasted_beans", amount_to_check)
	
	for bean in beans_to_check:
		if bean is CoffeeBean:
			var quality_score = bean.get_quality_score()
			var passed_qc = quality_score >= 0.8  # Minimum quality threshold
			
			if passed_qc:
				# Return to inventory
				inventory_manager.add_item("roastery", "roasted_beans", bean)
			else:
				# Failed QC - reduce quality or discard
				bean.current_quality *= 0.9
				inventory_manager.add_item("roastery", "roasted_beans", bean)
			
			quality_controlled.emit(bean, quality_score, passed_qc)
	
	print(employee.name, " performed QC on ", amount_to_check, " lbs of beans")

func _employee_blend(employee: Employee, quality: float, efficiency: float):
	"""Employee creates blends"""
	var roasted_beans_amount = inventory_manager.get_item_amount("roastery", "roasted_beans")
	if roasted_beans_amount < 10.0:
		return
	
	# Choose a blend recipe
	var recipe = blending_recipes[randi() % blending_recipes.size()]
	var blend_amount = min(roasted_beans_amount * efficiency * 0.2, 20.0)
	
	# Create blend (simplified - in reality would need multiple varieties)
	var blend_beans = inventory_manager.remove_item("roastery", "roasted_beans", blend_amount)
	
	if not blend_beans.is_empty():
		var blend_bean = blend_beans[0]
		blend_bean.roast_level = recipe["roast_level"]
		
		# Improve quality through blending
		blend_bean.current_quality *= 1.1
		
		# Add to inventory as blend
		inventory_manager.add_item("roastery", "roasted_beans", blend_bean)
		
		total_blends_created += 1
		blend_created.emit(recipe["name"], [blend_bean.variety], blend_amount, quality)
	
	print(employee.name, " created ", recipe["name"], " blend")

func _employee_package(employee: Employee, quality: float, efficiency: float):
	"""Employee packages roasted beans"""
	var roasted_beans_amount = inventory_manager.get_item_amount("roastery", "roasted_beans")
	if roasted_beans_amount <= 0:
		return
	
	# Package based on efficiency
	var amount_to_package = min(roasted_beans_amount * efficiency * 0.4, 30.0)
	
	# In a real game, this would create packaged products
	# For now, just remove from inventory (simulating sale)
	inventory_manager.remove_item("roastery", "roasted_beans", amount_to_package)
	
	print(employee.name, " packaged ", amount_to_package, " lbs of roasted beans")

func _employee_maintain(employee: Employee, quality: float, efficiency: float):
	"""Employee maintains equipment"""
	var maintenance_amount = 0.02 * efficiency
	
	roaster_condition = min(1.0, roaster_condition + maintenance_amount)
	grinder_condition = min(1.0, grinder_condition + maintenance_amount * 0.8)
	storage_condition = min(1.0, storage_condition + maintenance_amount * 0.5)
	
	print(employee.name, " maintained equipment (", int(maintenance_amount * 100), "% improvement)")

func _employee_organize_inventory(employee: Employee, quality: float, efficiency: float):
	"""Employee organizes inventory"""
	# Improve storage conditions slightly
	storage_condition = min(1.0, storage_condition + 0.01 * efficiency)
	
	print(employee.name, " organized inventory")

func _choose_roast_level(employee: Employee, variety: CoffeeVariety) -> String:
	"""Employee chooses roast level based on traits and variety"""
	if employee.has_trait(Employee.TraitType.CREATIVE):
		# Creative employees might experiment
		var levels = ["light", "medium", "dark"]
		return levels[randi() % levels.size()]
	elif employee.has_trait(Employee.TraitType.PERFECTIONIST):
		# Perfectionists prefer medium roasts
		return "medium"
	else:
		# Default to medium roast
		return "medium"

# UI Functions
func _on_roast_button_pressed():
	"""Player roasts beans manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "roaster":
		_manual_roast()

func _on_qc_button_pressed():
	"""Player performs quality control manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "roaster":
		_manual_quality_control()

func _on_blend_button_pressed():
	"""Player creates blend manually"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "roaster":
		_manual_blend()

func _on_hire_button_pressed():
	"""Player hires a new employee"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "roaster":
		_hire_employee()

func _on_end_day_button_pressed():
	"""Player ends the current day"""
	if GameManager.is_day_play() and GameManager.get_selected_sibling() == "roaster":
		print("Player ended the day from roastery")
		GameManager.request_end_day()

func _manual_roast():
	"""Manual roasting by player"""
	var green_beans_amount = inventory_manager.get_item_amount("roastery", "green_beans")
	if green_beans_amount <= 0:
		print("No green beans to roast")
		return
	
	# Roast 10 lbs
	var amount_to_roast = min(10.0, green_beans_amount)
	var beans_to_roast = inventory_manager.remove_item("roastery", "green_beans", amount_to_roast)
	
	for bean in beans_to_roast:
		if bean is CoffeeBean:
			# Player chooses medium roast
			bean.roast_beans("medium", 1.0)  # Player gets perfect quality
			inventory_manager.add_item("roastery", "roasted_beans", bean)
			
			total_roasted += bean.quantity
			beans_roasted.emit(bean.variety, bean.quantity, "medium", 1.0)
	
	print("Roasted ", amount_to_roast, " lbs of beans")

func _manual_quality_control():
	"""Manual quality control by player"""
	var roasted_beans_amount = inventory_manager.get_item_amount("roastery", "roasted_beans")
	if roasted_beans_amount <= 0:
		print("No roasted beans to check")
		return
	
	# Check 5 lbs
	var amount_to_check = min(5.0, roasted_beans_amount)
	var beans_to_check = inventory_manager.remove_item("roastery", "roasted_beans", amount_to_check)
	
	for bean in beans_to_check:
		if bean is CoffeeBean:
			var quality_score = bean.get_quality_score()
			var passed_qc = quality_score >= 0.8
			
			# Player always passes QC (for now)
			inventory_manager.add_item("roastery", "roasted_beans", bean)
			quality_controlled.emit(bean, quality_score, true)
	
	print("Performed QC on ", amount_to_check, " lbs of beans")

func _manual_blend():
	"""Manual blending by player"""
	var roasted_beans_amount = inventory_manager.get_item_amount("roastery", "roasted_beans")
	if roasted_beans_amount < 5.0:
		print("Not enough roasted beans for blending")
		return
	
	# Create a simple blend
	var amount_to_blend = min(5.0, roasted_beans_amount)
	var beans_to_blend = inventory_manager.remove_item("roastery", "roasted_beans", amount_to_blend)
	
	if not beans_to_blend.is_empty():
		var blend_bean = beans_to_blend[0]
		blend_bean.roast_level = "medium"
		blend_bean.current_quality *= 1.1
		
		inventory_manager.add_item("roastery", "roasted_beans", blend_bean)
		
		total_blends_created += 1
		blend_created.emit("Player Blend", [blend_bean.variety], amount_to_blend, 1.0)
	
	print("Created blend with ", amount_to_blend, " lbs of beans")

func _hire_employee():
	"""Hire a new employee"""
	if employees.size() >= 3:  # Max 3 employees for roastery
		print("Roastery is at maximum capacity")
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
	"""Update the UI with current roastery information"""
	day_label.text = "Day " + str(GameManager.get_current_day())
	equipment_label.text = "Roaster: " + str(int(roaster_condition * 100)) + "%"
	
	var green_beans = inventory_manager.get_item_amount("roastery", "green_beans")
	var roasted_beans = inventory_manager.get_item_amount("roastery", "roasted_beans")
	inventory_label.text = "Green: " + str(int(green_beans)) + " lbs | Roasted: " + str(int(roasted_beans)) + " lbs"
	
	employee_label.text = "Employees: " + str(employees.size()) + "/3"

# Getters for external systems
func get_employees() -> Array[Employee]:
	return employees

func get_inventory_manager() -> InventoryManager:
	return inventory_manager

func get_roaster_condition() -> float:
	return roaster_condition

func get_equipment_conditions() -> Dictionary:
	return roasting_equipment
