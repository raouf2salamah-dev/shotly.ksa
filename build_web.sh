#!/bin/bash

echo "Building Flutter web app in release mode..."
flutter build web --release --obfuscate --split-debug-info=./symbols

if [ $? -eq 0 ]; then
  echo "\nBuild successful! Web app is available in build/web/"
  echo "You can deploy this to any web hosting service like Firebase Hosting, Vercel, or GitHub Pages."
  echo "\nTo test locally, you can run:"
  echo "cd build/web && python -m http.server 8000"
  echo "Then open http://localhost:8000 in your browser"
else
  echo "\nBuild failed. Please check the error messages above."
fi