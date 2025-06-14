import os
import shutil
import re

# Root directory where all date folders are located
ROOT_DIR = "./"  # Change to your actual parent folder if needed

# The source folder you want to copy from
SOURCE_DIR = os.path.join(ROOT_DIR, "today")

# Regex to match folders named like YYYY-MM-DD
DATE_FOLDER_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")

for item in os.listdir(ROOT_DIR):
    item_path = os.path.join(ROOT_DIR, item)

    if os.path.isdir(item_path) and DATE_FOLDER_PATTERN.match(item) and item != "today":
        print(f"Updating: {item}")

        # Clear contents of the target folder
        for filename in os.listdir(item_path):
            file_path = os.path.join(item_path, filename)
            if os.path.isfile(file_path) or os.path.islink(file_path):
                print(f"Found file_path to remove: {file_path}")
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                print(f"Found file_path to remove: {file_path}")
                shutil.rmtree(file_path)

        # Copy contents of SOURCE_DIR to this folder
        for src_item in os.listdir(SOURCE_DIR):
            src_path = os.path.join(SOURCE_DIR, src_item)
            dest_path = os.path.join(item_path, src_item)
            if os.path.isdir(src_path):
                print(f"Copying {src_path} to {dest_path}")
                shutil.copytree(src_path, dest_path)
            else:
                print(f"Copying {src_path} to {dest_path}")
                shutil.copy2(src_path, dest_path)

print("Done!")
