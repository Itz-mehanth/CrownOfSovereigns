---
description: Guide to converting the Carcassonne project to Augmented Reality (AR) using Godot 4 and OpenXR.
---

# AR Conversion Guide (Godot 4 + OpenXR)

This workflow outlines the steps to convert the existing 3D Carcassonne game into a tabletop AR experience where the board is placed on a real-world surface.

## 1. Prerequisites & Setup

### Install OpenXR Loaders
1.  Open Godot Asset Library.
2.  Search for **"Godot OpenXR Loaders"**.
3.  Download and install the plugin.
4.  Go to **Project > Project Settings > Plugins** and enable it.

### Android Export Setup (for ARCore)
1.  Go to **Project > Export**.
2.  Add an **Android** preset.
3.  **Gradle Build**: Enable "Use Gradle Build".
4.  **Permissions**: Check the following:
    *   `Camera`
    *   `Internet` (optional, but often needed)
5.  **XR Features**:
    *   **XR Mode**: Select `OpenXR`.
    *   **Immersive Mode**: Checked.

## 2. Scene Restructuring

The current scene uses a static `Camera3D` with orbit controls. In AR, the camera IS the device.

1.  **Create a New Root Node**:
    *   Create a `Node3D` named `ARWorldOrigin`.
2.  **Add XR Nodes**:
    *   Add `XROrigin3D` as a child of `ARWorldOrigin`.
    *   Add `XRCamera3D` as a child of `XROrigin3D`.
    *   *Delete or Disable the existing `Camera3D`.*
3.  **Create a Board Container**:
    *   Create a `Node3D` named `BoardRoot` as a child of `ARWorldOrigin`.
    *   **Move all game objects** (Tiles, UI, Lights, etc.) that should be part of the game world into `BoardRoot`.
    *   *Crucial*: The `BoardRoot` will be the object we move, rotate, and scale to place on the table.

## 3. Scaling for AR (The "Giant Tile" Problem)

Godot's physics engine uses **1 unit = 1 meter**.
*   **Current Tile Size**: ~90 units (90 meters!).
*   **Target Tile Size**: ~0.1 units (10 cm).

**Action**:
*   Set the `scale` of `BoardRoot` to `Vector3(0.001, 0.001, 0.001)`.
*   This scales your 90m tiles down to 9cm, perfect for a tabletop.

## 4. Script Modifications (`main.gd`)

You need to modify `main.gd` to handle AR initialization and board placement instead of camera orbiting.

### A. Initialization (`_ready`)

```gdscript
var xr_interface: XRInterface
var board_placed: bool = false

func _ready():
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        get_viewport().use_xr = true
        
        # Enable Passthrough (See the real world)
        var modes = xr_interface.get_supported_environment_blend_modes()
        if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
            xr_interface.set_environment_blend_mode(XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND)
            get_viewport().transparent_bg = true
    else:
        print("OpenXR not initialized (Running in Editor?)")
```

### B. Input Handling (`_input`)

Replace the orbit/pan logic with placement logic.

```gdscript
func _input(event):
    if event is InputEventScreenTouch and event.pressed:
        if not board_placed:
            _try_place_board(event.position)
        else:
            # Pass input to your existing tile logic
            _handle_tile_touch(event.position)

func _try_place_board(screen_pos):
    # Raycast against the AR Plane Manager's collision mask
    var camera = $XROrigin3D/XRCamera3D
    var from = camera.project_ray_origin(screen_pos)
    var to = from + camera.project_ray_normal(screen_pos) * 10.0
    
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2 # Assume Layer 2 is for AR Planes
    
    var result = space_state.intersect_ray(query)
    if result:
        # Move the board to the hit position
        $BoardRoot.global_position = result.position
        
        # Optional: Rotate to face user
        var look_dir = camera.global_position
        look_dir.y = result.position.y
        $BoardRoot.look_at(look_dir, Vector3.UP)
        $BoardRoot.rotate_y(PI) # Flip if needed
        
        board_placed = true
        print("Board placed at: ", result.position)
```

## 5. Plane Detection

To detect tables, you need an **XRPlaneTracker** or similar functionality provided by ARCore.

1.  **Add `XRAnchor3D`**: (Optional) For more stable tracking.
2.  **Enable Plane Detection**: In Project Settings > XR > OpenXR, ensure "Plane Detection" is enabled if available.
3.  **Visualizing Planes**: You might need a helper script to generate collision meshes for detected planes so your raycast has something to hit.
    *   *Note*: Godot 4.2+ has improved AR plane support. Check the latest docs for `XRPlane3D`.

## 6. Lighting

*   **DirectionalLight3D**: Keep it, but set `Shadow Mode` to `PSSM 2 Splits` or lower for mobile performance.
*   **Environment**: Use a `CameraAttributesPhysical` for auto-exposure to match the real world brightness roughly.

## 7. Testing

1.  Connect your Android device via USB.
2.  Click the **Android** icon in the top right of Godot editor ("Remote Debug").
3.  The app should launch.
4.  **Scan the floor/table** (move phone around).
5.  **Tap** to place the board.
6.  **Play** as normal (tap tiles to select, etc.).

## Checklist for Conversion

- [ ] Install OpenXR Loaders Plugin.
- [ ] Configure Android Export (OpenXR Mode).
- [ ] Replace `Camera3D` with `XROrigin3D` + `XRCamera3D`.
- [ ] Group game content under `BoardRoot`.
- [ ] Scale `BoardRoot` to `0.001`.
- [ ] Update `main.gd` to initialize XR and Passthrough.
- [ ] Implement "Tap to Place" logic.
- [ ] Remove Orbit Camera logic (yaw/pitch/zoom).
