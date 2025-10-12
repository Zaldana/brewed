class_name Employee
extends Resource

# Employee Resource - Core employee data and personality system
# Dwarf Fortress-style personality with traits, moods, and autonomous behavior

signal mood_changed(new_mood: MoodType, old_mood: MoodType)
signal trait_activated(trait_name: String, context: String)
signal skill_improved(skill: String, new_level: int)
signal need_changed(need: NeedType, new_value: float)

# Core identification
@export var id: String = ""
@export var name: String = ""
@export var age: int = 25
@export var portrait: Texture2D

# Personality traits (Dwarf Fortress style)
enum TraitType {
	HARDWORKING,    # Works longer and more efficiently
	CLUMSY,         # More likely to make mistakes
	CREATIVE,       # May discover new recipes/methods
	PERFECTIONIST,  # Higher quality work, slower speed
	SOCIAL,         # Better customer interaction, team morale
	ANXIOUS,        # Stress affects performance
	OPTIMISTIC,     # Resistant to mood drops
	LAZY,          # Works slower, needs more breaks
	INTELLIGENT,    # Learns faster, better problem solving
	STRONG,         # Physical tasks are easier
	ARTISTIC,       # Better at creative tasks
	ORGANIZED       # Less likely to make organizational mistakes
}

# Current mood system
enum MoodType {
	ECSTATIC,       # +20% quality, +15% speed
	HAPPY,          # +10% quality, +5% speed
	CONTENT,        # Normal performance
	WORRIED,        # -5% quality, -5% speed
	STRESSED,       # -15% quality, -10% speed
	DEPRESSED,      # -25% quality, -20% speed
	SICK,           # -50% performance, may need time off
	INSPIRED        # +15% quality, +10% speed, may innovate
}

# Needs system
enum NeedType {
	REST,           # Sleep, breaks
	SOCIAL,         # Interaction with others
	FAIR_WAGES,     # Money satisfaction
	RECOGNITION,    # Praise and acknowledgment
	SAFETY,         # Safe working conditions
	CHALLENGE,      # Interesting work
	AUTONOMY        # Freedom to make decisions
}

# Skills and experience
enum SkillType {
	FARMING,        # Growing, harvesting, processing
	ROASTING,       # Roasting, blending, QC
	BARISTA,        # Making drinks, customer service
	MANAGEMENT,     # Leading others, organization
	MECHANICAL,     # Equipment maintenance
	CUSTOMER_SERVICE # Interacting with customers
}

# Employee data structure
@export var traits: Array[TraitType] = []
@export var current_mood: MoodType = MoodType.CONTENT
@export var mood_history: Array[MoodType] = []
@export var skills: Dictionary = {}  # SkillType -> level (0-100)
@export var experience: Dictionary = {}  # SkillType -> experience points
@export var needs: Dictionary = {}  # NeedType -> satisfaction (0.0-1.0)
@export var energy: float = 1.0
@export var stress: float = 0.0

# Work preferences and efficiency
@export var preferred_tasks: Array[String] = []
@export var efficiency_modifiers: Dictionary = {}  # Task -> modifier
@export var quality_modifiers: Dictionary = {}  # Task -> modifier

# Relationships with other employees
@export var relationships: Dictionary = {}  # Employee ID -> relationship value (-1.0 to 1.0)

# Current status
@export var is_working: bool = false
@export var current_task: String = ""
@export var work_location: String = ""
@export var days_worked: int = 0
@export var total_satisfaction: float = 0.5

func _init():
	_initialize_defaults()

func _initialize_defaults():
	# Initialize skills
	for skill in SkillType.values():
		skills[skill] = 0
		experience[skill] = 0.0
	
	# Initialize needs
	for need in NeedType.values():
		needs[need] = 0.5  # Start at neutral
	
	# Initialize mood history
	mood_history = [current_mood]
	
	# Initialize efficiency and quality modifiers
	efficiency_modifiers = {}
	quality_modifiers = {}

func add_trait(trait_type: TraitType):
	if trait_type not in traits:
		traits.append(trait_type)
		_update_modifiers_from_traits()
		print("Added trait ", TraitType.keys()[trait_type], " to ", name)

func remove_trait(trait_type: TraitType):
	if trait_type in traits:
		traits.erase(trait_type)
		_update_modifiers_from_traits()
		print("Removed trait ", TraitType.keys()[trait_type], " from ", name)

