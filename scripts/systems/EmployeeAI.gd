class_name EmployeeAI
extends Node

# EmployeeAI - Autonomous decision making for employees
# Dwarf Fortress-style AI that makes decisions without player control

signal task_completed(employee_id: String, task: String, quality: float, efficiency: float)
signal task_failed(employee_id: String, task: String, reason: String)
signal innovation_discovered(employee_id: String, innovation: String)
signal employee_event(employee_id: String, event_type: String, details: Dictionary)

# Task priorities and preferences
var task_priorities: Dictionary = {}
var available_tasks: Array[String] = []
var task_difficulties: Dictionary = {}

# AI decision making
var decision_threshold: float = 0.5
var risk_tolerance: float = 0.5

func _ready():
	_initialize_task_system()

func _initialize_task_system():
	"""Initialize the task system with priorities and difficulties"""
	task_priorities = {
		"planting": 0.8,
		"watering": 0.9,
		"harvesting": 1.0,
		"processing": 0.7,
		"roasting": 0.8,
		"quality_control": 0.9,
		"packaging": 0.6,
		"blending": 0.5,
		"customer_service": 0.7,
		"making_drinks": 0.8,
		"cleaning": 0.4,
		"maintenance": 0.3,
		"inventory": 0.6
	}
	
	task_difficulties = {
		"planting": 0.3,
		"watering": 0.2,
		"harvesting": 0.4,
		"processing": 0.6,
		"roasting": 0.8,
		"quality_control": 0.7,
		"packaging": 0.3,
		"blending": 0.9,
		"customer_service": 0.5,
		"making_drinks": 0.6,
		"cleaning": 0.1,
		"maintenance": 0.7,
		"inventory": 0.4
	}
	
	available_tasks = task_priorities.keys()

func process_employee_work(employee: Employee, available_tasks_for_location: Array[String]) -> Dictionary:
	"""Process what an employee should do during autonomous work"""
	if not employee.can_work():
		return {"action": "rest", "reason": "Cannot work (sick, no energy, etc.)"}
	
	# Select best task based on AI decision making
	var selected_task = _select_task(employee, available_tasks_for_location)
	if selected_task == "":
		return {"action": "idle", "reason": "No suitable tasks available"}
	
	# Perform the task
	var result = _perform_task(employee, selected_task)
	return result

func _select_task(employee: Employee, available_tasks: Array[String]) -> String:
	"""AI selects the best task for an employee"""
	var task_scores: Dictionary = {}
	
	for task in available_tasks:
		var score = _calculate_task_score(employee, task)
		task_scores[task] = score
	
	# Sort tasks by score
	var sorted_tasks = []
	for task in task_scores:
		sorted_tasks.append({"task": task, "score": task_scores[task]})
	
	sorted_tasks.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Select task based on AI personality and randomness
	var selected_task = _ai_task_selection(employee, sorted_tasks)
	return selected_task

func _calculate_task_score(employee: Employee, task: String) -> float:
	"""Calculate how suitable a task is for an employee"""
	var base_score = task_priorities.get(task, 0.5)
	var difficulty = task_difficulties.get(task, 0.5)
	
	# Skill-based scoring
	var relevant_skill = _get_relevant_skill(task)
	var skill_level = employee.get_skill_level(relevant_skill)
	var skill_score = float(skill_level) / 100.0
	
	# Trait-based modifiers
	var trait_modifier = _get_trait_modifier(employee, task)
	
	# Mood-based modifiers
	var mood_modifier = _get_mood_modifier(employee, task)
	
	# Energy and stress factors
	var energy_factor = employee.energy
	var stress_factor = 1.0 - employee.stress
	
	# Calculate final score
	var score = base_score * (0.3 + skill_score * 0.4) * trait_modifier * mood_modifier * energy_factor * stress_factor
	
	# Difficulty penalty (harder tasks are less attractive unless employee is skilled)
	if difficulty > skill_score:
		score *= (1.0 - (difficulty - skill_score) * 0.5)
	
	return score

func _get_relevant_skill(task: String) -> Employee.SkillType:
	"""Get the most relevant skill for a task"""
	match task:
		"planting", "watering", "harvesting", "processing":
			return Employee.SkillType.FARMING
		"roasting", "quality_control", "packaging", "blending":
			return Employee.SkillType.ROASTING
		"customer_service", "making_drinks":
			return Employee.SkillType.BARISTA
		"maintenance":
			return Employee.SkillType.MECHANICAL
		"inventory", "cleaning":
			return Employee.SkillType.MANAGEMENT
		_:
			return Employee.SkillType.FARMING

