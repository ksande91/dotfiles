#!/bin/bash
# Force the environment to load
source /etc/profile
source ~/.bashrc

# Set the working directory to where the script resides
cd ~/Documents/system/update-prompt

# Switch to workspace 1
hyprctl dispatch workspace 1

# Launch the terminal and keep it open
kitty --class Floating bash -ic './update_prompt;'
