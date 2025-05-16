import glob

with open('ga.html', 'r', encoding='utf-8') as ga_html_file:
    ga_html_data = ga_html_file.read()

for html_file_path in glob.glob('**/index.html', recursive=True):
    with open(html_file_path, "r", encoding='utf-8') as index_html_file:
        index_html_data = index_html_file.read()
        print(f"checking {html_file_path}")
        if ga_html_data in index_html_data:
            print(f"already found ga tag in {html_file_path}")
            continue

    if '</head>' in index_html_data:
        updated_html_data = index_html_data.replace('</head>', f'{ga_html_data}\n</head>')
    else:
        updated_html_data = index_html_data + '\n' + ga_html_data

    print(f"adding ga tag to {html_file_path}")
    with open(html_file_path, "w", encoding='utf-8') as index_html_file:
        index_html_file.write(updated_html_data)
        print(f"added ga tag to {html_file_path}")
