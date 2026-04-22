# SurfShooter

A professional speedrun-focused high-skill momentum shooter combining buttery-smooth CS:GO-style surfing with tight precision shooting. Targets 800–2000+ units/second movement that feels exceptional, fully deterministic for fair leaderboards/ghost replays, and ready for competitive play.

## Features

- **CS:GO-Style Surf Physics**: Air acceleration, ramp deflection, momentum preservation with speed gain on proper angles.
- **Deterministic Simulation**: 300 Hz physics for reproducible runs, state snapshots for replays.
- **Weapon System**: Pistol and rifle with recoil affecting velocity, muzzle flash, reload, spread, visual models with sway/bob.
- **Speedrun Tools**: Millisecond timer, splits, practice mode with instant restart, checkpoints with preview.
- **Ghost Replays**: Record/playback at 300 Hz, variable speed, compression.
- **Water Interaction**: Dynamic friction and surface normals using Gerstner waves.
- **UI/Polish**: Debug overlay, full HUD, main menu, audio hooks (surf whoosh, gunfire, impacts).
- **Level**: Polished ramps, water plane with wave shader, moving targets.

## Controls

- **Movement**: WASD
- **Jump**: Space
- **Shoot**: Left Mouse
- **Reload**: R
- **Weapon Switch**: 1 (Pistol), 2 (Rifle)
- **Checkpoint Preview**: E
- **Place Checkpoint**: Right Mouse (in preview)
- **Remove Checkpoint**: Middle Mouse (in preview)
- **Practice Mode**: Toggle in menu
- **Instant Restart**: R (in practice)
- **Ghost Playback**: G
- **Debug Toggle**: F1

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