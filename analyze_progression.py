#!/usr/bin/env python3
import json
from pathlib import Path

CARD_PREREQUISITES = {
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
    "Cleanse": ["Martyr"],
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
    "Cooperation": ["Overload"],
    "Focus": []
}


def load_puzzle_json(json_path):
    with open(json_path, 'r') as f:
        return json.load(f)


def can_learn_card(card, learned_cards):
    if card in learned_cards:
        return True

    if card not in CARD_PREREQUISITES:
        # Unknown card - assume it's learnable
        return True

    prereqs = CARD_PREREQUISITES[card]
    for prereq in prereqs:
        if prereq not in learned_cards:
            return False

    return True


def can_play_puzzle(cards, learned_cards):
    for card in cards:
        if not can_learn_card(card, learned_cards):
            return False
    return True


def find_available_puzzles(puzzles, learned_cards):
    available = []
    for puzzle_name, cards in puzzles.items():
        if can_play_puzzle(cards, learned_cards):
            available.append(puzzle_name)
    return sorted(available)


def get_blocking_cards(cards, learned_cards):
    blocking = []
    for card in cards:
        if card not in learned_cards and card in CARD_PREREQUISITES:
            prereqs = CARD_PREREQUISITES[card]
            for prereq in prereqs:
                if prereq not in learned_cards and prereq not in blocking:
                    blocking.append(prereq)
    return blocking


def calculate_progression(puzzle_data):
    progression = []
    # Start with knowledge of starter cards
    learned_cards = ["Echo", "Rage", "Slash", "Surge"]
    remaining_puzzles = puzzle_data.copy()

    while remaining_puzzles:
        available_puzzles = find_available_puzzles(remaining_puzzles, learned_cards)

        if not available_puzzles:
            # No more puzzles available - show what's blocking
            print(f"\nWARNING: {len(remaining_puzzles)} puzzles remain but cannot be unlocked:")
            for puzzle_name, cards in remaining_puzzles.items():
                blocking_cards = get_blocking_cards(cards, learned_cards)
                if blocking_cards:
                    clean_name = puzzle_name.replace('.scn', '')
                    print(f"  {clean_name} - blocked by: {', '.join(blocking_cards)}")
            break

        # Add this tier to progression
        progression.append(available_puzzles)

        # Mark cards as learned from these puzzles
        for puzzle_name in available_puzzles:
            cards = remaining_puzzles[puzzle_name]
            for card in cards:
                if card not in learned_cards:
                    learned_cards.append(card)
            del remaining_puzzles[puzzle_name]

    return progression


def print_progression(progression):
    print(f"\nSuggested Puzzle Progression ({len(progression)} tiers):\n")

    for i, tier_puzzles in enumerate(progression):
        print(f"═══ TIER {i + 1} ═══ ({len(tier_puzzles)} puzzles)")
        for puzzle_name in tier_puzzles:
            clean_name = puzzle_name.replace('.scn', '')
            print(f"  • {clean_name}")
        print()


