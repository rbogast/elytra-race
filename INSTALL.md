# Quick Installation Guide

## Step 1: Prepare Your Computers

You will need:
- **1 Main Computer** (race controller)
- **15 Gate Computers** (one at each gate)
- **1 Split Timer Computer** (at halfway point)
- **1 Finish Line Computer** (at finish line)
- **1 Leaderboard Computer** (anywhere visible)

All computers must be **Advanced Computers** with **Ender Modems** attached.

## Step 2: Upload Files

### All Computers Need These Core Files:
```
config.lua
utils.lua
database.lua
```

### Main Computer Only:
```
setup.lua
```

### Gate Computers Only:
```
gate.lua
```

### Split Timer Computer Only:
```
split_display.lua
```

### Finish Line Computer Only:
```
finish_display.lua
```

### Leaderboard Computer Only:
```
leaderboard.lua
```

## Step 3: Configure Gate Numbers

For each of the 15 gate computers:

1. Edit `gate.lua`
2. Find line: `local GATE_NUMBER = 1`
3. Change the number to match the gate (1-15)
4. Save the file

**Example:**
- Gate 1 computer: `local GATE_NUMBER = 1`
- Gate 2 computer: `local GATE_NUMBER = 2`
- Gate 15 computer: `local GATE_NUMBER = 15`

## Step 4: Configure Redstone (Main Computer)

The main computer needs redstone connections for:

- **LEFT side**: Start/Finish line trigger (from Integrated Dynamics)
- **BACK side**: False start detection (from Integrated Dynamics)

### Integrated Dynamics Setup:
1. Place an **Entity Reader** at the start line
2. Configure it to detect players entering a specific area
3. Send redstone signal to LEFT side of main computer
4. For false starts: detect players BEFORE the start signal is armed
5. Send that signal to BACK side of main computer

## Step 5: Start the System

Start each computer in this order:

```
1. Gate computers (all 15): Run "gate.lua"
2. Split timer: Run "split_display.lua"
3. Finish line: Run "finish_display.lua"  
4. Leaderboard: Run "leaderboard.lua"
5. Main computer: Run "setup.lua"
```

## Step 6: Test the System

1. On the main computer, select option **1** (Arm Race)
2. Enter a test player name
3. Have a player fly through gate 1 - it should be detected
4. The main computer should log "GATE 1 PASSED"
5. Continue through all gates to the finish line

## Step 7: Configure Your Course Settings

Edit `config.lua` to customize:

```lua
-- Change number of gates
config.TOTAL_GATES = 15

-- Change which gate has split timer (halfway point)
config.SPLIT_GATE_NUMBER = 8

-- Change penalties (in milliseconds)
config.FALSE_START_PENALTY = 3000  -- 3 seconds
config.MISSED_GATE_PENALTY = 5000  -- 5 seconds
```

## Common Issues

### "No ender modem found"
- Attach an ender modem to the computer
- Ensure it's an **ender** modem, not regular modem

### "No player detector found"
- Gate computers need a Player Detector from Advanced Peripherals
- Attach it to the gate computer

### "No monitor found"
- Display computers need monitors attached
- Can be a single monitor or monitor wall

### Gates not detected
- Check player detector range (16 blocks)
- Verify gate computer is running
- Check GATE_NUMBER is unique for each gate

### Database not saving
- Ensure the database file `race_database.txt` can be written
- Check computer has sufficient storage

## Video Display Recommendations

### Split Timer & Finish Line:
- Minimum: 3x3 monitor wall
- Recommended: 4x3 or 5x3 for better visibility
- Large text scale in config

### Leaderboard:
- Minimum: 2x3 monitor wall
- Recommended: 3x4 for top 10 display
- Smaller text scale for more entries

## Running a Race

1. Main computer menu → **1** (Arm Race)
2. Enter player name
3. Player flies through start line (race begins)
4. Player flies through gates 1-15
5. Player flies through finish line
6. Results saved automatically
7. Reset race for next player

## Support

See `README.md` for full documentation, troubleshooting, and customization options.
