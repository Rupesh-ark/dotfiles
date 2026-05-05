#!/bin/bash
# Screenshot via grimblast - copies to clipboard and saves to ~/Pictures/Screenshots
mkdir -p ~/Pictures/Screenshots
grimblast --notify copysave area ~/Pictures/Screenshots/"$(date +'%Y%m%d_%H%M%S').png"
