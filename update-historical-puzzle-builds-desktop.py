import os
import shutil
import re

# Set paths
SOURCE_DESKTOP_DIR = "./desktop/today"
DESTINATION_DESKTOP_DIR = "./desktop"
TEST_PUZZLE_DIR = os.path.join(DESTINATION_DESKTOP_DIR, "test-puzzle")

# Match folders like 2025-07-01
DATE_FOLDER_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# Get the top-level files in /desktop/today
desktop_files = [
    f for f in os.listdir(SOURCE_DESKTOP_DIR)
    if os.path.isfile(os.path.join(SOURCE_DESKTOP_DIR, f))
]

# Function to clear and copy to a target directory
def clear_and_copy_to(target_dir, label):
    print(f"Updating {label}...")
    os.makedirs(target_dir, exist_ok=True)

    for filename in os.listdir(target_dir):
        file_path = os.path.join(target_dir, filename)
        if os.path.isfile(file_path) or os.path.islink(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path)

    for filename in desktop_files:
        src = os.path.join(SOURCE_DESKTOP_DIR, filename)
        dst = os.path.join(target_dir, filename)
        print(f"Copying {filename} to {label}")
        shutil.copy2(src, dst)

# Loop through all /desktop/{date} folders
for item in os.listdir(DESTINATION_DESKTOP_DIR):
    date_dir = os.path.join(DESTINATION_DESKTOP_DIR, item)
    if os.path.isdir(date_dir) and DATE_FOLDER_PATTERN.match(item):
        clear_and_copy_to(date_dir, f"/desktop/{item}")

# Also update /desktop/test-puzzle
clear_and_copy_to(TEST_PUZZLE_DIR, "/desktop/test-puzzle")

print("Done!")