func _get_trait_modifier(employee: Employee, task: String) -> float:
	"""Get trait-based modifier for task preference"""
	var modifier = 1.0
	
	for trait_type in employee.traits:
		match trait_type:
			Employee.TraitType.HARDWORKING:
				modifier *= 1.2
			Employee.TraitType.LAZY:
				if task in ["cleaning", "maintenance", "inventory"]:
					modifier *= 0.7
				else:
					modifier *= 0.8
			Employee.TraitType.CREATIVE:
				if task in ["blending", "making_drinks"]:
					modifier *= 1.3
			Employee.TraitType.SOCIAL:
				if task == "customer_service":
					modifier *= 1.4
			Employee.TraitType.ANXIOUS:
				if task in ["roasting", "quality_control"]:
					modifier *= 0.8
			Employee.TraitType.PERFECTIONIST:
				if task in ["quality_control", "roasting"]:
					modifier *= 1.3
			Employee.TraitType.STRONG:
				if task in ["harvesting", "processing", "maintenance"]:
					modifier *= 1.2
	
	return modifier

func _get_mood_modifier(employee: Employee, task: String) -> float:
	"""Get mood-based modifier for task preference"""
	match employee.current_mood:
		Employee.MoodType.ECSTATIC:
			return 1.3
		Employee.MoodType.HAPPY:
			return 1.1
		Employee.MoodType.CONTENT:
			return 1.0
		Employee.MoodType.WORRIED:
			return 0.9
		Employee.MoodType.STRESSED:
			return 0.8
		Employee.MoodType.DEPRESSED:
			return 0.6
		Employee.MoodType.SICK:
			return 0.3
		Employee.MoodType.INSPIRED:
			if task in ["blending", "making_drinks", "processing"]:
				return 1.4
			else:
				return 1.1
		_:
			return 1.0

func _ai_task_selection(employee: Employee, sorted_tasks: Array) -> String:
	"""AI selects task based on personality and randomness"""
	if sorted_tasks.is_empty():
		return ""
	
	# Get top 3 tasks
	var top_tasks = []
	for i in range(min(3, sorted_tasks.size())):
		top_tasks.append(sorted_tasks[i])
	
	# Personality-based selection
	var selection_bias = _get_selection_bias(employee)
	
	# Weighted random selection
	var total_weight = 0.0
	for i in range(top_tasks.size()):
		var weight = pow(0.5, i) * (1.0 + selection_bias)
		top_tasks[i]["weight"] = weight
		total_weight += weight
	
	# Random selection
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for task_data in top_tasks:
		current_weight += task_data["weight"]
		if random_value <= current_weight:
			return task_data["task"]
	
	# Fallback to first task
	return top_tasks[0]["task"]

func _get_selection_bias(employee: Employee) -> float:
	"""Get selection bias based on employee personality"""
	var bias = 0.0
	
	for trait_type in employee.traits:
		match trait_type:
			Employee.TraitType.CREATIVE:
				bias += 0.3  # Prefer creative tasks
			Employee.TraitType.LAZY:
				bias -= 0.2  # Prefer easier tasks
			Employee.TraitType.HARDWORKING:
				bias += 0.1  # Slight preference for harder tasks
			Employee.TraitType.ANXIOUS:
				bias -= 0.1  # Prefer safer tasks
	
	return clamp(bias, -0.5, 0.5)

func _perform_task(employee: Employee, task: String) -> Dictionary:
	"""Perform the selected task"""
	var difficulty = task_difficulties.get(task, 0.5)
	var skill_level = employee.get_skill_level(_get_relevant_skill(task))
	
	# Calculate success chance
	var base_success = 0.8
	var skill_bonus = float(skill_level) / 100.0 * 0.3
	var mood_bonus = _get_mood_performance_modifier(employee)
	var trait_bonus = _get_trait_performance_modifier(employee, task)
	
	var success_chance = base_success + skill_bonus + mood_bonus + trait_bonus - difficulty * 0.2
	success_chance = clamp(success_chance, 0.1, 0.95)
	
	# Attempt the task
	var success = randf() < success_chance
	
	if success:
		var result = _task_success(employee, task, difficulty)
		return result
	else:
		var result = _task_failure(employee, task)
		return result

