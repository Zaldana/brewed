class_name StartScreen
extends Control

# StartScreen - Main menu and game launcher
# Handles: Menu navigation, game initialization, scene transitions

signal start_new_game
signal load_game
signal open_settings
signal quit_game

# UI references
@onready var new_game_button: Button = $VBoxContainer/ButtonContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/ButtonContainer/LoadGameButton
@onready var settings_button: Button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton

# Audio references (for future implementation)
var button_sound: AudioStreamPlayer
var background_music: AudioStreamPlayer

func _ready():
	_setup_ui_connections()
	_setup_visual_effects()
	_animate_entrance()

func _setup_ui_connections():
	"""Connect UI buttons to their respective functions"""
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect keyboard shortcuts
	_setup_keyboard_shortcuts()

func _setup_keyboard_shortcuts():
	"""Setup keyboard navigation for the menu"""
	# Make buttons focusable for keyboard navigation
	new_game_button.focus_mode = Control.FOCUS_ALL
	load_game_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	quit_button.focus_mode = Control.FOCUS_ALL
	
	# Set initial focus
	new_game_button.grab_focus()

func _setup_visual_effects():
	"""Setup visual effects and animations"""
	# Add hover effects to buttons
	_add_button_hover_effects()
	
	# Setup background effects (if needed)
	_setup_background_effects()

func _add_button_hover_effects():
	"""Add hover effects to menu buttons"""
	var buttons = [new_game_button, load_game_button, settings_button, quit_button]
	
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _setup_background_effects():
	"""Setup background visual effects"""
	# This could include particle effects, animated backgrounds, etc.
	# For now, we'll keep it simple
	pass

func _animate_entrance():
	"""Animate the entrance of the start screen"""
	# Start with elements invisible
	modulate = Color.TRANSPARENT
	
	# Animate fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
	# Add slight scale animation for title
	var title_container = $VBoxContainer/TitleContainer
	title_container.scale = Vector2(0.8, 0.8)
	var title_tween = create_tween()
	title_tween.tween_property(title_container, "scale", Vector2.ONE, 0.6)

func _on_button_hover(button: Button):
	"""Handle button hover effects"""
	# Add hover sound (when audio is implemented)
	# _play_button_sound()
	
	# Add visual feedback
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unhover(button: Button):
	"""Handle button unhover effects"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)
	tween.tween_property(button, "modulate", Color.WHITE, 0.1)

func _on_new_game_pressed():
	"""Handle new game button press"""
	_play_button_click_effect()
	start_new_game.emit()
	print("Starting new game...")

func _on_load_game_pressed():
	"""Handle load game button press"""
	_play_button_click_effect()
	load_game.emit()
	print("Loading game...")

func _on_settings_pressed():
	"""Handle settings button press"""
	_play_button_click_effect()
	open_settings.emit()
	print("Opening settings...")

func _on_quit_pressed():
	"""Handle quit button press"""
	_play_button_click_effect()
	quit_game.emit()
	print("Quitting game...")

func _play_button_click_effect():
	"""Play button click effect"""
	# Add click sound (when audio is implemented)
	# _play_button_sound()
	
	# Add visual feedback
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.9, 0.9, 0.9, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.05)

func _input(event: InputEvent):
	"""Handle input events"""
	if event.is_action_pressed("ui_cancel"):
		# ESC key to quit
		_on_quit_pressed()
	elif event.is_action_pressed("ui_accept"):
		# Enter key to activate focused button
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is Button:
			focused.emit_signal("pressed")

func transition_to_game():
	"""Transition to the main game scene"""
	# Animate exit
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	
	# Wait for animation to complete, then change scene
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")

func show_load_error(message: String):
	"""Show an error message for failed game loading"""
	# This could show a popup or notification
	print("Load error: ", message)
	# TODO: Implement error popup UI

func update_version_info(version: String):
	"""Update the version label"""
	var version_label = $VersionLabel
	if version_label:
		version_label.text = "v" + version

# Public functions for external access
func set_load_button_enabled(enabled: bool):
	"""Enable or disable the load game button"""
	load_game_button.disabled = not enabled

func get_focused_button() -> Button:
	"""Get the currently focused button"""
	var focused = get_viewport().gui_get_focus_owner()
	if focused and focused is Button:
		return focused
	return null
