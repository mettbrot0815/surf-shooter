# SurfShooter

A professional speedrun-focused high-skill momentum shooter combining buttery-smooth CS:GO-style surfing with tight precision shooting. Targets 800–2000+ units/second movement that feels exceptional, fully deterministic for fair leaderboards/ghost replays, and ready for competitive play.

## Features

- **CS:GO-Style Surf Physics**: Air acceleration with camera-relative wishdir, ramp deflection with speed gain on proper angles, momentum preservation.
- **Deterministic Simulation**: 300 Hz physics for reproducible runs, full state snapshots for replays and rollback.
- **Weapon System**: Pistol and rifle with recoil affecting player velocity, deterministic spread patterns, weapon sway/bob, visual weapon models.
- **Speedrun Tools**: Millisecond-precision timer, splits, practice mode with instant restart, checkpoints with preview and teleport.
- **Ghost Replays**: Record/playback at 300 Hz using state snapshots, compression, variable speed support.
- **Water Interaction**: Dynamic friction and surface normals using Gerstner waves with depth-based physics.
- **UI/Polish**: Debug overlay (velocity, speed, timer, physics), full HUD (timer, speedometer, ammo, weapon), main menu, responsive controls.
- **Testing Suite**: Comprehensive automated tests for determinism, performance, weapons, water, and surfing mechanics.
- **Level**: Multiple angled ramps, water plane, WaveSystem integration - ready for expansion.

## Controls

- **Movement**: WASD / Arrow Keys
- **Jump**: Space
- **Sprint**: Shift
- **Shoot**: Left Mouse
- **Reload**: R
- **Weapon Switch**: 1 (Pistol), 2 (Rifle)
- **Checkpoint Preview**: E
- **Place Checkpoint**: Right Mouse (in preview)
- **Restart from Checkpoint**: Down Arrow / S
- **Practice Mode Toggle**: P
- **Instant Restart**: R (in practice mode)
- **Ghost Playback**: G (if available)
- **Debug Overlay**: F1 (velocity/speed), F2 (all debug)

## Installation

1. Clone the repo: `git clone https://github.com/mettbrot0815/surf-shooter.git`
2. Open in Godot 4.3+.
3. Run main.tscn.

## Project Structure

- `Scripts/`: Core systems (SurfPhysicsController, WeaponSystem, etc.)
- `Scenes/`: Player.tscn, Level.tscn, main.tscn
- `Assets/`: Models, sounds, particles

## Tuning

Adjust parameters in SurfPhysicsController for movement feel:
- `max_speed`: Base movement speed (320 default)
- `surf_acceleration`: Surf acceleration on ramps (2500)
- `ramp_boost_factor`: Speed gain on optimal ramp angles (0.8)
- `ground_acceleration`: Ground acceleration (4000)
- `air_acceleration`: Air acceleration (1500)

## Performance

<200 MB memory, 60+ FPS at high speeds. Uses multi-mesh for visuals.

## Known Issues

- Audio uses placeholders (print statements) - needs real sound files
- Ghost replay compression partially implemented
- Level has basic ramps - needs more complex courses
- No enemy targets or scoring system yet

## Development Status

✅ **Phase 1**: Core Movement - CS:GO-style surfing with 300Hz deterministic physics
✅ **Phase 2**: Weapons System - Projectile shooting with recoil, sway, ammo management
✅ **Phase 3**: Testing & Integration - Comprehensive test suite, all systems verified
🔄 **Phase 4**: Audio & Polish - Sound implementation, level expansion, final touches

**Current Branch**: `phase3-debugging` (pushed to remote)
**Test Status**: Full integration verified, ready for gameplay testing

## Quick Start Testing

1. Open `Scenes/DebugMain.tscn` in Godot
2. Run the scene to execute automated test suite
3. Check console for test results (should show 5/5 passed)
4. Use `Scenes/main.tscn` for normal gameplay

## Roadmap

See SURF_ROADMAP.md for detailed development progress and upcoming features.

## Credits

Inspired by CS:GO surf physics and competitive momentum shooters.