import os
import re

BASE_URL = "https://playlethal.fun"

def inject_canonical(file_path, subdir):
    with open(file_path, 'r', encoding='utf-8') as f:
        html = f.read()

    canonical_url = f'{BASE_URL}/{subdir}'
    canonical_tag = f'<link rel="canonical" href="{canonical_url}" />'

    # Avoid double insertion
    if canonical_tag in html:
        return

    # Insert before </head>
    updated_html = re.sub(
        r'(</head>)',
        f'    {canonical_tag}\n\\1',
        html,
        count=1
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated_html)
    print(f'✅ Canonical added to: {file_path}')

def process_directory(root_dir):
    for subdir in os.listdir(root_dir):
        subdir_path = os.path.join(root_dir, subdir)
        if os.path.isdir(subdir_path) and re.match(r'\d{4}-\d{2}-\d{2}', subdir):
            index_path = os.path.join(subdir_path, 'index.html')
            if os.path.isfile(index_path):
                inject_canonical(index_path, subdir)

if __name__ == '__main__':
    process_directory('.')
