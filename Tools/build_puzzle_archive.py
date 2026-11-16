"""Build Data/puzzle_archive.json: every released daily puzzle, for the desktop Puzzle Archive.

    python Tools/build_puzzle_archive.py

Run from the repo root after puzzles are released (manifest.json / custom-redirects.json change).
Reads only repo files:
  - manifest.json             which puzzles are released (date, title)
  - Scenes/Puzzles/*.tscn     scene puzzles: cards, numbers, enemy statuses
  - custom-redirects.json     URL puzzles ("?cards=...&php=&pnrg=&ehp=&enemy_name=&author=&enemy_buffs=")
  - Scripts/Background.gd     ENEMY_DIFFICULTIES and PUZZLE_AUTHORS
  - formspree_*_export.json   the creator's difficulty when Background doesn't have one
Difficulty is 1-5 skulls (Very Easy .. Very Hard); unknown puzzles are Medium (3).
"""
import base64, glob, json, os, re, urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

SKULLS = {'VERY_EASY': 1, 'EASY': 2, 'MEDIUM': 3, 'HARD': 4, 'VERY_HARD': 5}
WORD_SKULLS = {'very easy': 1, 'easy': 2, 'medium': 3, 'hard': 4, 'very hard': 5}


def read(path):
    return open(path, encoding='utf-8').read()


# ---- Background tables
background = read('Scripts/Background.gd')


def table(name):
    start = background.index('const %s' % name)
    return background[start:background.index('\n}', start)]


difficulty = {n: SKULLS[d] for n, d in re.findall(r'"([^"]+)"\s*:\s*Difficulty\.(\w+)', table('ENEMY_DIFFICULTIES'))}
authors = dict(re.findall(r'"([^"]+)"\s*:\s*"([^"]*)"', table('PUZZLE_AUTHORS')))

# ---- creators' difficulty from Formspree submissions (enemy_info starts with the enemy name)
submitted = []
for path in sorted(glob.glob('formspree_*_export.json')):
    data = json.load(open(path, encoding='utf-8'))
    for item in (data if isinstance(data, list) else data.get('submissions', [])):
        word = str(item.get('difficulty') or '').strip().lower()
        if word in WORD_SKULLS:
            submitted.append((str(item.get('enemy_info') or '').lower(), WORD_SKULLS[word]))


def submitted_difficulty(enemy):
    key = enemy.lower()
    for info, skulls in submitted:
        if info.startswith(key):
            return skulls
    return None


# ---- card display names ("Emptyfist" file -> "Empty Fist" card_name)
card_names = {}
for path in glob.glob('Scenes/*Card.tscn'):
    m = re.search(r'^card_name = "([^"]+)"', read(path), re.M)
    if m:
        card_names[os.path.basename(path)[:-len('Card.tscn')].lower()] = m.group(1)


def card_name(key):
    key = key.lower().replace(' ', '').replace('-', '')
    return card_names.get(key, key.title())


def scene_puzzle(path):
    text = read(path)
    ext = dict((i, p) for p, i in re.findall(r'\[ext_resource [^\]]*path="([^"]+)"[^\]]*id="([^"]+)"\]', text))

    def field(name, default=None):
        m = re.search(r'^%s = (.+)$' % name, text, re.M)
        return m.group(1).strip().strip('"') if m else default

    cards = []
    m = re.search(r'^card_scenes = \[(.*)\]$', text, re.M)
    if m:
        for rid in re.findall(r'ExtResource\("([^"]+)"\)', m.group(1)):
            cards.append(card_name(os.path.basename(ext.get(rid, ''))[:-len('Card.tscn')]))
    statuses = sorted({os.path.basename(p)[:-len('Buff.tscn')] for p in ext.values() if p.endswith('Buff.tscn')}
                      & {'Doom', 'Retaliate'})
    return {'enemy': field('enemy_name', ''), 'cards': cards, 'php': int(field('player_health', 3)),
            'energy': int(field('player_energy', 5)), 'ehp': int(field('enemy_health', 10)), 'statuses': statuses,
            'scene': 'res://' + path.replace(os.sep, '/')}


def url_puzzle(search):
    params = urllib.parse.parse_qs(search.lstrip('?'))
    encoded = urllib.parse.unquote(params['cards'][0])
    cards = [card_name(c.strip().lower().replace('-card.png', ''))
             for c in urllib.parse.unquote(base64.b64decode(encoded + '=' * (-len(encoded) % 4)).decode()).split(',') if c.strip()]
    statuses = sorted({b.split(':')[0] for b in params.get('enemy_buffs', [''])[0].split(',') if b})
    return {'enemy': params.get('enemy_name', [''])[0], 'author': params.get('author', [''])[0], 'cards': cards,
            'php': int(params.get('php', [3])[0]), 'energy': int(params.get('pnrg', [5])[0]),
            'ehp': int(params.get('ehp', [10])[0]), 'statuses': statuses, 'search': search}


scenes = {os.path.basename(p)[:10]: p for p in glob.glob('Scenes/Puzzles/*.tscn')}
redirects = json.load(open('custom-redirects.json', encoding='utf-8'))
manifest = json.load(open('manifest.json', encoding='utf-8'))['puzzles']

puzzles = []
for item in sorted(manifest, key=lambda p: p['id']):
    date = item['id']
    if date in redirects:
        entry = url_puzzle(redirects[date])
    elif date in scenes:
        entry = scene_puzzle(scenes[date])
    else:
        print('skipped (no puzzle found):', date, item.get('title'))
        continue
    enemy = entry['enemy'] or item.get('title', '')
    entry['enemy'] = enemy
    entry['author'] = entry.get('author') or authors.get(enemy, '')
    entry['skulls'] = difficulty.get(enemy) or submitted_difficulty(enemy) or 3
    entry['date'] = date
    entry['id'] = 'daily:' + date
    puzzles.append({k: entry[k] for k in ('id', 'date', 'enemy', 'author', 'skulls', 'cards', 'php', 'energy', 'ehp', 'statuses')
                    if k in entry} | ({'scene': entry['scene']} if 'scene' in entry else {'search': entry['search']}))

# One spelling per author: names that differ only in capitals ("Gold_me", "gold_me") use the most common one.
spellings = {}
for p in puzzles:
    spellings.setdefault(p['author'].lower(), {}).setdefault(p['author'], 0)
    spellings[p['author'].lower()][p['author']] += 1
for p in puzzles:
    options = spellings[p['author'].lower()]
    p['author'] = max(options, key=lambda name: (options[name], name))

data = {'note': 'Generated by Tools/build_puzzle_archive.py from manifest.json, custom-redirects.json and the puzzle scenes. '
                'Do not edit by hand; rerun the script after releasing puzzles.',
        'puzzles': puzzles}
with open('Data/puzzle_archive.json', 'w', encoding='utf-8', newline='\n') as fh:
    json.dump(data, fh, indent=1, ensure_ascii=False)
    fh.write('\n')
print('puzzles', len(puzzles), 'scene', sum('scene' in p for p in puzzles), 'url', sum('search' in p for p in puzzles),
      'no author', sum(not p['author'] for p in puzzles))
