class_name Customer
extends Resource

# Customer Resource - Represents individual café customers
# Handles: Order preferences, satisfaction, patience, tips

signal order_placed(drink_type: String)
signal order_completed(drink_type: String, satisfaction: float)
signal tip_given(amount: float)

# Customer identification
@export var name: String = ""
@export var customer_type: CustomerType = CustomerType.REGULAR

# Customer types
enum CustomerType {
	REGULAR,    # Normal customer
	CRITIC,     # Very demanding, high expectations
	TOURIST,    # Unfamiliar with coffee, lower expectations
	BUSINESS,   # In a hurry, values speed
	STUDENT,    # Price conscious, lower expectations
	COFFEE_SNOB # Very particular about quality
}

# Order preferences
@export var preferred_drink: String = "espresso"
@export var drink_preferences: Array[String] = []
@export var price_sensitivity: float = 0.5  # 0.0 = price doesn't matter, 1.0 = very price sensitive

# Behavior traits
@export var patience: float = 0.7  # 0.0 = no patience, 1.0 = very patient
@export var tip_likelihood: float = 0.5  # 0.0 = never tips, 1.0 = always tips
@export var tip_amount: float = 0.15  # Percentage of order value
@export var quality_expectation: float = 0.7  # Expected quality level
@export var social_butterfly: float = 0.3  # Likes to chat with staff

# Current state
@export var current_mood: CustomerMood = CustomerMood.NEUTRAL
@export var wait_time: float = 0.0  # Minutes waiting
@export var order_placed_time: float = 0.0
@export var satisfaction: float = 0.5

# Visit history
@export var visit_count: int = 0
@export var total_spent: float = 0.0
@export var average_satisfaction: float = 0.5
@export var last_visit_day: int = 0

# Customer moods
enum CustomerMood {
	HAPPY,      # Good experience, will return
	NEUTRAL,    # Standard experience
	ANNOYED,    # Slightly unhappy, may not return
	ANGRY,      # Bad experience, unlikely to return
	ECSTATIC    # Amazing experience, will definitely return
}

func _init():
	_initialize_defaults()

func _initialize_defaults():
	"""Initialize default values for a new customer"""
	drink_preferences = ["espresso", "latte", "cappuccino", "americano"]
	current_mood = CustomerMood.NEUTRAL
	satisfaction = 0.5

func place_order(drink_type: String):
	"""Customer places an order"""
	preferred_drink = drink_type
	order_placed_time = Time.get_time_dict_from_system()["minute"]  # Simplified timing
	order_placed.emit(drink_type)
	print(name, " ordered ", drink_type)

func complete_order(drink_quality: float, service_quality: float, ambiance: float, wait_time: float):
	"""Customer receives their order and evaluates experience"""
	_update_satisfaction(drink_quality, service_quality, ambiance, wait_time)
	_update_mood_from_satisfaction()
	
	order_completed.emit(preferred_drink, satisfaction)
	
	# Calculate tip
	var tip_amount = _calculate_tip(drink_quality, service_quality)
	if tip_amount > 0:
		tip_given.emit(tip_amount)
	
	# Update visit history
	visit_count += 1
	last_visit_day = GameManager.get_current_day()
	
	print(name, " completed order (Satisfaction: ", satisfaction, ", Tip: $", tip_amount, ")")

func _update_satisfaction(drink_quality: float, service_quality: float, ambiance: float, wait_time: float):
	"""Update customer satisfaction based on experience"""
	var base_satisfaction = 0.5
	
	# Drink quality (most important factor)
	var quality_factor = drink_quality * 0.4
	if drink_quality < quality_expectation:
		quality_factor *= 0.7  # Penalty for below expectations
	elif drink_quality > quality_expectation * 1.2:
		quality_factor *= 1.2  # Bonus for exceeding expectations
	
	base_satisfaction += quality_factor
	
	# Service quality
	var service_factor = service_quality * 0.25
	base_satisfaction += service_factor
	
	# Ambiance
	var ambiance_factor = ambiance * 0.15
	base_satisfaction += ambiance_factor
	
	# Wait time (affects satisfaction negatively)
	var wait_penalty = wait_time * 0.1 * (1.0 - patience)
	base_satisfaction -= wait_penalty
	
	# Customer type modifiers
	base_satisfaction = _apply_customer_type_modifiers(base_satisfaction, drink_quality, service_quality, wait_time)
	
	# Update running average
	var total_satisfaction_points = average_satisfaction * (visit_count - 1) + base_satisfaction
	satisfaction = total_satisfaction_points / visit_count
	average_satisfaction = satisfaction