func _update_modifiers_from_traits():
	efficiency_modifiers.clear()
	quality_modifiers.clear()
	
	for trait_type in traits:
		match trait_type:
			TraitType.HARDWORKING:
				efficiency_modifiers["default"] = 1.2
			TraitType.CLUMSY:
				quality_modifiers["default"] = 0.8
				efficiency_modifiers["default"] = 0.9
			TraitType.CREATIVE:
				quality_modifiers["creative_tasks"] = 1.3
			TraitType.PERFECTIONIST:
				quality_modifiers["default"] = 1.4
				efficiency_modifiers["default"] = 0.7
			TraitType.SOCIAL:
				quality_modifiers["customer_service"] = 1.3
			TraitType.ANXIOUS:
				quality_modifiers["default"] = 0.9
			TraitType.OPTIMISTIC:
				# Resistant to mood drops
				pass
			TraitType.LAZY:
				efficiency_modifiers["default"] = 0.7
			TraitType.INTELLIGENT:
				quality_modifiers["complex_tasks"] = 1.2
			TraitType.STRONG:
				efficiency_modifiers["physical_tasks"] = 1.3
			TraitType.ARTISTIC:
				quality_modifiers["creative_tasks"] = 1.3
			TraitType.ORGANIZED:
				efficiency_modifiers["organizational_tasks"] = 1.2

func change_mood(new_mood: MoodType, reason: String = ""):
	var old_mood = current_mood
	current_mood = new_mood
	mood_history.append(new_mood)
	
	# Keep mood history reasonable size
	if mood_history.size() > 30:
		mood_history.pop_front()
	
	mood_changed.emit(new_mood, old_mood)
	print(name, " mood changed from ", MoodType.keys()[old_mood], " to ", MoodType.keys()[new_mood], " - ", reason)

func update_need(need: NeedType, change: float, reason: String = ""):
	var old_value = needs[need]
	needs[need] = clamp(needs[need] + change, 0.0, 1.0)
	
	need_changed.emit(need, needs[need])
	
	# Check for mood changes based on needs
	_check_need_based_mood_changes()
	
	print(name, " need ", NeedType.keys()[need], " changed from ", old_value, " to ", needs[need], " - ", reason)

func _check_need_based_mood_changes():
	var total_need_satisfaction = 0.0
	for need_value in needs.values():
		total_need_satisfaction += need_value
	
	var average_satisfaction = total_need_satisfaction / needs.size()
	
	# Mood changes based on overall satisfaction
	if average_satisfaction > 0.8 and current_mood < MoodType.HAPPY:
		change_mood(MoodType.HAPPY, "High need satisfaction")
	elif average_satisfaction < 0.3 and current_mood > MoodType.WORRIED:
		change_mood(MoodType.WORRIED, "Low need satisfaction")
	
	# Check for critical needs
	for need in needs:
		if needs[need] < 0.2:
			if need == NeedType.REST and current_mood != MoodType.SICK:
				change_mood(MoodType.SICK, "Exhausted")
			elif need == NeedType.SOCIAL and current_mood > MoodType.STRESSED:
				change_mood(MoodType.STRESSED, "Lonely")

func gain_experience(skill: SkillType, amount: float):
	var old_level = skills[skill]
	experience[skill] += amount
	
	# Check for level up (every 100 experience points)
	var new_level = int(experience[skill] / 100)
	if new_level > old_level:
		skills[skill] = new_level
		skill_improved.emit(SkillType.keys()[skill], new_level)
		print(name, " leveled up ", SkillType.keys()[skill], " to level ", new_level)

func get_work_efficiency(task: String) -> float:
	var base_efficiency = efficiency_modifiers.get("default", 1.0)
	var task_efficiency = efficiency_modifiers.get(task, 1.0)
	var mood_efficiency = _get_mood_efficiency_modifier()
	
	return base_efficiency * task_efficiency * mood_efficiency

func get_work_quality(task: String) -> float:
	var base_quality = quality_modifiers.get("default", 1.0)
	var task_quality = quality_modifiers.get(task, 1.0)
	var mood_quality = _get_mood_quality_modifier()
	
	return base_quality * task_quality * mood_quality

