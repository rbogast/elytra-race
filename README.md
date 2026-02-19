# Elytra Race Time Trial System

A comprehensive time trial racing system for Minecraft using CC:Tweaked, Advanced Peripherals, and Integrated Dynamics. Track player times through a 15-gate course with split timers, leaderboards, and penalty tracking.

## System Architecture

### Main Components

1. **Main Computer** (`setup.lua`) - Central race controller
   - Manages race state and timing
   - Handles false start detection
   - Logs race events
   - Calculates penalties
   - Saves results to database

2. **Gate Computers** (`gate.lua`) - 15 gate stations
   - Detects players passing through gates
   - Reports to main computer via ender modem
   - Displays gate number on monitor

3. **Split Timer** (`split_display.lua`) - Halfway point display
   - Shows current race time with large digits
   - Displays delta (green/red) compared to target
   - Located at gate 8 by default

4. **Finish Line Display** (`finish_display.lua`) - Final time display
   - Shows finish time with delta comparison
   - Green if beating target, red if behind

5. **Leaderboard** (`leaderboard.lua`) - Top 10 display
   - Monitor bank showing best times
   - Auto-updates when new times are recorded
   - Touch to manually refresh

## Hardware Requirements

### Main Computer
- 1x Advanced Computer
- 1x Ender Modem
- Redstone inputs:
  - **Left side**: Start line trigger (player detection from Integrated Dynamics)
  - **Back side**: False start detection (Integrated Dynamics entity sensor)

### Each Gate (x15)
- 1x Advanced Computer
- 1x Ender Modem
- 1x Player Detector (Advanced Peripherals)
- 1x Monitor (optional, for gate number display)

### Split Timer Computer
- 1x Advanced Computer
- 1x Ender Modem
- Monitor wall (recommend 3x3 or larger)

### Finish Line Computer
- 1x Advanced Computer
- 1x Ender Modem
- Monitor wall (recommend 3x3 or larger)

### Leaderboard Computer
- 1x Advanced Computer
- 1x Ender Modem
- Monitor wall (recommend 2x3 or larger)

## Installation

1. **Copy all files to each computer:**
   ```
   config.lua
   utils.lua
   database.lua
   ```

2. **Main Computer:**
   ```
   setup.lua (run this)
   ```

3. **Gate Computers (repeat for gates 1-15):**
   ```
   gate.lua
   ```
   Edit `gate.lua` and change `GATE_NUMBER` for each gate (1-15)

4. **Split Timer:**
   ```
   split_display.lua
   ```

5. **Finish Line:**
   ```
   finish_display.lua
   ```

6. **Leaderboard:**
   ```
   leaderboard.lua
   ```

7. **Configuration:**
   Edit `config.lua` to adjust:
   - Gate count (default: 15)
   - Split gate number (default: 8 - halfway point)
   - Penalties (false start: 3s, missed gate: 5s)
   - Modem channels
   - Display settings

## Usage

### Starting the System

1. Start all gate computers: `gate.lua`
2. Start split timer: `split_display.lua`
3. Start finish line: `finish_display.lua`
4. Start leaderboard: `leaderboard.lua`
5. Start main computer: `setup.lua`

### Running a Race

1. On the main computer, select option **1** (Arm Race)
2. Enter the player's name
3. Optionally change comparison mode (option **2**):
   - **Personal Best**: Compare to player's best time
   - **Course Record**: Compare to overall best time
   - **Daily Best**: Compare to best time today

4. The system is now ARMED and waiting for the player
5. When the player crosses the start line (Integrated Dynamics detection), the race begins
6. Gates are tracked as the player passes through them
7. At gate 8 (halfway), the split timer shows their progress
8. When the player crosses the finish line, results are calculated

### Penalty System

- **False Start**: +3 seconds (detected by Integrated Dynamics before start)
- **Missed Gate**: +5 seconds per gate

### Race Log Example
```
00:00.000 - RACE STARTED
00:09.250 - GATE 1 PASSED
00:16.300 - GATE 2 PASSED
00:23.100 - GATE 3 PASSED
[...]
01:10.100 - GATE 15 PASSED
01:23.550 - FINISHED!
Missed gate 4: +5.000s
Final Time: 01:28.550
```

## Comparison Modes

The system supports three comparison modes for split/finish delta displays:

1. **Personal Best**: Shows how the current run compares to the player's best time
2. **Course Record**: Shows how the current run compares to the all-time best
3. **Daily Best**: Shows how the current run compares to the best time today

## Delta Display

- **Green numbers**: Player is ahead of target time (faster)
- **Red numbers**: Player is behind target time (slower)
- Display format: +/-X.XXX (seconds difference)

## Database

Race data is stored in `race_database.txt`:
- Top 20 times per player
- Global best time
- Daily best times
- Split times for each gate
- Penalty information

## Menu Commands

From the main computer setup menu:

1. **Arm Race** - Prepare the course for a player
2. **Set Comparison Mode** - Choose personal/course/daily comparison
3. **Reset Race** - Cancel current race
4. **View Top 10** - Display leaderboard in terminal
5. **View Player Stats** - See all runs for a specific player
6. **Q** - Enter monitoring mode

In monitoring mode, press **M** to return to the menu.

## Troubleshooting

### Gates not detecting players
- Check that player detector has power
- Verify ender modem is attached and configured
- Ensure player is within 16 blocks of detector

### Displays not updating
- Verify ender modems are on correct channels
- Check that monitors are connected
- Restart display computers

### False start not detecting
- Verify Integrated Dynamics entity sensor is configured
- Check redstone connection to back of main computer
- Test redstone signal manually

### Database not saving
- Ensure main computer has write permissions
- Check for disk space
- Verify `database.lua` is present

## Customization

### Changing Gate Count
Edit `config.lua`:
```lua
config.TOTAL_GATES = 20  -- Change from 15 to 20
```

### Adjusting Split Gate Location
Edit `config.lua`:
```lua
config.SPLIT_GATE_NUMBER = 10  -- Change from 8 to 10
```

### Changing Penalties
Edit `config.lua`:
```lua
config.FALSE_START_PENALTY = 5000  -- 5 seconds (in milliseconds)
config.MISSED_GATE_PENALTY = 10000  -- 10 seconds
```

### Monitor Text Scale
Edit `config.lua`:
```lua
config.TIMER_TEXT_SCALE = 1.0  -- Larger numbers
config.LEADERBOARD_TEXT_SCALE = 0.5  -- Smaller text
```

## Technical Details

### Modem Channels
- **100**: Gates → Main (gate passage events)
- **101**: Main → Gates (control commands)
- **102**: Main → Split Timer (race updates)
- **103**: Main → Finish Line (race updates)
- **104**: Main → Leaderboard (update notifications)

### Message Protocol

Gate passage:
```lua
{
  type = "gate_passed",
  gate = 1,
  player = "PlayerName",
  timestamp = 123456789
}
```

Race start:
```lua
{
  type = "race_start",
  player = "PlayerName",
  comparison = 45000  -- target time in ms
}
```

## Credits

Built for Minecraft with:
- CC:Tweaked (ComputerCraft)
- Advanced Peripherals
- Integrated Dynamics

Perfect for elytra racing minigames, speedrun competitions, and parkour courses!
