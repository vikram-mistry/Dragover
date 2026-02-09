import sys
import os
from pbxproj import XcodeProject

print(f"Current setup: {os.getcwd()}")
if os.path.exists('Dragover.xcodeproj/project.pbxproj'):
    print("Project file found.")
else:
    print("Project file NOT found.")
    sys.exit(1)

project = XcodeProject.load('Dragover.xcodeproj/project.pbxproj')
print("Project loaded.")

files = [
    'Dragover/UI/Shelf/ShelfCell.swift',
    'Dragover/UI/Shelf/ShelfCollectionView.swift'
]

for f in files:
    if os.path.exists(f):
        print(f"Processing {f}...")
        try:
            # project.add_file returns a list of objects or None
            added = project.add_file(f, force=False)
            print(f"Added result used: {added}")
        except Exception as e:
            print(f"Error adding {f}: {e}")
    else:
        print(f"File missing on disk: {f}")

project.save()
print("Project saved.")
