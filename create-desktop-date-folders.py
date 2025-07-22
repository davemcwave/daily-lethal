import os
import shutil
import re

# Root and desktop paths
ROOT_DIR = "./"
DESKTOP_DIR = os.path.join(ROOT_DIR, "desktop")

# Regex for date folders like YYYY-MM-DD
DATE_FOLDER_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# Make sure /desktop exists
os.makedirs(DESKTOP_DIR, exist_ok=True)

# Loop through all date-named folders in root
for item in os.listdir(ROOT_DIR):
    root_path = os.path.join(ROOT_DIR, item)
    if os.path.isdir(root_path) and DATE_FOLDER_PATTERN.match(item) and item != "desktop":
        desktop_date_dir = os.path.join(DESKTOP_DIR, item)

        # Create or clear the directory
        if os.path.exists(desktop_date_dir):
            print(f"Clearing /desktop/{item}...")
            shutil.rmtree(desktop_date_dir)
        os.makedirs(desktop_date_dir)
        print(f"Created /desktop/{item}")

print("Done!")
