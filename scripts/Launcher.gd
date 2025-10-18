class_name Launcher
extends Control

# Launcher - Handles the initial game launch and start screen
# Manages: Start screen display, game initialization, scene transitions

@onready var start_screen: StartScreen = $StartScreen as StartScreen
@onready var character_selection_screen: Control = $CharacterSelectionScreen

func _ready():
	_setup_start_screen_connections()
	_initialize_game()

func _setup_start_screen_connections():
	"""Connect start screen signals to launcher functions"""
	start_screen.start_new_game.connect(_on_start_new_game)
	start_screen.load_game.connect(_on_load_game)
	start_screen.open_settings.connect(_on_open_settings)
	start_screen.quit_game.connect(_on_quit_game)
	
	# Connect character selection screen signals
	character_selection_screen.character_selected.connect(_on_character_selected)
	character_selection_screen.back_to_menu.connect(_on_back_to_menu)

func _initialize_game():
	"""Initialize the game systems"""
	# Ensure all managers are loaded
	print("Initializing game systems...")
	
	# Check if save file exists to enable/disable load button
	var save_exists = FileAccess.file_exists("user://brewed_together_save.dat")
	start_screen.set_load_button_enabled(save_exists)
	
	print("Game initialization complete")

func _on_start_new_game():
	"""Handle new game start"""
	print("Starting new game...")
	
	# Show character selection screen
	_show_character_selection()

func _on_load_game():
	"""Handle game loading"""
	print("Loading game...")
	
	if GameManager.load_game():
		print("Game loaded successfully")
		_transition_to_game()
	else:
		print("Failed to load game")
		start_screen.show_load_error("Failed to load game. Save file may be corrupted.")

func _on_open_settings():
	"""Handle settings menu"""
	print("Opening settings...")
	# TODO: Implement settings screen
	# For now, just show a placeholder message
	print("Settings not yet implemented")

func _on_quit_game():
	"""Handle game quit"""
	print("Quitting game...")
	get_tree().quit()

func _show_character_selection():
	"""Show the character selection screen"""
	start_screen.visible = false
	character_selection_screen.visible = true

func _on_character_selected(character: String):
	"""Handle character selection"""
	print("Character selected: ", character)
	
	# Set the initial character in GameManager
	GameManager.set_initial_character(character)
	
	# Initialize game state and start first day
	GameManager.start_new_day()
	
	# Transition to main game scene
	_transition_to_game()

func _on_back_to_menu():
	"""Handle back to menu from character selection"""
	character_selection_screen.visible = false
	start_screen.visible = true

func _transition_to_game():
	"""Transition from launcher to main game scene"""
	print("Transitioning to main game...")
	
	# Fade out the current screen
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	
	# Wait for fade to complete, then change scene
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")
