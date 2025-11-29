# Preview Tile System

## Overview
The preview tile system allows players to see where a tile will be placed before confirming the placement. This provides a better user experience by letting players visualize their move.

## How It Works

### 1. **Single-Click on Tile Button**
- When a player clicks a tile button in the UI, a semi-transparent preview of that tile appears at its designated grid position
- The preview tile has 50% opacity to clearly indicate it's not yet placed
- The preview shows the exact position where the tile will be placed

### 2. **Selecting Different Tiles**
- If the player clicks another tile button while a preview is shown, the old preview is removed
- A new preview appears at the new tile's position
- This allows players to compare different tile placements

### 3. **Double-Click to Confirm**
- Double-clicking anywhere on the screen confirms the preview tile placement
- The preview tile is removed and replaced with the actual tile
- The tile is permanently placed and the game continues normally
- Camera zooms in on the placed tile, then returns to default view after 1 second

### 4. **PvP Mode Support**
- The system works in both single-player (vs AI) and PvP modes
- In PvP mode, turns alternate between players after each confirmed placement

## Key Functions

### `_show_preview_tile(tile_path: String, row: int, col: int)`
- Creates a semi-transparent preview tile at the specified position
- Removes any existing preview first
- Checks if the cell is already occupied

### `_remove_preview_tile()`
- Removes the current preview tile from the scene
- Clears all preview-related variables

### `_set_tile_transparency(tile: Node3D, alpha: float)`
- Recursively sets transparency for all mesh instances in a tile
- Used to make the preview tile semi-transparent (50% opacity)

### `_confirm_tile_placement()`
- Converts the preview tile into an actual placed tile
- Handles scoring, city completion, and turn management
- Removes the tile from the UI selector

### Modified Functions

#### `_on_tile_selected(tile_path: String)`
- Now shows a preview instead of immediately placing the tile
- Stores the selected scene for later confirmation

#### `_handle_double_tap(screen_pos: Vector2)`
- First checks if a preview tile exists
- If yes, confirms the placement
- If no, focuses camera on existing tiles (original behavior)

### `TileSelectorUI.gd` Changes
- **Single Click Selection**: Modified `_on_button_gui_input` to trigger selection on single click instead of double click
- **Prevent Premature Removal**: Removed `remove_tile_button` call from `_select_tile` to ensure the button stays visible during preview mode

## Visual Feedback
- **Preview Tile**: Semi-transparent (70% opacity), slightly raised (0.1 units), and no shadows to distinguish from placed tiles
- **Placed Tile**: Full opacity, permanent on the board
- **Camera**: Zooms in on confirmed placement, returns to default after 1 second

## Benefits
1. **Better Planning**: Players can visualize tile placement before committing
2. **Mistake Prevention**: Reduces accidental placements
3. **Comparison**: Easy to compare different tile positions
4. **Intuitive**: Single-click to preview, double-click to confirm
