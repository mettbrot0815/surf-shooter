# SurfShooter

**Active Milestone:** M001 — Core Implementation & Core Systems (Phases 1-5)

## What This Is

SurfShooter is a high-velocity deterministic surf shooter game built in Godot 4.x, combining:

- **CS:GO-style surfing physics**: Air acceleration with camera-relative movement, ramp deflection with speed gain, momentum preservation
- **300Hz deterministic physics**: For reproducible runs, ghost replays, and fair leaderboards
- **Weapon system**: Pistol and rifle with recoil affecting player velocity
- **Speedrun tools**: Millisecond-precision timer, splits, checkpoints with preview
- **Ghost replay system**: 300Hz recording/playback with variable-speed control

## Core Value

**The one thing that must work**: 300Hz deterministic physics with full rollback capability that enables fair, reproducible speedruns.

## Current State

**Version 0.7** — Phase 4 Complete, Phase 5 (Deployment) In Progress

### Completed Systems:
- ✅ 300Hz deterministic physics engine with rollback
- ✅ CS:GO-style surf movement and ramp mechanics
- ✅ Water interaction with Gerstner waves
- ✅ Weapon system with recoil and sway
- ✅ Speedrun tools (timer, checkpoints, practice mode)
- ✅ Ghost replay system
- ✅ Full UI/HUD with debug overlay
- ✅ 5-ramp level with environmental features
- ✅ Audio placeholders and visual polish

### In Progress:
- 🔄 Phase 5: Deployment & Distribution
  - Audio placeholders ready for real files
  - Visual feedback system implemented
  - Documentation enhanced

## Architecture / Key Patterns

### Tech Stack
- **Engine**: Godot 4.x
- **Physics**: 300Hz deterministic stepping with rollback
- **Water**: Gerstner waves with dynamic normals
- **Weapons**: Recoil-based projectile system
- **Timer**: Millisecond-precision timing

### Key Conventions
- **Movement**: Camera-relative wish direction
- **Physics**: 300Hz tick rate, state snapshots for rollback
- **UI**: Debug overlay + HUD, crosshair-focused
- **Level**: Expandable ramp system with checkpoints

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [ ] M001: Core Implementation & Core Systems (Phases 1-5) — Deliver complete, playable surf shooter with all core features through deployment preparation

## Requirements Coverage

| ID | Title | Status | Owner | Source |
|---|-------|--------|-------|--------|
| R001 | 300Hz deterministic physics with rollback | active | M001/S01 | user |
| R002 | CS:GO-style surf mechanics | active | M001/S02 | user |
| R003 | Water interaction with Gerstner waves | active | M001/S03 | user |
| R004 | Weapon system with recoil | active | M001/S04 | user |
| R005 | Speedrun tools (timer, checkpoints) | active | M001/S05 | user |
| R006 | Ghost replay system | active | M001/S06 | user |
| R007 | UI/HUD with visual feedback | active | M001/S07 | user |
| R008 | Expandable level design | active | M001/S08 | user |
| R009 | Audio system with placeholders | active | M001/S09 | user |
| R010 | Documentation and release readiness | active | M001/S10 | user |

## Project Notes

### Key Decisions Made
- **Physics Tick Rate**: 300Hz for deterministic simulation
- **Ramp Friction**: 0.3x on ramps for speed
- **Water Friction**: 4.0 coefficient with dynamic surface normals
- **Audio**: Placeholder system for future real audio files

### Known Limitations
- Audio uses placeholders (print statements) - needs real sound files
- Level has basic ramps - needs more complex courses
- No enemy targets or scoring system yet

---
**Last Updated**: 2026-04-23
**Maintained By**: GSD Auto-Mode