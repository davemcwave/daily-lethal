class_name Keywords
## Game keywords that card text can mention, with the color they are highlighted in and
## the tooltip shown under the card preview. A card's preview shows a tooltip for each
## keyword in its text that none of its own effects already explains (see
## Card.show_card_preview), so every card, built-in or made in the Card Lab, explains
## the words it uses.

const PURPLE := "purple"     # moving cards around
const ORANGE := "#e67e22"    # statuses
const BLUE := "#2565ff"      # costs and energy
const GREEN := "#008c10"     # protection

## Keyword -> [color, tooltip]. Statuses use the same text as their own tooltips.
const GLOSSARY := {
	"Trash": [PURPLE, "Removed from the game for good (it doesn't go to the discard pile)."],
	"Reclaim": [PURPLE, "Move cards from the discard pile back to your hand."],
	"Discard": [PURPLE, "Move a card from your hand to the discard pile."],
	"Return": [PURPLE, "Return the next card played to hand"],
	"Repeat": [PURPLE, "Plays the next card twice"],
	"Copy": [PURPLE, "A duplicate of a card, added to your hand."],
	"Vulnerable": [ORANGE, "Whenever this target takes damage, they take an additional 1 damage."],
	"Burn": [ORANGE, "Whenever you play a card, deal 1 damage, then remove 1 Burn."],
	"Flame": [ORANGE, "Next attack card's damage is converted into Burn."],
	"Poison": [ORANGE, "Next attack card's damage is converted into Vulnerable."],
	"Critical": [ORANGE, "Your next attack deals double damage. Waits for an attack that deals damage."],
	"Sharp": [ORANGE, "Damage increased by 1. Lose 1 Sharp after every card played."],
	"Corrode": [ORANGE, "Any attack cards used against this enemy are trashed."],
	"Splinter": [ORANGE, "Your attack splits into many attacks, 1-damage each."],
	"Lifesteal": [ORANGE, "Your next attack heals you for the damage dealt."],
	"Regen": [ORANGE, "Gain 1 HP after the next card is played"],
	"Charge": [BLUE, "Next attack gains you energy instead of dealing damage"],
	"Blood": [BLUE, "The next card costs health instead of energy to play"],
	"Discount": [BLUE, "Reduces the cost of the next card played by 1"],
	"Free": [BLUE, "Next card played costs 0"],
	"Block": [GREEN, "Prevents the target from taking damage once"],
}

## [keyword, tooltip] for every keyword in the (BBCode) text, in glossary order.
## "discard pile" is a place, not the Discard action, so it doesn't count.
static func find_in(bbcode: String) -> Array:
	var plain := _strip_tags(bbcode).to_lower()
	var found: Array = []
	for keyword: String in GLOSSARY:
		var pattern := "\\b%s\\b" % keyword.to_lower()
		if keyword == "Discard":
			pattern = "\\bdiscard\\b(?! pile)"
		var regex := RegEx.create_from_string(pattern)
		if regex.search(plain) != null:
			found.append([keyword, GLOSSARY[keyword][1]])
	return found

static func color_of(keyword: String) -> String:
	return GLOSSARY.get(keyword, ["", ""])[0]

static func _strip_tags(bbcode: String) -> String:
	return RegEx.create_from_string("\\[[^\\]]*\\]").sub(bbcode, "", true)
