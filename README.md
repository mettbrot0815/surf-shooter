# SurfShooter - High-Skill Momentum Shooter in Godot 4

A professional speedrun-focused high-skill momentum shooter in Godot 4.3+ that combines CS:GO-style surfing movement with precision shooting mechanics.

## Features

### Core Movement System
- **Source Engine Physics**: Accurate implementation of CS:GO-style surf mechanics
  - Air acceleration with wishdir (mouse input while airborne)
  - Surf ramp deflection (velocity perpendicular to ramp surface)
  - Ground friction and air resistance
  - Momentum preservation at 300Hz physics rate

### Speedrun Features
- **Precise Segmented Timer**: Millisecond-accurate timing with splits
- **Ghost Replay System**: Deterministic replay recording at 300Hz
- **Practice Mode**: Instant restart from checkpoints
- **Checkpoint System**: Place checkpoints anywhere for instant recovery

### Shooting Mechanics
- **Weapon System**: Pistol and Rifle with:
  - Recoil patterns and spread
  - Muzzle flash and visual effects
  - Fire rate limiting
  - Magazine and reload mechanics

### Physics & Performance
- **300Hz Physics Engine**: Deterministic simulation for consistent gameplay
- **State Snapshots**: Full physics state for rollback and replays
- **Wave System**: Procedural multi-layer Gerstner waves for realistic water surface

## Project Structure

```
SurfShooter/
├── Scenes/
│   ├── main.tscn           # Main game scene
│   ├── Player.tscn         # Player character scene
│   ├── Level.tscn          # Level with ramps and water
│   ├── UI.tscn             # HUD and debug overlay
│   └── Weapon.tscn         # Weapon mesh scene
├── Scripts/
│   ├── Physics/
│   │   ├── SurfPhysicsController.gd     # Core surf movement
│   │   └── DeterministicPhysicsServer.gd  # 300Hz physics engine
│   ├── Waves/
│   │   └── WaveSystem.gd        # Procedural wave generation
│   ├── Timer/
│   │   └── SpeedrunTimer.gd     # Professional timing system
│   ├── Replay/
│   │   └── GhostReplaySystem.gd # Ghost replay recording
│   ├── UI/
│   │   ├── DebugOverlay.gd      # Debug information display
│   │   └── CheckpointSystem.gd  # Checkpoint management
│   └── Weapons/
│       └── WeaponSystem.gd       # Shooting mechanics
└── Resources/              # Additional assets
```

## Installation

1. **Clone or download** this project
2. **Open in Godot 4.3+**: Open `SurfShooter/` in Godot Editor
3. **Run**: Select `main.tscn` and press Play

## Controls

| Key | Action |
|-----|--------|
| WASD | Move (wishdir - horizontal movement) |
| Space | Jump |
| Left Click | Fire weapon |
| Right Click | Cycle weapons |
| RMB | Restart from checkpoint |
| E | Toggle checkpoint preview |
| Z | Place checkpoint (in preview mode) |
| X | Remove checkpoint (in preview mode) |
| C | Cycle checkpoints |
| F1 | Show velocity debug |
| F2 | Show all debug info |

## Physics Tuning

Key tunable parameters in `SurfPhysicsController.gd`:

```gdscript
@export var max_speed: float = 320.0          # Max ground speed
@export var air_acceleration: float = 1500.0   # Air acceleration
@export var ground_friction: float = 6.0       # Ground friction
@export var water_friction: float = 4.0        # Water/surf friction
@export var surf_acceleration: float = 2500.0  # Surf acceleration
@export var surf_max_velocity: float = 6000.0  # Max surf speed
```

## Technical Details

### Deterministic Physics (300Hz)
- Fixed timestep simulation for consistent player experience
- State snapshots enable rollback and anti-cheat
- Network synchronization at 60Hz (5:1 physics:network ratio)

### Wave System
- Multi-layer Gerstner waves for realistic water surface
- Dynamic friction based on water depth
- Visual surface normals for lighting

### Ghost Replay
- Frame-accurate recording at 300Hz
- Compression support for smaller files
- Variable speed playback (0.5x - 3.0x)

## Performance Targets

| Metric | Target |
|--------|--------|
| Physics Tick Rate | 300 Hz |
| Physics Step | 3.33ms |
| Memory Usage | <200MB |
| Network Sync | 60 Hz |
| Rollback Buffer | 150 ticks (500ms) |

## Contributing

This project follows these design principles:

1. **Deterministic Physics**: All physics must be deterministic for consistent multiplayer
2. **Performance First**: Optimized for high tick rates and low memory
3. **Clean Code**: Modular, well-commented GDScript following Godot 4 best practices
4. **Production Quality**: Ready for competitive speedrunning from day one

## License

This project is MIT Licensed - feel free to use and modify!

## Credits

- **Physics System**: Based on Source Engine surf physics (Valve)
- **Godot 4**: Official Godot 4.3+ engine
- **Design**: Competitive speedrunning community standards

## Known Issues

- **Checkpoint Placement**: Must be in preview mode (E key) to place checkpoints
- **Wave System**: Water interaction currently uses raycasting; DOTS version coming soon
- **Weapon Switching**: Right-click weapon switching is functional but needs visual feedback

## Roadmap

- [ ] DOTS physics backend for better performance
- [ ] Multiplayer networking with authoritative server
- [ ] Additional weapons (SMG, Shotgun)
- [ ] Level editor for custom track creation
- [ ] Replay sharing system
- [ ] Achievements and leaderboards

---

**Enjoy your high-velocity surf run!** 🏄‍♂️⚡
