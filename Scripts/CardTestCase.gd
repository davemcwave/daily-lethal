extends Resource
class_name CardTestCase

@export var test_name: String = "Unnamed Test"
@export var cards_in_hand: Array[PackedScene] = []
@export var cards_to_play: Array[PackedScene] = []
@export var starting_energy: int = 10
@export var pause_after_test: bool = false  # Wait for button press to continue

# Expected outcomes (-1 means don't check)
@export_group("Expected Outcomes")
@export var expected_hand_count: int = -1
@export var expected_discard_count: int = -1
@export var expected_buff_count: int = -1
@export var expected_enemy_health: int = -1
@export var expected_energy: int = -1
