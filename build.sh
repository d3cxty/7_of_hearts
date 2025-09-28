#!/bin/bash
# Build script for 7 of Hearts game

echo "🎮 Building 7 of Hearts..."
echo "=========================="

# Create builds directory if it doesn't exist
mkdir -p builds

# Export for Linux
echo "📦 Exporting Linux build..."
godot --headless --export-release "Linux" builds/7_of_hearts_linux.x86_64

# Export for Windows  
echo "📦 Exporting Windows build..."
godot --headless --export-release "Windows Desktop" builds/7_of_hearts_windows.exe

echo "✅ Build complete!"
echo "📁 Files created in builds/ directory"
echo ""
echo "🎯 To run:"
echo "   Linux: ./builds/7_of_hearts_linux.x86_64"  
echo "   Windows: ./builds/7_of_hearts_windows.exe"