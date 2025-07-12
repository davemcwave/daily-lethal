from PIL import Image
import os

folder = "./Assets/Textures"

print(os.listdir(folder))
for filename in os.listdir(folder):
    if filename.endswith(".png"):
        path = os.path.join(folder, filename)
        with Image.open(path) as img:
            w, h = img.size
            if w == h and w > 256:
                print(f"{filename} is {img.size}, resizing to 256x256")
                resized = img.resize((256, 256), Image.LANCZOS)
                resized.save(path)
