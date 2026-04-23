# Requirements

This file is the explicit capability and coverage contract for SurfShooter.

## Active

### R001 — 300Hz Deterministic Physics with Rollback
- Class: core-capability
- Status: active
- Description: Physics engine runs at 300Hz with full rollback capability for fair speedruns
- Why it matters: Enables reproducible runs, ghost replays, and fair leaderboards
- Source: user
- Primary owning slice: S01
- Supporting slices: S02, S03, S04, S05, S06
- Validation: unmapped
- Notes: Must support rollback to any point in time

### R002 — CS:GO-Style Surf Mechanics
- Class: core-capability
- Status: active
- Description: Camera-relative air acceleration, ramp deflection with speed gain, momentum preservation
- Why it matters: Core gameplay mechanic that defines the surfing experience
- Source: user
- Primary owning slice: S02
- Supporting slices: S03, S04, S05, S06, S07, S08
- Validation: unmapped
- Notes: Must work at 2000+ u/s with smooth 60+ FPS

### R003 — Water Interaction with Gerstner Waves
- Class: core-capability
- Status: active
- Description: Procedural Gerstner waves with dynamic friction and surface normals
- Why it matters: Defines water physics and interaction with player
- Source: user
- Primary owning slice: S03
- Supporting slices: S04, S05, S06, S07, S08
- Validation: unmapped
- Notes: Must support surface normals for proper interaction

### R004 — Weapon System with Recoil
- Class: core-capability
- Status: active
- Description: Pistol and rifle with recoil affecting player velocity, deterministic spread patterns
- Why it matters: Core combat mechanic with physical consequences
- Source: user
- Primary owning slice: S04
- Supporting slices: S05, S06, S07, S08
- Validation: unmapped
- Notes: Must be deterministic for fair gameplay

### R005 — Speedrun Tools
- Class: core-capability
- Status: active
- Description: Millisecond-precision timer, instant restart, checkpoints with preview and teleport
- Why it matters: Essential for speedrunning and practice
- Source: user
- Primary owning slice: S05
- Supporting slices: S06, S07, S08
- Validation: unmapped
- Notes: Must achieve sub-millisecond timing accuracy

### R006 — Ghost Replay System
- Class: core-capability
- Status: active
- Description: 300Hz state snapshot recording for ghost replays with variable-speed playback
- Why it matters: Allows reviewing and learning from past runs
- Source: user
- Primary owning slice: S06
- Supporting slices: S07, S08
- Validation: unmapped
- Notes: Must support variable-speed playback

### R007 — UI/HUD with Visual Feedback
- Class: core-capability
- Status: active
- Description: Comprehensive HUD, debug overlay, crosshair, and visual feedback effects
- Why it matters: Essential for gameplay information and player feedback
- Source: user
- Primary owning slice: S07
- Supporting slices: S08, S09, S10
- Validation: unmapped
- Notes: Must display all gameplay-critical information

### R008 — Expandable Level Design
- Class: core-capability
- Status: active
- Description: 5-ramp level with water, checkpoints, shooting targets, and environmental hazards
- Why it matters: Provides playable content with room for expansion
- Source: user
- Primary owning slice: S08
- Supporting slices: S09, S10
- Validation: unmapped
- Notes: Must be playable and balanced

### R009 — Audio System with Placeholders
- Class: core-capability
- Status: active
- Description: Placeholder audio system ready for real sound files, visual polish (surf whoosh)
- Why it matters: Audio feedback enhances player experience
- Source: user
- Primary owning slice: S09
- Supporting slices: S10
- Validation: unmapped
- Notes: Placeholders must be functional and ready for replacement

### R010 — Documentation and Release Readiness
- Class: core-capability
- Status: active
- Description: Comprehensive documentation, release notes, and deployment preparation
- Why it matters: Enables other developers to understand and deploy the project
- Source: user
- Primary owning slice: S10
- Supporting slices: none
- Validation: unmapped
- Notes: Must be complete and readable

## Validated

## Deferred

## Out of Scope

### R011 — Multiplayer Networking
- Class: anti-feature
- Status: out-of-scope
- Description: Full multiplayer networking implementation
- Why it matters: Not part of the core scope, planned for future phases
- Source: user
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Deferred to future milestone (Phase 6+)

### R012 — Advanced AI with Pathfinding
- Class: anti-feature
- Status: out-of-scope
- Description: Full pathfinding and behavior tree AI system
- Why it matters: Not part of the core scope, planned for future phases
- Source: user
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Deferred to future milestone (Phase 6+)

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| R001 | core-capability | active | M001/S01 | S02, S03, S04, S05, S06 | mapped |
| R002 | core-capability | active | M001/S02 | S03, S04, S05, S06, S07, S08 | mapped |
| R003 | core-capability | active | M001/S03 | S04, S05, S06, S07, S08 | mapped |
| R004 | core-capability | active | M001/S04 | S05, S06, S07, S08 | mapped |
| R005 | core-capability | active | M001/S05 | S06, S07, S08 | mapped |
| R006 | core-capability | active | M001/S06 | S07, S08 | mapped |
| R007 | core-capability | active | M001/S07 | S08, S09, S10 | mapped |
| R008 | core-capability | active | M001/S08 | S09, S10 | mapped |
| R009 | core-capability | active | M001/S09 | S10 | mapped |
| R010 | core-capability | active | M001/S10 | none | mapped |
| R011 | anti-feature | out-of-scope | none | none | n/a |
| R012 | anti-feature | out-of-scope | none | none | n/a |

## Coverage Summary

- Active requirements: 10
- Mapped to slices: 10
- Validated: 0
- Unmapped active requirements: 0
- Deferred: 0
- Out of scope: 2