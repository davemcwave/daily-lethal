import os
import shutil
import re

# Root directory
ROOT_DIR = "./"

# Regex to match folders named like YYYY-MM-DD
DATE_FOLDER_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# Loop through root directory and remove each {date}/desktop folder
for item in os.listdir(ROOT_DIR):
    item_path = os.path.join(ROOT_DIR, item)
    if os.path.isdir(item_path) and DATE_FOLDER_PATTERN.match(item):
        desktop_path = os.path.join(item_path, "desktop")
        if os.path.exists(desktop_path) and os.path.isdir(desktop_path):
            print(f"Removing folder: {desktop_path}")
            shutil.rmtree(desktop_path)

print("Done!")
