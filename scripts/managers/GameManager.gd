extends Node

# GameManager - Core game state and turn-based day system
# Handles: Day progression, save/load, calendar, global events

signal day_changed(day: int, season: String)
signal sibling_selected(sibling: String)
signal game_saved
signal game_loaded

enum GamePhase {
	MORNING_SELECTION,
	DAY_PLAY
}

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER
}

var current_day: int = 1
var current_season: Season = Season.SPRING
var current_phase: GamePhase = GamePhase.MORNING_SELECTION
var selected_sibling: String = ""
var initial_character: String = ""  # The character selected at game start
var game_started: bool = false
var character_selected: bool = false  # Whether initial character has been chosen

# Calendar system
var days_per_season: int = 28
var total_days_played: int = 0

# Save file path
const SAVE_FILE = "user://brewed_together_save.dat"

func _ready():
	# Connect to other managers
	EventManager.game_event.connect(_on_game_event)
	
	# Initialize game state
	_initialize_game()

func _initialize_game():
	"""Initialize the game state on first run"""
	if not game_started:
		game_started = true
		_change_phase(GamePhase.MORNING_SELECTION)
		print("Game initialized - Day 1, Spring")

func set_initial_character(character: String):
	"""Set the initial character selected at game start"""
	initial_character = character
	character_selected = true
	print("Initial character set to: ", character)

func start_new_day():
	"""Begin a new day cycle"""
	current_day += 1
	total_days_played += 1
	
	# Check for season change
	var season_day = (current_day - 1) % days_per_season
	if season_day == 0 and current_day > 1:
		_advance_season()
	
	# Reset phase to morning selection
	_change_phase(GamePhase.MORNING_SELECTION)
	selected_sibling = ""
	
	# Emit signals
	day_changed.emit(current_day, _season_to_string(current_season))
	print("New day: ", current_day, " (", _season_to_string(current_season), ")")

func select_sibling(sibling: String):
	"""Player selects which sibling to play for the day"""
	if current_phase != GamePhase.MORNING_SELECTION:
		print("Warning: Can only select sibling during morning phase")
		return
	
	selected_sibling = sibling
	_change_phase(GamePhase.DAY_PLAY)
	sibling_selected.emit(sibling)
	print("Selected sibling: ", sibling)

func end_current_day():
	"""End the current day and advance to next day"""
	if current_phase == GamePhase.DAY_PLAY:
		_process_end_of_day()
		start_new_day()
	else:
		print("Can only end day during DAY_PLAY phase")

func _change_phase(new_phase: GamePhase):
	"""Internal function to change game phase"""
	current_phase = new_phase
	print("Phase changed to: ", _phase_to_string(new_phase))
	
	# Handle phase-specific logic
	match new_phase:
		GamePhase.MORNING_SELECTION:
			print("Ready to select sibling for the day")
		GamePhase.DAY_PLAY:
			print("Day started - playing as ", selected_sibling)

func _process_end_of_day():
	"""Process end of day operations for all businesses"""
	print("Processing end of day operations...")
	# Update employees for all businesses
	# Process autonomous operations for non-selected siblings
	# Apply any end-of-day effects

func _advance_season():
	"""Advance to the next season"""
	var seasons = [Season.SPRING, Season.SUMMER, Season.AUTUMN, Season.WINTER]
	var current_index = seasons.find(current_season)
	current_season = seasons[(current_index + 1) % seasons.size()]
	print("Season advanced to: ", _season_to_string(current_season))

func save_game():
	"""Save the current game state"""
	var save_data = {
		"current_day": current_day,
		"current_season": current_season,
	"current_phase": current_phase,
	"selected_sibling": selected_sibling,
	"initial_character": initial_character,
	"character_selected": character_selected,
	"total_days_played": total_days_played,
	"game_started": game_started
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		game_saved.emit()
		print("Game saved successfully")
		return true
	else:
		print("Error: Could not save game")
		return false

func load_game():
	"""Load the game state from save file"""
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found")
		return false
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			current_day = save_data.get("current_day", 1)
			current_season = save_data.get("current_season", Season.SPRING)
			current_phase = save_data.get("current_phase", GamePhase.MORNING_SELECTION)
			selected_sibling = save_data.get("selected_sibling", "")
			initial_character = save_data.get("initial_character", "")
			character_selected = save_data.get("character_selected", false)
			total_days_played = save_data.get("total_days_played", 0)
			game_started = save_data.get("game_started", true)
			
			game_loaded.emit()
			print("Game loaded successfully - Day ", current_day)
			return true
	
	print("Error: Could not load game")
	return false

func _on_game_event(event_type: String, event_data: Dictionary):
	"""Handle global game events"""
	print("Game event received: ", event_type, " - ", event_data)
	# This will be expanded as we add more event types

func _season_to_string(season: Season) -> String:
	match season:
		Season.SPRING: return "Spring"
		Season.SUMMER: return "Summer"
		Season.AUTUMN: return "Autumn"
		Season.WINTER: return "Winter"
		_: return "Unknown"

func _phase_to_string(phase: GamePhase) -> String:
	match phase:
		GamePhase.MORNING_SELECTION: return "Morning Selection"
		GamePhase.DAY_PLAY: return "Day Play"
		_: return "Unknown"

# Getters for other systems
func get_current_day() -> int:
	return current_day

func get_current_season() -> Season:
	return current_season

func get_current_phase() -> GamePhase:
	return current_phase

func get_selected_sibling() -> String:
	return selected_sibling

func is_morning_selection() -> bool:
	return current_phase == GamePhase.MORNING_SELECTION

func is_day_play() -> bool:
	return current_phase == GamePhase.DAY_PLAY

func request_end_day():
	"""Public function for UI to request ending the current day"""
	end_current_day()

func get_initial_character() -> String:
	return initial_character

func is_character_selected() -> bool:
	return character_selected
