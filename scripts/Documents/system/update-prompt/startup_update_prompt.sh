#!/bin/bash
# Force the environment to load
source /etc/profile
source ~/.bashrc

# Set the working directory to where the script resides
cd ~/Documents/system/update-prompt

# Launch the terminal and keep it open (window rule pins UpdatePrompt to workspace 1)
kitty --class UpdatePrompt bash -ic './update_prompt;'