func _task_success(employee: Employee, task: String, difficulty: float) -> Dictionary:
	"""Handle successful task completion"""
	var quality = employee.get_work_quality(task)
	var efficiency = employee.get_work_efficiency(task)
	
	# Gain experience
	var skill = _get_relevant_skill(task)
	var experience_gain = difficulty * 5.0 * efficiency
	employee.gain_experience(skill, experience_gain)
	
	# Update needs and mood
	_update_needs_from_task(employee, task, true)
	
	# Check for innovation
	var innovation = _check_for_innovation(employee, task)
	
	# Energy cost
	employee.energy = max(0.0, employee.energy - 0.1)
	
	task_completed.emit(employee.id, task, quality, efficiency)
	
	var result = {
		"action": "task_success",
		"task": task,
		"quality": quality,
		"efficiency": efficiency,
		"experience_gained": experience_gain,
		"innovation": innovation
	}
	
	print(employee.name, " successfully completed ", task, " (Quality: ", quality, ", Efficiency: ", efficiency, ")")
	
	return result

func _task_failure(employee: Employee, task: String) -> Dictionary:
	"""Handle failed task"""
	var reason = _get_failure_reason(employee, task)
	
	# Mood impact
	employee.change_mood(Employee.MoodType.WORRIED, "Failed at " + task)
	
	# Stress increase
	employee.stress = min(1.0, employee.stress + 0.1)
	
	# Still gain some experience (learning from failure)
	var skill = _get_relevant_skill(task)
	employee.gain_experience(skill, 1.0)
	
	# Update needs
	_update_needs_from_task(employee, task, false)
	
	# Energy cost (less than success)
	employee.energy = max(0.0, employee.energy - 0.05)
	
	task_failed.emit(employee.id, task, reason)
	
	var result = {
		"action": "task_failure",
		"task": task,
		"reason": reason,
		"stress_increase": 0.1
	}
	
	print(employee.name, " failed at ", task, " - ", reason)
	
	return result

func _get_failure_reason(employee: Employee, task: String) -> String:
	"""Get a reason for task failure"""
	var reasons = []
	
	if employee.has_trait(Employee.TraitType.CLUMSY):
		reasons.append("Made a mistake due to clumsiness")
	if employee.current_mood == Employee.MoodType.DEPRESSED:
		reasons.append("Lack of motivation")
	if employee.energy < 0.3:
		reasons.append("Too tired to focus")
	if employee.stress > 0.7:
		reasons.append("Too stressed to perform well")
	if employee.get_skill_level(_get_relevant_skill(task)) < 20:
		reasons.append("Lacks sufficient skill")
	
	if reasons.is_empty():
		reasons.append("Unlucky circumstances")
	
	return reasons[randi() % reasons.size()]

func _update_needs_from_task(employee: Employee, task: String, success: bool):
	"""Update employee needs based on task completion"""
	if success:
		employee.update_need(Employee.NeedType.RECOGNITION, 0.1, "Completed task successfully")
		if task == "customer_service":
			employee.update_need(Employee.NeedType.SOCIAL, 0.2, "Positive customer interaction")
	else:
		employee.update_need(Employee.NeedType.RECOGNITION, -0.1, "Failed to complete task")

func _check_for_innovation(employee: Employee, task: String) -> String:
	"""Check if employee discovers something new"""
	if not employee.has_trait(Employee.TraitType.CREATIVE):
		return ""
	
	if employee.current_mood == Employee.MoodType.INSPIRED and randf() < 0.15:
		var innovations = {
			"blending": "New blend combination discovered",
			"making_drinks": "New drink recipe created",
			"roasting": "Improved roasting technique found",
			"processing": "Better processing method developed"
		}
		
		if task in innovations:
			innovation_discovered.emit(employee.id, innovations[task])
			employee.change_mood(Employee.MoodType.ECSTATIC, "Made an innovation!")
			return innovations[task]
	
	return ""

func _get_mood_performance_modifier(employee: Employee) -> float:
	"""Get performance modifier based on mood"""
	match employee.current_mood:
		Employee.MoodType.ECSTATIC: return 0.2
		Employee.MoodType.HAPPY: return 0.1
		Employee.MoodType.CONTENT: return 0.0
		Employee.MoodType.WORRIED: return -0.05
		Employee.MoodType.STRESSED: return -0.1
		Employee.MoodType.DEPRESSED: return -0.2
		Employee.MoodType.SICK: return -0.4
		Employee.MoodType.INSPIRED: return 0.15
		_: return 0.0

func _get_trait_performance_modifier(employee: Employee, task: String) -> float:
	"""Get performance modifier based on traits"""
	var modifier = 0.0
	
	for trait_type in employee.traits:
		match trait_type:
			Employee.TraitType.HARDWORKING:
				modifier += 0.1
			Employee.TraitType.CLUMSY:
				modifier -= 0.1
			Employee.TraitType.PERFECTIONIST:
				if task in ["quality_control", "roasting"]:
					modifier += 0.15
			Employee.TraitType.INTELLIGENT:
				if task_difficulties.get(task, 0.5) > 0.6:
					modifier += 0.1
	
	return modifier
