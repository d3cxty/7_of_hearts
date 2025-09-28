#!/bin/bash
# 7 of Hearts Game Launcher

clear
echo "🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮"
echo "            🎯 7 OF HEARTS 🎯"
echo "     Alice in Borderland Inspired Game"
echo "🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮🎮"
echo ""
echo "🎮 How to Play:"
echo "   • Touch other players to swap roles"
echo "   • Wolf gets speed advantage"
echo "   • Survive for 3 minutes!"
echo ""
echo "🎯 Controls:"
echo "   • WASD - Move"
echo "   • Mouse - Look"
echo "   • Shift - Sprint"
echo "   • Space - Jump"
echo ""
echo "🌐 Multiplayer:"
echo "   • Host: Click 'NEW GAME'"
echo "   • Join: Enter host's IP address"
echo ""
echo "Starting game..."
sleep 2

# Try to run the Linux build
if [ -f "builds/7_of_hearts_linux.x86_64" ]; then
    ./builds/7_of_hearts_linux.x86_64
elif [ -f "7_of_hearts_linux.x86_64" ]; then
    ./7_of_hearts_linux.x86_64
else
    echo "❌ Game executable not found!"
    echo "Please run: ./build.sh first"
fi