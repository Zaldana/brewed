class_name CharacterSelectionScreen
extends Control

# CharacterSelectionScreen - Initial character selection for new game
# Handles: Character selection, character info display, transition to gameplay

signal character_selected(character: String)
signal back_to_menu

# UI references
@onready var alex_button: Button = $VBoxContainer/CharacterContainer/AlexCard/AlexButton
@onready var jordan_button: Button = $VBoxContainer/CharacterContainer/JordanCard/JordanButton
@onready var casey_button: Button = $VBoxContainer/CharacterContainer/CaseyCard/CaseyButton
@onready var back_button: Button = $VBoxContainer/BottomContainer/ButtonContainer/BackButton

# Character cards for hover effects
@onready var alex_card: Panel = $VBoxContainer/CharacterContainer/AlexCard
@onready var jordan_card: Panel = $VBoxContainer/CharacterContainer/JordanCard
@onready var casey_card: Panel = $VBoxContainer/CharacterContainer/CaseyCard

# Currently selected character (for confirmation)
var selected_character: String = ""

func _ready():
	_setup_ui_connections()
	_setup_hover_effects()

func _setup_ui_connections():
	"""Connect UI buttons to functions"""
	alex_button.pressed.connect(_on_alex_selected)
	jordan_button.pressed.connect(_on_jordan_selected)
	casey_button.pressed.connect(_on_casey_selected)
	back_button.pressed.connect(_on_back_pressed)

func _setup_hover_effects():
	"""Setup hover effects for character cards"""
	alex_button.mouse_entered.connect(_on_alex_hover)
	alex_button.mouse_exited.connect(_on_alex_unhover)
	
	jordan_button.mouse_entered.connect(_on_jordan_hover)
	jordan_button.mouse_exited.connect(_on_jordan_unhover)
	
	casey_button.mouse_entered.connect(_on_casey_hover)
	casey_button.mouse_exited.connect(_on_casey_unhover)

func _on_alex_selected():
	"""Player selected Alex (The Farmer)"""
	selected_character = "farmer"
	_animate_selection(alex_card)
	_confirm_selection("Alex", "The Farmer", "Starting with farming expertise!")

func _on_jordan_selected():
	"""Player selected Jordan (The Roaster)"""
	selected_character = "roaster"
	_animate_selection(jordan_card)
	_confirm_selection("Jordan", "The Roaster", "Starting with roasting mastery!")

func _on_casey_selected():
	"""Player selected Casey (The Café Owner)"""
	selected_character = "cafe_owner"
	_animate_selection(casey_card)
	_confirm_selection("Casey", "The Café Owner", "Starting with customer service excellence!")

func _on_back_pressed():
	"""Return to main menu"""
	back_to_menu.emit()

func _confirm_selection(name: String, role: String, message: String):
	"""Confirm the character selection"""
	print("Character selected: ", name, " - ", role)
	print(message)
	
	# Brief delay for visual feedback, then proceed
	await get_tree().create_timer(0.5).timeout
	character_selected.emit(selected_character)

func _animate_selection(card: Panel):
	"""Animate the selected character card"""
	var tween = create_tween()
	tween.parallel().tween_property(card, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(card, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)

func _on_alex_hover():
	"""Alex card hover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(alex_card, "scale", Vector2(1.02, 1.02), 0.1)
	tween.parallel().tween_property(alex_card, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.1)

func _on_alex_unhover():
	"""Alex card unhover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(alex_card, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(alex_card, "modulate", Color.WHITE, 0.1)

func _on_jordan_hover():
	"""Jordan card hover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(jordan_card, "scale", Vector2(1.02, 1.02), 0.1)
	tween.parallel().tween_property(jordan_card, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.1)

func _on_jordan_unhover():
	"""Jordan card unhover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(jordan_card, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(jordan_card, "modulate", Color.WHITE, 0.1)

func _on_casey_hover():
	"""Casey card hover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(casey_card, "scale", Vector2(1.02, 1.02), 0.1)
	tween.parallel().tween_property(casey_card, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.1)

func _on_casey_unhover():
	"""Casey card unhover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(casey_card, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(casey_card, "modulate", Color.WHITE, 0.1)

func get_character_info(character: String) -> Dictionary:
	"""Get detailed information about a character"""
	match character:
		"farmer":
			return {
				"name": "Alex",
				"title": "The Farmer",
				"description": "Passionate about sustainable farming and growing the perfect coffee beans.",
				"expertise": "Crop management, weather patterns, soil quality",
				"personality": "Patient, methodical, connected to nature",
				"starting_bonus": "Better crop yields and weather resistance"
			}
		"roaster":
			return {
				"name": "Jordan",
				"title": "The Roaster",
				"description": "An artist with coffee roasting, transforming green beans into perfection.",
				"expertise": "Roasting profiles, quality control, blending",
				"personality": "Precise, creative, quality-focused",
				"starting_bonus": "Higher roast quality and better equipment efficiency"
			}
		"cafe_owner":
			return {
				"name": "Casey",
				"title": "The Café Owner",
				"description": "Creates the perfect café atmosphere where every customer feels at home.",
				"expertise": "Customer service, barista skills, ambiance",
				"personality": "Social, welcoming, service-oriented",
				"starting_bonus": "Better customer satisfaction and reputation growth"
			}
		_:
			return {}