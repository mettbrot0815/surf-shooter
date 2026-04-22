# SurfShooter

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

1. Clone the repo.
2. Open in Godot 4.3+.
3. Run main.tscn.

## Project Structure

- `Scripts/`: Core systems (SurfPhysicsController, WeaponSystem, etc.)
- `Scenes/`: Player.tscn, Level.tscn, main.tscn
- `Assets/`: Models, sounds, particles

## Tuning

Adjust parameters in SurfPhysicsController for movement feel.

## Performance

<200 MB memory, 60+ FPS at high speeds. Uses multi-mesh for visuals.

## Credits

Inspired by CS:GO surf and momentum shooters.