func _apply_customer_type_modifiers(base_satisfaction: float, drink_quality: float, service_quality: float, wait_time: float) -> float:
	"""Apply modifiers based on customer type"""
	var modified_satisfaction = base_satisfaction
	
	match customer_type:
		CustomerType.CRITIC:
			# Critics are harder to please
			if drink_quality < 0.9:
				modified_satisfaction *= 0.8
			if service_quality < 0.9:
				modified_satisfaction *= 0.9
			if wait_time > 5.0:  # 5 minutes
				modified_satisfaction *= 0.7
		
		CustomerType.TOURIST:
			# Tourists are more forgiving but have different expectations
			modified_satisfaction += 0.1  # Bonus for being friendly
			if drink_quality < 0.6:
				modified_satisfaction *= 0.8
		
		CustomerType.BUSINESS:
			# Business customers value speed
			if wait_time > 3.0:  # 3 minutes
				modified_satisfaction *= 0.6
			else:
				modified_satisfaction += 0.1
		
		CustomerType.STUDENT:
			# Students are price conscious but forgiving
			modified_satisfaction += 0.05  # Small bonus for being understanding
		
		CustomerType.COFFEE_SNOB:
			# Coffee snobs are very particular about quality
			if drink_quality < 0.8:
				modified_satisfaction *= 0.5
			elif drink_quality > 0.9:
				modified_satisfaction *= 1.2
	
	return modified_satisfaction

func _update_mood_from_satisfaction():
	"""Update customer mood based on satisfaction"""
	if satisfaction >= 0.9:
		current_mood = CustomerMood.ECSTATIC
	elif satisfaction >= 0.7:
		current_mood = CustomerMood.HAPPY
	elif satisfaction >= 0.4:
		current_mood = CustomerMood.NEUTRAL
	elif satisfaction >= 0.2:
		current_mood = CustomerMood.ANNOYED
	else:
		current_mood = CustomerMood.ANGRY

func _calculate_tip(drink_quality: float, service_quality: float) -> float:
	"""Calculate tip amount"""
	if randf() > tip_likelihood:
		return 0.0
	
	var base_tip = tip_amount
	
	# Quality bonuses
	if drink_quality > 0.8:
		base_tip += 0.05
	if service_quality > 0.8:
		base_tip += 0.05
	
	# Customer type modifiers
	match customer_type:
		CustomerType.BUSINESS:
			base_tip *= 1.5  # Business customers tip more
		CustomerType.STUDENT:
			base_tip *= 0.5  # Students tip less
		CustomerType.CRITIC:
			if satisfaction > 0.8:
				base_tip *= 2.0  # Critics tip well when pleased
			else:
				base_tip *= 0.3  # Critics tip poorly when displeased
	
	return base_tip

func get_customer_type_name() -> String:
	"""Get customer type as string"""
	match customer_type:
		CustomerType.REGULAR: return "Regular"
		CustomerType.CRITIC: return "Critic"
		CustomerType.TOURIST: return "Tourist"
		CustomerType.BUSINESS: return "Business"
		CustomerType.STUDENT: return "Student"
		CustomerType.COFFEE_SNOB: return "Coffee Snob"
		_: return "Unknown"

func get_mood_name() -> String:
	"""Get current mood as string"""
	match current_mood:
		CustomerMood.HAPPY: return "Happy"
		CustomerMood.NEUTRAL: return "Neutral"
		CustomerMood.ANNOYED: return "Annoyed"
		CustomerMood.ANGRY: return "Angry"
		CustomerMood.ECSTATIC: return "Ecstatic"
		_: return "Unknown"

func is_return_customer() -> bool:
	"""Check if this is a returning customer"""
	return visit_count > 1

func get_loyalty_level() -> String:
	"""Get customer loyalty level"""
	if visit_count >= 10:
		return "Loyal"
	elif visit_count >= 5:
		return "Regular"
	elif visit_count >= 2:
		return "Occasional"
	else:
		return "New"

func will_return() -> bool:
	"""Predict if customer will return based on satisfaction and mood"""
	if current_mood == CustomerMood.ANGRY:
		return false
	elif current_mood == CustomerMood.ANNOYED and satisfaction < 0.3:
		return false
	elif current_mood in [CustomerMood.HAPPY, CustomerMood.ECSTATIC]:
		return true
	else:
		return satisfaction > 0.5

func get_spending_pattern() -> String:
	"""Get customer spending pattern"""
	if total_spent / max(visit_count, 1) > 8.0:
		return "High Spender"
	elif total_spent / max(visit_count, 1) > 5.0:
		return "Average Spender"
	else:
		return "Budget Conscious"

# Getters for external systems
func get_customer_name() -> String:
	return name

func get_preferred_drink() -> String:
	return preferred_drink

func get_patience() -> float:
	return patience

func get_satisfaction() -> float:
	return satisfaction

func get_current_mood() -> CustomerMood:
	return current_mood

func get_visit_count() -> int:
	return visit_count

func get_total_spent() -> float:
	return total_spent