func _get_mood_efficiency_modifier() -> float:
	match current_mood:
		MoodType.ECSTATIC: return 1.15
		MoodType.HAPPY: return 1.05
		MoodType.CONTENT: return 1.0
		MoodType.WORRIED: return 0.95
		MoodType.STRESSED: return 0.90
		MoodType.DEPRESSED: return 0.80
		MoodType.SICK: return 0.50
		MoodType.INSPIRED: return 1.10
		_: return 1.0

func _get_mood_quality_modifier() -> float:
	match current_mood:
		MoodType.ECSTATIC: return 1.20
		MoodType.HAPPY: return 1.10
		MoodType.CONTENT: return 1.0
		MoodType.WORRIED: return 0.95
		MoodType.STRESSED: return 0.85
		MoodType.DEPRESSED: return 0.75
		MoodType.SICK: return 0.50
		MoodType.INSPIRED: return 1.15
		_: return 1.0

func can_work() -> bool:
	return current_mood != MoodType.SICK and energy > 0.2 and is_working == false

func start_work(task: String, location: String):
	if can_work():
		is_working = true
		current_task = task
		work_location = location
		print(name, " started working on ", task, " at ", location)
		return true
	return false

func stop_work():
	if is_working:
		is_working = false
		current_task = ""
		work_location = ""
		days_worked += 1
		print(name, " stopped working")

func daily_update():
	# Energy recovery
	energy = min(1.0, energy + 0.3)
	
	# Stress decay
	stress = max(0.0, stress - 0.1)
	
	# Need decay (needs gradually decrease over time)
	for need in needs:
		needs[need] = max(0.0, needs[need] - 0.05)
	
	# Random mood events
	if randf() < 0.1:  # 10% chance per day
		_random_mood_event()
	
	# Trait-based events
	for trait_type in traits:
		if randf() < 0.05:  # 5% chance per trait per day
			_trait_event(trait_type)

func _random_mood_event():
	var events = [
		{"mood": MoodType.HAPPY, "reason": "Received praise from supervisor"},
		{"mood": MoodType.WORRIED, "reason": "Concerned about work performance"},
		{"mood": MoodType.INSPIRED, "reason": "Had a creative breakthrough"},
		{"mood": MoodType.STRESSED, "reason": "Workload feels overwhelming"}
	]
	
	var event = events[randi() % events.size()]
	change_mood(event["mood"], event["reason"])

func _trait_event(trait_type: TraitType):
	match trait_type:
		TraitType.CLUMSY:
			if randf() < 0.3:
				change_mood(MoodType.WORRIED, "Made a mistake due to clumsiness")
		TraitType.CREATIVE:
			if randf() < 0.2:
				change_mood(MoodType.INSPIRED, "Had a creative idea")
		TraitType.SOCIAL:
			if randf() < 0.3:
				update_need(NeedType.SOCIAL, 0.2, "Had positive social interaction")
		TraitType.ANXIOUS:
			if randf() < 0.4:
				stress += 0.1
				change_mood(MoodType.WORRIED, "Feeling anxious about work")

func get_relationship(employee_id: String) -> float:
	return relationships.get(employee_id, 0.0)

func update_relationship(employee_id: String, change: float, reason: String = ""):
	var old_relationship = relationships.get(employee_id, 0.0)
	relationships[employee_id] = clamp(old_relationship + change, -1.0, 1.0)
	
	print(name, " relationship with ", employee_id, " changed from ", old_relationship, " to ", relationships[employee_id], " - ", reason)

# Getters for external systems
func get_skill_level(skill: SkillType) -> int:
	return skills.get(skill, 0)

func get_experience_points(skill: SkillType) -> float:
	return experience.get(skill, 0.0)

func get_need_satisfaction(need: NeedType) -> float:
	return needs.get(need, 0.5)

func has_trait(trait_type: TraitType) -> bool:
	return trait_type in traits

func get_overall_satisfaction() -> float:
	var total = 0.0
	for need_value in needs.values():
		total += need_value
	return total / needs.size()

func get_mood_stability() -> float:
	if mood_history.size() < 2:
		return 1.0
	
	var mood_changes = 0
	for i in range(1, mood_history.size()):
		if mood_history[i] != mood_history[i-1]:
			mood_changes += 1
	
	return 1.0 - (float(mood_changes) / float(mood_history.size() - 1))
