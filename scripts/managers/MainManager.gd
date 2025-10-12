class_name MainManager
extends Node2D

# MainManager - Main game controller and scene manager
# Handles: Scene transitions, day selection, game flow

signal game_started
signal scene_changed(scene_name: String)
signal day_completed

# UI references
@onready var main_menu: Control = $UI/MainMenu
@onready var day_selection_ui: Control = $UI/DaySelectionUI
@onready var status_panel: Panel = $UI/StatusPanel
@onready var status_label: Label = $UI/StatusPanel/StatusLabel
@onready var farmer_button: Button = $UI/DaySelectionUI/DayPanel/SiblingButtons/FarmerButton
@onready var roaster_button: Button = $UI/DaySelectionUI/DayPanel/SiblingButtons/RoasterButton
@onready var cafe_button: Button = $UI/DaySelectionUI/DayPanel/SiblingButtons/CafeButton

# Scene references
@onready var scene_container: Node = $SceneContainer
@onready var farm_scene: Node2D = $SceneContainer/FarmScene
@onready var roastery_scene: Node2D = $SceneContainer/RoasteryScene

# Game state
var current_scene: String = ""
var is_game_active: bool = false
var current_day: int = 1
var current_season: String = "Spring"

func _ready():
	_setup_ui_connections()
	_connect_to_managers()
	_show_main_menu()

func _setup_ui_connections():
	"""Connect UI buttons to functions"""
	# Main menu buttons
	var new_game_button = $UI/MainMenu/TitlePanel/ButtonContainer/NewGameButton
	var load_game_button = $UI/MainMenu/TitlePanel/ButtonContainer/LoadGameButton
	var quit_button = $UI/MainMenu/TitlePanel/ButtonContainer/QuitButton
	
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Day selection buttons
	farmer_button.pressed.connect(_on_farmer_selected)
	roaster_button.pressed.connect(_on_roaster_selected)
	cafe_button.pressed.connect(_on_cafe_selected)

func _connect_to_managers():
	"""Connect to global managers"""
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.sibling_selected.connect(_on_sibling_selected)

func _show_main_menu():
	"""Show the main menu"""
	main_menu.visible = true
	day_selection_ui.visible = false
	status_panel.visible = false
	_hide_all_scenes()

func _show_day_selection():
	"""Show the day selection UI"""
	main_menu.visible = false
	day_selection_ui.visible = true
	status_panel.visible = true
	_hide_all_scenes()
	
	_update_status_display()

func _hide_all_scenes():
	"""Hide all business scenes"""
	farm_scene.visible = false
	roastery_scene.visible = false
	# Add café scene when implemented
	current_scene = ""

func _update_status_display():
	"""Update the status display"""
	var day = GameManager.get_current_day()
	var season = _get_season_name(GameManager.get_current_season())
	var phase = _get_phase_name(GameManager.get_current_phase())
	
	status_label.text = "Day " + str(day) + " - " + season + " (" + phase + ")"

func _on_new_game_pressed():
	"""Start a new game"""
	GameManager.start_new_day()
	is_game_active = true
	_show_day_selection()
	game_started.emit()
	print("New game started")

func _on_load_game_pressed():
	"""Load an existing game"""
	if GameManager.load_game():
		is_game_active = true
		_show_day_selection()
		print("Game loaded")
	else:
		print("Failed to load game")

func _on_quit_pressed():
	"""Quit the game"""
	get_tree().quit()

func _on_farmer_selected():
	"""Player selected the farmer sibling"""
	GameManager.select_sibling("farmer")
	_switch_to_scene("farm")

func _on_roaster_selected():
	"""Player selected the roaster sibling"""
	GameManager.select_sibling("roaster")
	_switch_to_scene("roastery")

func _on_cafe_selected():
	"""Player selected the café sibling"""
	GameManager.select_sibling("cafe_owner")
	_switch_to_scene("cafe")

func _switch_to_scene(scene_name: String):
	"""Switch to a specific business scene"""
	_hide_all_scenes()
	
	match scene_name:
		"farm":
			farm_scene.visible = true
			current_scene = "farm"
		"roastery":
			roastery_scene.visible = true
			current_scene = "roastery"
		"cafe":
			# Add café scene when implemented
			current_scene = "cafe"
		_:
			print("Unknown scene: ", scene_name)
			return
	
	day_selection_ui.visible = false
	scene_changed.emit(scene_name)
	print("Switched to ", scene_name, " scene")

func _on_day_changed(day: int, season: String):
	"""Handle day changes"""
	current_day = day
	current_season = season
	_update_status_display()
	
	# Show day selection for next day
	_show_day_selection()

func _on_sibling_selected(sibling: String):
	"""Handle sibling selection"""
	print("Selected sibling: ", sibling)

func _get_season_name(season: GameManager.Season) -> String:
	"""Convert season enum to string"""
	match season:
		GameManager.Season.SPRING: return "Spring"
		GameManager.Season.SUMMER: return "Summer"
		GameManager.Season.AUTUMN: return "Autumn"
		GameManager.Season.WINTER: return "Winter"
		_: return "Unknown"

func _get_phase_name(phase: GameManager.GamePhase) -> String:
	"""Convert phase enum to string"""
	match phase:
		GameManager.GamePhase.MORNING_SELECTION: return "Morning Selection"
		GameManager.GamePhase.DAY_PLAY: return "Day Play"
		GameManager.GamePhase.EVENING_REVIEW: return "Evening Review"
		GameManager.GamePhase.NIGHT_REST: return "Night Rest"
		_: return "Unknown"

# Public functions for external access
func get_current_scene() -> String:
	return current_scene

func is_game_started() -> bool:
	return is_game_active

func end_current_day():
	"""End the current day and advance to next day"""
	GameManager.end_day_phase()
	day_completed.emit()
