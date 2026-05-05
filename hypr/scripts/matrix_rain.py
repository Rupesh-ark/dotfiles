#!/usr/bin/env python3
"""Matrix rain effect for Hyprlock label."""
import random
import json
import os

COLS, ROWS, TRAIL = 350, 160, 14
STATE = "/tmp/hyprlock_matrix.json"
CHARS = "0123456789ABCDEFGHJKLMNPRSTUVWXYZアイウエオカキクケコサシスセソタチツテト"

try:
    with open(STATE) as f:
        state = json.load(f)
    heads = state["heads"]
    speeds = state["speeds"]
except (FileNotFoundError, json.JSONDecodeError, KeyError):
    heads = [random.randint(-12, ROWS) for _ in range(COLS)]
    speeds = [random.choice([1, 1, 1, 2]) for _ in range(COLS)]

# Advance each column
for i in range(COLS):
    heads[i] += speeds[i]
    if heads[i] > ROWS + 14:
        heads[i] = random.randint(-14, -1)
        speeds[i] = random.choice([1, 1, 1, 2])

with open(STATE, "w") as f:
    json.dump({"heads": heads, "speeds": speeds}, f)

# Render the grid
lines = []
for r in range(ROWS):
    row = []
    for c in range(COLS):
        h = heads[c]
        if h - TRAIL < r <= h:
            row.append(random.choice(CHARS))
        else:
            row.append(" ")
    lines.append("".join(row))

print("\n".join(lines))
