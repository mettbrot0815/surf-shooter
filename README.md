# SurfShooter - High-Velocity Deterministic Surf Shooter

A professional speedrun-focused high-skill momentum shooter combining buttery-smooth CS:GO-style surfing with tight precision shooting. Targets 800–2000+ units/second movement that feels exceptional, fully deterministic for fair leaderboards/ghost replays, and ready for competitive play.

## Features

- **CS:GO-Style Surf Physics**: Air acceleration with camera-relative wishdir, ramp deflection with speed gain on proper angles, momentum preservation.
- **Deterministic Simulation**: 300 Hz physics for reproducible runs, full state snapshots for replays and rollback.
- **Weapon System**: Pistol and rifle with recoil affecting player velocity, deterministic spread patterns, visual weapon models.
- **Speedrun Tools**: Millisecond-precision timer, splits, practice mode with instant restart, checkpoints with preview and teleport.
- **Ghost Replays**: Record/playback at 300 Hz using state snapshots, variable speed, compression.
- **Water Interaction**: Dynamic friction and surface normals using Gerstner waves.
- **UI/Polish**: Debug overlay (velocity, speed, timer, physics), full HUD (timer, speedometer, ammo, weapon), responsive controls.
- **Level**: Basic ramps, water plane, checkpoints - ready for expansion.

## Controls

| Action | Control | Description |
|--------|---------|-------------|
| **Movement** | WASD / Arrow Keys | Move relative to camera |
| **Jump** | Space | Jump when on ground/ramp |
| **Sprint** | Shift | Increase max speed |
| **Shoot** | Left Mouse | Fire weapon |
| **Reload** | R | Reload current weapon |
| **Weapon Switch** | 1 / 2 | Switch between Pistol and Rifle |
| **Checkpoint Preview** | E | Preview next checkpoint |
| **Place Checkpoint** | Right Mouse | Place checkpoint in preview |
| **Restart from Checkpoint** | Down Arrow / S | Restart from checkpoint |
| **Practice Mode Toggle** | P | Toggle practice mode |
| **Instant Restart** | R | Instant restart in practice mode |
| **Ghost Playback** | G | Start ghost replay playback |
| **Debug Overlay (velocity)** | F1 | Toggle velocity/speed display |
| **Debug Overlay (all)** | F2 | Toggle all debug information |

## Installation

1. Clone the repo: `git clone https://github.com/mettbrot0815/surf-shooter.git`
2. Open in Godot 4.3+
3. Run `main.tscn`

## Project Structure

```
surf-shooter/
├── Scenes/
│   ├── main.tscn          # Main scene with player, HUD, UI
│   ├── Player.tscn        # Player character with physics controller
│   ├── Level.tscn         # Level with ramps and water
│   ├── HUD.tscn           # Heads-up display
│   └── UI.tscn            # Main menu
├── Scripts/
│   ├── Physics/
│   │   ├── SurfPhysicsController.gd    # Core surf physics
│   │   └── DeterministicPhysicsServer.gd   # 300Hz physics engine
│   ├── Waves/
│   │   └── WaveSystem.gd       # Procedural wave generation
│   ├── Weapons/
│   │   └── WeaponSystem.gd     # Weapon mechanics
│   ├── Replay/
│   │   └── GhostReplaySystem.gd  # Ghost replay recording/playback
│   ├── UI/
│   │   ├── HUD.gd              # In-game HUD
│   │   ├── DebugOverlay.gd     # Debug information overlay
│   │   └── MainMenu.gd         # Main menu system
│   └── SpeedrunTimer.gd        # High-precision timer
├── Assets/
│   ├── Models/                 # 3D models
│   ├── Sounds/                 # Audio files
│   └── Particles/              # Particle effects
└── Scripts/
    └── UI/
        └── CheckpointSystem.gd   # Checkpoint management
```

## Tuning

Adjust parameters in `SurfPhysicsController.gd` for movement feel:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_speed` | 320.0 | Base movement speed |
| `max_air_speed` | 350.0 | Maximum air speed |
| `sprint_speed` | 400.0 | Sprint speed boost |
| `jump_force` | 290.0 | Jump velocity |
| `ground_acceleration` | 4000.0 | Ground acceleration |
| `air_acceleration` | 1500.0 | Air acceleration |
| `ground_friction` | 6.0 | Ground friction coefficient |
| `water_friction` | 4.0 | Water friction coefficient |
| `surf_acceleration` | 2500.0 | Surf acceleration on ramps |
| `ramp_boost_factor` | 0.8 | Additional speed on optimal ramps |
| `min_ramp_angle` | 10.0° | Minimum angle for ramp detection |
| `max_ramp_angle` | 60.0° | Maximum angle for ramp detection |

## Performance

- **Memory**: <200 MB total runtime
- **Frame Rate**: 60+ FPS at 2000+ u/s
- **Physics**: 300 Hz deterministic tick rate
- **Optimization**: Uses typed code, multi-mesh for visuals

## Known Issues

- Audio uses placeholders (print statements) - needs real sound files
- Ghost replay compression partially implemented
- Level has basic ramps - needs more complex courses
- No enemy targets or scoring system yet

## Development Status

✅ **Core Movement**: CS:GO-style surfing with 300Hz deterministic physics
✅ **Weapons**: Projectile shooting with recoil, sway, ammo management
✅ **Speedrun Tools**: Timer, checkpoints, practice mode, ghost replays
✅ **UI**: HUD, debug overlay, main menu
✅ **Water Physics**: Dynamic waves with surface interaction

## Roadmap

See SURF_ROADMAP.md for detailed development progress and upcoming features.

## Credits

Inspired by CS:GO surf physics and competitive momentum shooters.
