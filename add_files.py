import sys
import os
from pbxproj import XcodeProject

project_path = 'Dragover.xcodeproj/project.pbxproj'
project = XcodeProject.load(project_path)

files_to_add = [
    'Dragover/UI/Shelf/ShelfCell.swift',
    'Dragover/UI/Shelf/ShelfCollectionView.swift'
]

# Find the main group for UI/Shelf or just add to root and let Xcode handle it, but better to be tidy
# Since pbxproj handles relative paths, adding them should work.
# We will add them to the main target 'Dragover'

for file_path in files_to_add:
    if os.path.exists(file_path):
        # Check if already exists to avoid duplicates (though pbxproj usually handles this)
        # Adding to project
        # force=False prevents overwriting existing references if they exist
        project.add_file(file_path, force=False)
        print(f"Added {file_path}")
    else:
        print(f"File not found: {file_path}")

project.save()
