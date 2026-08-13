"""
STEP 1: Organize cat images into folders by emotion label.

TensorFlow's image_dataset_from_directory (and ImageDataGenerator)
expect this folder structure:

    data/
      cat/
        Relaxed/
          00001.jpg
          00004.jpg
          ...
        Happy/
          ...
        Aggressive/
          ...
        Sad/
          ...

This script reads pet_labels.txt, figures out which images are cats
(using the same word-boundary detection as before), and COPIES those
images from your raw images folder into the structure above.

USAGE:
    python organize_cat_images.py

BEFORE RUNNING:
    1. Make sure pet_labels.txt is in this folder.
    2. Set RAW_IMAGES_DIR below to wherever your actual .jpg files live
       (the folder that contains images/00001.jpg, images/00002.jpg, etc.)
    3. Set OUTPUT_DIR to where you want the organized dataset to go.
"""

import json
import os
import re
import shutil
from collections import Counter

LABELS_FILE = "pet_labels.txt"
RAW_IMAGES_DIR = "images"          # <-- CHANGE THIS: folder containing the actual .jpg files
OUTPUT_DIR = "data/cat"            # <-- organized dataset will be created here

SPECIES_WORDS = ["cat", "dog", "horse", "bird", "rabbit", "hamster", "bunny"]


def detect_species(text: str):
    text = text.lower()
    found = set()
    for word in SPECIES_WORDS:
        if re.search(rf"\b{word}s?\b", text):
            found.add(word)
    if len(found) == 1:
        return found.pop()
    return None


def main():
    if not os.path.isdir(RAW_IMAGES_DIR):
        print(f"ERROR: RAW_IMAGES_DIR '{RAW_IMAGES_DIR}' not found.")
        print("Edit the RAW_IMAGES_DIR variable at the top of this script "
              "to point to the folder containing your actual .jpg files.")
        return

    counts = Counter()
    missing_files = 0

    with open(LABELS_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            entry = json.loads(line)

            text = entry.get("visual_features", "") + " " + entry.get("cot_analysis", "")
            species = detect_species(text)
            if species != "cat":
                continue

            label = entry.get("final_emotion_label", "UNKNOWN")
            image_rel_path = entry["image"]                 # e.g. "images/00001.jpg"
            image_filename = os.path.basename(image_rel_path)  # e.g. "00001.jpg"

            src_path = os.path.join(RAW_IMAGES_DIR, image_filename)
            if not os.path.exists(src_path):
                # try the path exactly as written in the json, relative to cwd
                src_path = image_rel_path
                if not os.path.exists(src_path):
                    missing_files += 1
                    continue

            dest_dir = os.path.join(OUTPUT_DIR, label)
            os.makedirs(dest_dir, exist_ok=True)
            dest_path = os.path.join(dest_dir, image_filename)

            shutil.copy2(src_path, dest_path)
            counts[label] += 1

    print("=" * 50)
    print("DONE ORGANIZING CAT IMAGES")
    print("=" * 50)
    for label, n in counts.most_common():
        print(f"{label:<15} {n:>6} images -> {OUTPUT_DIR}/{label}/")
    if missing_files:
        print(f"\nWARNING: {missing_files} images were listed in {LABELS_FILE} "
              f"but not found in '{RAW_IMAGES_DIR}'. Check RAW_IMAGES_DIR is correct.")
    print(f"\nTotal organized: {sum(counts.values())} cat images")


if __name__ == "__main__":
    main()