def generate_html_graph(progression):
    """Generate an HTML visualization of the puzzle progression"""
    total_puzzles = sum(len(tier) for tier in progression)

    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Puzzle Progression Graph</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #1e1e1e;
            color: #e0e0e0;
            padding: 20px;
            margin: 0;
        }}
        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}
        h1 {{
            text-align: center;
            color: #4ec9b0;
            margin-bottom: 10px;
        }}
        .stats {{
            text-align: center;
            color: #9cdcfe;
            margin-bottom: 30px;
            font-size: 14px;
        }}
        .tier {{
            margin-bottom: 40px;
            border-left: 4px solid #4ec9b0;
            padding-left: 20px;
        }}
        .tier-header {{
            font-size: 24px;
            font-weight: bold;
            color: #4ec9b0;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }}
        .tier-number {{
            background: #4ec9b0;
            color: #1e1e1e;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 18px;
        }}
        .puzzle-count {{
            color: #9cdcfe;
            font-size: 16px;
        }}
        .puzzles {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 12px;
            margin-top: 15px;
        }}
        .puzzle {{
            background: #2d2d2d;
            padding: 12px 16px;
            border-radius: 6px;
            border-left: 3px solid #569cd6;
            transition: all 0.2s;
            cursor: default;
        }}
        .puzzle:hover {{
            background: #363636;
            transform: translateX(5px);
            border-left-color: #4ec9b0;
        }}
        .puzzle-name {{
            font-size: 14px;
            color: #dcdcdc;
        }}
        .tier-1 .puzzle {{ border-left-color: #4ec9b0; }}
        .tier-2 .puzzle {{ border-left-color: #569cd6; }}
        .tier-3 .puzzle {{ border-left-color: #c586c0; }}
        .tier-4 .puzzle {{ border-left-color: #dcdcaa; }}
        .tier-5 .puzzle {{ border-left-color: #ce9178; }}
        .tier-6 .puzzle {{ border-left-color: #d16969; }}
        .tier-7 .puzzle {{ border-left-color: #f48771; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🎮 Puzzle Progression Graph</h1>
        <div class="stats">Total Tiers: {len(progression)} | Total Puzzles: {total_puzzles}</div>
"""

    for i, tier_puzzles in enumerate(progression):
        tier_num = i + 1
        html += f"""
        <div class="tier tier-{tier_num}">
            <div class="tier-header">
                <span class="tier-number">Tier {tier_num}</span>
                <span class="puzzle-count">{len(tier_puzzles)} puzzles</span>
            </div>
            <div class="puzzles">
"""
        for puzzle_name in tier_puzzles:
            clean_name = puzzle_name.replace('.scn', '')
            html += f'                <div class="puzzle"><div class="puzzle-name">{clean_name}</div></div>\n'

        html += """            </div>
        </div>
"""

    html += """    </div>
</body>
</html>"""

    return html


def generate_dependency_graph(puzzle_data):
    """Generate detailed dependency relationships between puzzles"""
    learned_cards = ["Echo", "Rage", "Slash", "Surge"]

    # Calculate what cards each puzzle provides
    puzzle_provides = {}
    for puzzle_name, cards in puzzle_data.items():
        new_cards = []
        for card in cards:
            if card not in learned_cards and card not in new_cards:
                new_cards.append(card)
        puzzle_provides[puzzle_name] = new_cards

    # Calculate dependencies: which puzzles must be completed before this one
    puzzle_dependencies = {}
    for puzzle_name, cards in puzzle_data.items():
        required_puzzles = set()

        for card in cards:
            if card in CARD_PREREQUISITES and CARD_PREREQUISITES[card]:
                # Find which puzzles teach the prerequisite cards
                for prereq_card in CARD_PREREQUISITES[card]:
                    if prereq_card not in learned_cards:
                        # Find puzzles that teach this prereq
                        for other_puzzle, other_cards in puzzle_data.items():
                            if prereq_card in other_cards and other_puzzle != puzzle_name:
                                required_puzzles.add(other_puzzle)
                                break

        puzzle_dependencies[puzzle_name] = list(required_puzzles)

    return puzzle_provides, puzzle_dependencies


def puzzle_name_to_image_path(puzzle_name):
    """Convert puzzle name to image path"""
    # Extract the creature name from the puzzle filename
    # e.g., "2025-04-23-EvilRobot-Puzzle.scn" -> "evil-robot"
    clean_name = puzzle_name.replace('.scn', '').replace('-Puzzle', '').replace('Puzzle', '')

    # Remove date prefix (YYYY-MM-DD-)
    import re
    clean_name = re.sub(r'^\d{4}-\d{2}-\d{2}-', '', clean_name)

    # Convert CamelCase to kebab-case and lowercase
    # e.g., "EvilRobot" -> "evil-robot"
    name_parts = re.findall(r'[A-Z](?:[a-z]+|[A-Z]*(?=[A-Z]|$))', clean_name)
    if name_parts:
        kebab_name = '-'.join(name_parts).lower()
    else:
        kebab_name = clean_name.lower()

    return f"Assets/Textures/{kebab_name}.png"


def generate_network_graph(puzzle_data, progression):
    """Generate an interactive D3.js network graph"""
    puzzle_provides, puzzle_dependencies = generate_dependency_graph(puzzle_data)

    # Assign tier to each puzzle
    puzzle_tiers = {}
    for tier_idx, tier_puzzles in enumerate(progression):
        for puzzle in tier_puzzles:
            puzzle_tiers[puzzle] = tier_idx + 1

    # Create nodes
    nodes = []
    for puzzle_name in puzzle_data.keys():
        clean_name = puzzle_name.replace('.scn', '')
        tier = puzzle_tiers.get(puzzle_name, 0)
        provides = puzzle_provides.get(puzzle_name, [])
        image_path = puzzle_name_to_image_path(puzzle_name)

        nodes.append({
            'id': puzzle_name,
            'name': clean_name,
            'tier': tier,
            'provides': provides,
            'cardCount': len(puzzle_data[puzzle_name]),
            'image': image_path
        })

    # Create edges (links)
    links = []
    for puzzle_name, dependencies in puzzle_dependencies.items():
        for dep_puzzle in dependencies:
            links.append({
                'source': dep_puzzle,
                'target': puzzle_name
            })

    # Generate HTML with D3.js
    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Puzzle Dependency Graph</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body {{
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #1e1e1e;
            color: #e0e0e0;
            overflow: hidden;
        }}

        #graph {{
            width: 100vw;
            height: 100vh;
        }}

        .controls {{
            position: fixed;
            top: 20px;
            left: 20px;
            background: rgba(30, 30, 30, 0.95);
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #4ec9b0;
            z-index: 1000;
            max-width: 300px;
        }}

        .controls h3 {{
            margin: 0 0 10px 0;
            color: #4ec9b0;
            font-size: 16px;
        }}

        .info-panel {{
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: rgba(30, 30, 30, 0.95);
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #569cd6;
            z-index: 1000;
            max-width: 400px;
            display: none;
        }}

        .info-panel.visible {{
            display: block;
        }}

        .info-panel h4 {{
            margin: 0 0 10px 0;
            color: #569cd6;
            font-size: 14px;
        }}

        .info-content {{
            font-size: 12px;
            color: #dcdcdc;
        }}

        .path-node {{
            background: #2d2d2d;
            padding: 5px 10px;
            margin: 3px 0;
            border-radius: 4px;
            border-left: 3px solid #4ec9b0;
        }}

        .path-arrow {{
            color: #569cd6;
            text-align: center;
            margin: 2px 0;
        }}

        .control-group {{
            margin-bottom: 10px;
        }}

        .control-group label {{
            display: block;
            font-size: 12px;
            color: #9cdcfe;
            margin-bottom: 5px;
        }}

        .control-group select, .control-group input {{
            width: 100%;
            padding: 5px;
            background: #2d2d2d;
            border: 1px solid #569cd6;
            color: #e0e0e0;
            border-radius: 4px;
            font-size: 12px;
        }}

        .legend {{
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #4ec9b0;
        }}

        .legend-item {{
            display: flex;
            align-items: center;
            margin-bottom: 8px;
            font-size: 11px;
        }}

        .legend-color {{
            width: 16px;
            height: 16px;
            border-radius: 3px;
            margin-right: 8px;
        }}

        .tooltip {{
            position: absolute;
            background: rgba(30, 30, 30, 0.95);
            border: 1px solid #4ec9b0;
            border-radius: 6px;
            padding: 10px;
            pointer-events: none;
            opacity: 0;
            transition: opacity 0.2s;
            z-index: 2000;
            max-width: 250px;
        }}

        .tooltip.visible {{
            opacity: 1;
        }}

        .tooltip-title {{
            font-weight: bold;
            color: #4ec9b0;
            margin-bottom: 5px;
        }}

        .tooltip-content {{
            font-size: 12px;
            color: #dcdcdc;
        }}

        .node-group {{
            cursor: pointer;
        }}

        .node-group:hover .node-bg {{
            stroke: #4ec9b0;
            stroke-width: 3px;
        }}

        .node-bg {{
            transition: all 0.2s;
        }}

        .node-image {{
            border-radius: 50%;
        }}

        .link {{
            stroke: #569cd6;
            stroke-opacity: 0.3;
            stroke-width: 1px;
        }}

        .link.highlighted {{
            stroke: #4ec9b0;
            stroke-opacity: 0.8;
            stroke-width: 2px;
        }}

        .node-label {{
            font-size: 10px;
            fill: #dcdcdc;
            pointer-events: none;
            text-anchor: middle;
        }}
    </style>
</head>
<body>
    <div class="controls">
        <h3>🎮 Puzzle Dependency Graph</h3>

        <div class="control-group">
            <label>Filter by Tier:</label>
            <select id="tierFilter">
                <option value="all">All Tiers</option>
                <option value="1">Tier 1</option>
                <option value="2">Tier 2</option>
                <option value="3">Tier 3</option>
                <option value="4">Tier 4</option>
                <option value="5">Tier 5</option>
                <option value="6">Tier 6</option>
                <option value="7">Tier 7</option>
            </select>
        </div>

        <div class="control-group">
            <label>Search Puzzle:</label>
            <input type="text" id="searchBox" placeholder="Type puzzle name...">
        </div>

        <div class="legend">
            <div class="legend-item">
                <div class="legend-color" style="background: #4ec9b0;"></div>
                <span>Tier 1 (Starter)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #569cd6;"></div>
                <span>Tier 2-3 (Early)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #c586c0;"></div>
                <span>Tier 4-5 (Mid)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #dcdcaa;"></div>
                <span>Tier 6 (Late)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #d16969;"></div>
                <span>Tier 7 (End)</span>
            </div>
        </div>
    </div>

    <div class="tooltip" id="tooltip">
        <div class="tooltip-title" id="tooltipTitle"></div>
        <div class="tooltip-content" id="tooltipContent"></div>
    </div>

    <svg id="graph"></svg>

    <script>
        const nodes = {json.dumps(nodes, indent=8)};
        const links = {json.dumps(links, indent=8)};

        const width = window.innerWidth;
        const height = window.innerHeight;

        const svg = d3.select("#graph")
            .attr("width", width)
            .attr("height", height);

        const g = svg.append("g");

        // Add zoom behavior
        const zoom = d3.zoom()
            .scaleExtent([0.1, 4])
            .on("zoom", (event) => {{
                g.attr("transform", event.transform);
            }});

        svg.call(zoom);

        // Tier colors
        const tierColors = {{
            1: "#4ec9b0",
            2: "#569cd6",
            3: "#569cd6",
            4: "#c586c0",
            5: "#c586c0",
            6: "#dcdcaa",
            7: "#d16969"
        }};

        // Create simulation
        const simulation = d3.forceSimulation(nodes)
            .force("link", d3.forceLink(links).id(d => d.id).distance(100))
            .force("charge", d3.forceManyBody().strength(-300))
            .force("x", d3.forceX(width / 2).strength(0.1))
            .force("y", d3.forceY(height / 2).strength(0.1))
            .force("collision", d3.forceCollide().radius(20));

        // Create links
        const link = g.append("g")
            .selectAll("line")
            .data(links)
            .join("line")
            .attr("class", "link");

        // Create node groups
        const nodeGroup = g.append("g")
            .selectAll("g")
            .data(nodes)
            .join("g")
            .attr("class", "node-group")
            .call(drag(simulation));

        // Add circles as backgrounds
        nodeGroup.append("circle")
            .attr("class", "node-bg")
            .attr("r", d => 15 + d.cardCount * 0.3)
            .attr("fill", d => tierColors[d.tier] || "#666")
            .attr("stroke", "#1e1e1e")
            .attr("stroke-width", 2);

        // Add images
        nodeGroup.append("image")
            .attr("class", "node-image")
            .attr("xlink:href", d => d.image)
            .attr("x", d => -(12 + d.cardCount * 0.3))
            .attr("y", d => -(12 + d.cardCount * 0.3))
            .attr("width", d => (12 + d.cardCount * 0.3) * 2)
            .attr("height", d => (12 + d.cardCount * 0.3) * 2)
            .attr("clip-path", "circle()")
            .style("pointer-events", "none")
            .on("error", function(e, d) {{
                // If image fails to load, hide it
                d3.select(this).style("display", "none");
            }});

        // Add interaction handlers to the group
        nodeGroup
            .on("mouseover", showTooltip)
            .on("mouseout", hideTooltip)
            .on("click", highlightConnections);

        const node = nodeGroup.select("circle");

        // Add labels (only shown when zoomed in)
        const label = g.append("g")
            .selectAll("text")
            .data(nodes)
            .join("text")
            .attr("class", "node-label")
            .text(d => d.name.substring(0, 20))
            .style("opacity", 0);

        // Update positions on simulation tick
        simulation.on("tick", () => {{
            link
                .attr("x1", d => d.source.x)
                .attr("y1", d => d.source.y)
                .attr("x2", d => d.target.x)
                .attr("y2", d => d.target.y);

            nodeGroup
                .attr("transform", d => `translate(${{d.x}},${{d.y}})`);

            label
                .attr("x", d => d.x)
                .attr("y", d => d.y - 25);
        }});

        // Show labels when zoomed in
        svg.on("zoom", () => {{
            const scale = d3.zoomTransform(svg.node()).k;
            label.style("opacity", scale > 1.5 ? 1 : 0);
        }});

        // Drag behavior
        function drag(simulation) {{
            function dragstarted(event) {{
                if (!event.active) simulation.alphaTarget(0.3).restart();
                event.subject.fx = event.subject.x;
                event.subject.fy = event.subject.y;
            }}

            function dragged(event) {{
                event.subject.fx = event.x;
                event.subject.fy = event.y;
            }}

            function dragended(event) {{
                if (!event.active) simulation.alphaTarget(0);
                event.subject.fx = null;
                event.subject.fy = null;
            }}

            return d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended);
        }}

        // Tooltip
        function showTooltip(event, d) {{
            const tooltip = d3.select("#tooltip");
            const title = d3.select("#tooltipTitle");
            const content = d3.select("#tooltipContent");

            title.text(d.name);
            content.html(`
                <strong>Tier:</strong> ${{d.tier}}<br>
                <strong>Cards:</strong> ${{d.cardCount}}<br>
                <strong>Provides:</strong> ${{d.provides.length > 0 ? d.provides.join(", ") : "None"}}
            `);

            tooltip
                .style("left", (event.pageX + 15) + "px")
                .style("top", (event.pageY + 15) + "px")
                .classed("visible", true);
        }}

        function hideTooltip() {{
            d3.select("#tooltip").classed("visible", false);
        }}

        // Highlight connections
        let selectedNode = null;
        function highlightConnections(event, d) {{
            if (selectedNode === d) {{
                // Deselect
                selectedNode = null;
                link.classed("highlighted", false);
                node.style("opacity", 1);
            }} else {{
                // Select
                selectedNode = d;

                const connectedNodes = new Set();
                connectedNodes.add(d.id);

                link.classed("highlighted", l => {{
                    if (l.source.id === d.id || l.target.id === d.id) {{
                        connectedNodes.add(l.source.id);
                        connectedNodes.add(l.target.id);
                        return true;
                    }}
                    return false;
                }});

                nodeGroup.style("opacity", n => connectedNodes.has(n.id) ? 1 : 0.2);
            }}
        }}

        // Tier filter
        d3.select("#tierFilter").on("change", function() {{
            const tier = this.value;
            if (tier === "all") {{
                nodeGroup.style("display", "block");
                link.style("display", "block");
            }} else {{
                const tierNum = parseInt(tier);
                nodeGroup.style("display", d => d.tier === tierNum ? "block" : "none");
                link.style("display", l => {{
                    const sourceVisible = l.source.tier === tierNum;
                    const targetVisible = l.target.tier === tierNum;
                    return sourceVisible && targetVisible ? "block" : "none";
                }});
            }}
        }});

        // Search
        d3.select("#searchBox").on("input", function() {{
            const search = this.value.toLowerCase();
            if (search === "") {{
                nodeGroup.style("opacity", 1);
                nodeGroup.select(".node-bg").attr("r", d => 15 + d.cardCount * 0.3);
                nodeGroup.select(".node-image")
                    .attr("x", d => -(12 + d.cardCount * 0.3))
                    .attr("y", d => -(12 + d.cardCount * 0.3))
                    .attr("width", d => (12 + d.cardCount * 0.3) * 2)
                    .attr("height", d => (12 + d.cardCount * 0.3) * 2);
            }} else {{
                nodeGroup.style("opacity", d => d.name.toLowerCase().includes(search) ? 1 : 0.2);
                nodeGroup.select(".node-bg").attr("r", d => {{
                    return d.name.toLowerCase().includes(search) ? 20 + d.cardCount * 0.3 : 15 + d.cardCount * 0.3;
                }});
                nodeGroup.select(".node-image")
                    .attr("x", d => {{
                        const size = d.name.toLowerCase().includes(search) ? 17 : 12;
                        return -(size + d.cardCount * 0.3);
                    }})
                    .attr("y", d => {{
                        const size = d.name.toLowerCase().includes(search) ? 17 : 12;
                        return -(size + d.cardCount * 0.3);
                    }})
                    .attr("width", d => {{
                        const size = d.name.toLowerCase().includes(search) ? 17 : 12;
                        return (size + d.cardCount * 0.3) * 2;
                    }})
                    .attr("height", d => {{
                        const size = d.name.toLowerCase().includes(search) ? 17 : 12;
                        return (size + d.cardCount * 0.3) * 2;
                    }});
            }}
        }});
    </script>
</body>
</html>"""

    return html


def main():
    print("\n========== PUZZLE PROGRESSION ANALYZER ==========\n")

    json_path = Path(__file__).parent / "puzzle_cards.json"
    puzzle_data = load_puzzle_json(json_path)

    if not puzzle_data:
        print("ERROR: No puzzle data loaded")
        return

    progression = calculate_progression(puzzle_data)
    print_progression(progression)

    # Generate simple tier graph
    html = generate_html_graph(progression)
    output_path = Path(__file__).parent / "puzzle_progression.html"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"\n✓ Generated tier view: {output_path}")

    # Generate detailed network graph
    network_html = generate_network_graph(puzzle_data, progression)
    network_path = Path(__file__).parent / "puzzle_network.html"
    with open(network_path, 'w', encoding='utf-8') as f:
        f.write(network_html)

    print(f"✓ Generated network graph: {network_path}")
    print("  Open this file in your browser to see the interactive dependency graph!\n")

    print("========== END ANALYZER ==========\n")


if __name__ == "__main__":
    main()
