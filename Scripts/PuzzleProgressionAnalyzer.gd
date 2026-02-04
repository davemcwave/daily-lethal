extends Node
class_name PuzzleProgressionAnalyzer

## Analyzes puzzle order based on card prerequisites
## Outputs suggested puzzle progression graph

func _ready() -> void:
	analyze_progression()

const CARD_PREREQUISITES = {
	# STARTERS - no prereqs
	"Echo": [],
	"Rage": [],
	"Slash": [],
	"Surge": [],

	# TIER 1
	"Bargain": ["Surge"],
	"Cleave": ["Slash"],
	"Fang": ["Slash"],
	"Flurry": ["Slash"],
	"Lunge": ["Slash", "Surge"],
	"Pound": ["Slash"],
	"Rebound": ["Echo"],
	"Scrap": ["Surge"],
	"Sharpen": ["Rage"],
	"Spark": ["Rage", "Slash"],
	"Spear": ["Slash"],
	"Snipe": ["Slash"],
	"Target": ["Rage"],
	"Thunderbolt": ["Slash", "Surge"],
	"Wound": ["Rage"],

	# TIER 2
	"Armory": ["Spear", "Pound", "Cleave"],
	"Berserk": ["Fang", "Wound"],
	"Gift": ["Bargain"],
	"Empty Fist": ["Snipe"],
	"Haunt": ["Wound"],
	"Ignite": ["Spark"],
	"Inspiration": ["Fang", "Surge"],
	"Martyr": ["Bargain", "Fang"],
	"Mend": ["Fang"],
	"Revive": ["Rebound"],
	"Shovel": ["Snipe"],
	"Trace": ["Rebound"],
	"Venom": ["Wound"],

	# TIER 3
	"Burst": ["Shovel"],
	"Capacitor": ["Bargain", "Venom"],
	"Cauterize": ["Mend"],
	"Cleanse": ["Martyr"], # or Venom - using first option
	"Drain": ["Mend"],
	"Exchange": ["Mend", "Surge"],
	"Frenzy": ["Inspiration", "Target"],
	"Heartbeat": ["Mend", "Thunderbolt"],
	"Potion": ["Mend"],
	"Reverberate": ["Revive"],
	"Shield": ["Mend"],
	"Tribute": ["Gift", "Haunt"],
	"Waste": ["Haunt"],

	# TIER 4
	"Overload": ["Burst", "Surge"],

	# TIER 5
	"Cooperate": ["Overload"],
	"Cooperation": ["Overload"], # Alternative spelling
	"Focus": [] # Assuming no prereqs
}

func analyze_progression(json_path: String = "res://puzzle_cards.json") -> void:
	print("\n========== PUZZLE PROGRESSION ANALYZER ==========\n")

	var puzzle_data = load_puzzle_json(json_path)
	if puzzle_data.is_empty():
		print("ERROR: No puzzle data loaded")
		return

	var progression = calculate_progression(puzzle_data)
	print_progression(progression)

	print("\n========== END ANALYZER ==========\n")

func load_puzzle_json(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return {}

	return json.data

func calculate_progression(puzzle_data: Dictionary) -> Array[Array]:
	var progression: Array[Array] = []
	# Start with knowledge of starter cards
	var learned_cards: Array[String] = ["Echo", "Rage", "Slash", "Surge"]
	var remaining_puzzles = puzzle_data.duplicate()

	while not remaining_puzzles.is_empty():
		var available_puzzles = find_available_puzzles(remaining_puzzles, learned_cards)

		if available_puzzles.is_empty():
			# No more puzzles available - show what's blocking
			print("\nWARNING: %d puzzles remain but cannot be unlocked:" % remaining_puzzles.size())
			for puzzle_name in remaining_puzzles.keys():
				var cards = remaining_puzzles[puzzle_name]
				var blocking_cards = get_blocking_cards(cards, learned_cards)
				if not blocking_cards.is_empty():
					print("  %s - blocked by: %s" % [puzzle_name.get_basename(), ", ".join(blocking_cards)])
			break

		# Add this tier to progression
		progression.append(available_puzzles)

		# Mark cards as learned from these puzzles
		for puzzle_name in available_puzzles:
			var cards = remaining_puzzles[puzzle_name]
			for card in cards:
				if card not in learned_cards:
					learned_cards.append(card)
			remaining_puzzles.erase(puzzle_name)

	return progression

func find_available_puzzles(puzzles: Dictionary, learned_cards: Array[String]) -> Array[String]:
	var available: Array[String] = []

	for puzzle_name in puzzles.keys():
		var cards = puzzles[puzzle_name]
		if can_play_puzzle(cards, learned_cards):
			available.append(puzzle_name)

	available.sort()
	return available

func can_play_puzzle(cards: Array, learned_cards: Array[String]) -> bool:
	for card in cards:
		if not can_learn_card(card, learned_cards):
			return false
	return true

func can_learn_card(card: String, learned_cards: Array[String]) -> bool:
	if card in learned_cards:
		return true

	if not CARD_PREREQUISITES.has(card):
		# Unknown card - assume it's learnable
		return true

	var prereqs = CARD_PREREQUISITES[card]
	for prereq in prereqs:
		if prereq not in learned_cards:
			return false

	return true

func get_blocking_cards(cards: Array, learned_cards: Array[String]) -> Array[String]:
	var blocking: Array[String] = []

	for card in cards:
		if card not in learned_cards and CARD_PREREQUISITES.has(card):
			var prereqs = CARD_PREREQUISITES[card]
			for prereq in prereqs:
				if prereq not in learned_cards and prereq not in blocking:
					blocking.append(prereq)

	return blocking

func print_progression(progression: Array[Array]) -> void:
	print("Suggested Puzzle Progression (%d tiers):\n" % progression.size())

	for i in range(progression.size()):
		var tier_puzzles = progression[i]
		print("═══ TIER %d ═══ (%d puzzles)" % [i + 1, tier_puzzles.size()])

		for puzzle_name in tier_puzzles:
			print("  • %s" % puzzle_name.get_basename())

		print()
