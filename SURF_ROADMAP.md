# SurfShooter - Development Roadmap

**Project**: High-skill momentum-based surfing shooter in Godot 4  
**Version**: 1.0  
**Status**: Pre-production (Phase 1)  
**Target Engine**: Godot 4.3+  
**Target Platform**: PC/Steam (with potential for cross-platform)

---

## 📋 Project Overview

**Core Fantasy**: "Surfing at insane speeds while landing perfect shots."

**Key Pillars**:
1. **CS:GO-style Surf Physics** - Air acceleration, wishdir, ramp behavior, velocity retention
2. **Speedrunning Focus** - Precise timers, ghost replays, deterministic runs
3. **High Skill Ceiling** - Momentum-based movement, tight shooting
4. **Vertical Flowing Design** - Levels as flowing surf parks

**Target Performance**: 800–2000+ units/second movement speed, buttery smooth gameplay

---

## 🗺️ Roadmap Structure

### Phase 1: Research & Foundation (Week 1-2)
**Status**: ✅ **CURRENT**

- [x] Research Source Engine surf physics formulas
- [x] Analyze existing Godot 4 movement implementations
- [x] Establish development environment
- [x] Create project structure

**Deliverables**:
- Research documentation
- Project architecture
- Core movement controller (prototype)

---

### Phase 2: Core Movement System (Week 3-4)
**Status**: 🚧 IN PROGRESS

**Key Tasks**:
- [ ] Implement air acceleration system (wishdir, drag, thrust)
- [ ] Create surface interaction (ramp behavior, friction)
- [ ] Develop velocity retention system
- [ ] Build momentum-based shooting mechanics

**Technical Focus**:
- Godot 4.3+ CharacterBody3D physics
- move_and_slide() optimization
- Multi-mesh for performance
- Physics determinism for replays

**Deliverables**:
- `MovementController.gd`
- `AirPhysics.gd`
- `SurfaceInteraction.gd`
- Base character scene

---

### Phase 3: Core Gameplay Loop (Week 5-6)
**Status**: ⏳ PENDING

**Key Tasks**:
- [ ] Create first surf park level
- [ ] Implement basic weapon system
- [ ] Add shooting mechanics (aim, fire, recoil)
- [ ] Integrate movement + shooting interaction

**Deliverables**:
- Playable prototype
- First level design
- Weapon system framework

---

### Phase 4: Speedrun Features (Week 7-8)
**Status**: ⏳ PENDING

**Key Tasks**:
- [ ] Implement segmented timer with splits
- [ ] Create ghost replay system
- [ ] Add checkpoint system
- [ ] Build demo recording/playback
- [ ] Develop leaderboard system (deterministic runs)

**Deliverables**:
- Timer system with accuracy
- Replay functionality
- Checkpoint network

---

### Phase 5: Polish & Optimization (Week 9-10)
**Status**: ⏳ PENDING

**Key Tasks**:
- [ ] Performance optimization (60+ FPS target)
- [ ] Visual polish (particle effects, lighting)
- [ ] Audio integration (surf sounds, gunfire)
- [ ] UI/UX refinement
- [ ] Bug fixing and stability

**Deliverables**:
- Optimized game build
- Audio/visual polish
- Final UI systems

---

### Phase 6: Pre-Release & Testing (Week 11-12)
**Status**: ⏳ PENDING

**Key Tasks**:
- [ ] Internal QA testing
- [ ] Speedrun community feedback
- [ ] Performance stress testing
- [ ] Balance tuning
- [ ] Build for target platforms

**Deliverables**:
- Beta build
- QA report
- Final balance patch

---

## 🏗️ Architecture Overview

```
SurfShooter
├── Player/
│   ├── CharacterBody3D
│   │   ├── MovementController.gd
│   │   ├── AirPhysics.gd
│   │   ├── SurfaceInteraction.gd
│   │   └── SpeedrunManager.gd
│   ├── WeaponSystem.gd
│   ├── InputHandler.gd
│   └── CharacterModel
├── Levels/
│   ├── SurfPark.gd
│   ├── LevelManager.gd
│   └── CheckpointSystem.gd
├── Systems/
│   ├── TimerSystem.gd
│   ├── ReplaySystem.gd
│   └── LeaderboardSystem.gd
└── Resources/
    ├── Audio/
    ├── Animations/
    └── Materials/
```

---

## 🎯 Key Technical Challenges & Solutions

### 1. Physics Determinism
**Challenge**: Godot's physics can be non-deterministic, breaking ghost replays.  
**Solution**: Use deterministic physics (Spatial/GDScript), fixed timestep, seed randomizers.

### 2. Air Physics Fidelity  
**Challenge**: Replicating Source engine's complex air acceleration.  
**Solution**: Implement custom physics body with thrust vectors, drag calculation, and wishdir system.

### 3. Performance at High Speeds
**Challenge**: Maintaining 800+ units/s without slowdown or physics issues.  
**Solution**: Multi-mesh optimization, collision layer tuning, physics substeps.

### 4. Input Latency
**Challenge**: Competitive play requires instant response.  
**Solution**: Direct input to physics, no interpolation, lock player rotation.

---

## 📊 Development Progress Tracking

| Phase | Status | Progress | Notes |
|-------|--------|----------|-------|
| Phase 1: Research | ✅ Complete | 100% | Research complete, citations gathered |
| Phase 2: Core Movement | 🚧 In Progress | 40% | Core systems implemented |
| Phase 3: Gameplay Loop | ⏳ Pending | 0% | Next major milestone |
| Phase 4: Speedrun | ⏳ Pending | 0% | - |
| Phase 5: Polish | ⏳ Pending | 0% | - |
| Phase 6: Pre-Release | ⏳ Pending | 0% | - |

---

## 📝 Next Milestone: Core Movement System

**Goal**: Deliver a fully functional movement controller that replicates Source engine surf physics with Godot 4's CharacterBody3D.

**Key Components**:
1. `AirPhysics.gd` - Air acceleration, drag, thrust
2. `SurfaceInteraction.gd` - Friction, ramp behavior
3. `MovementController.gd` - Main control logic

**Success Criteria**:
- Smooth 100+ units/s movement
- Air acceleration feels like Source engine
- Ramp boosting works correctly
- Velocity retention on surfaces

---

## 🤝 Team & Communication

- **Lead Developer**: Movement Systems Expert
- **Playtesters**: Speedrunning community
- **Engine**: Godot 4.3+

---

## 📅 Timeline

- **Day 1-7**: Research Phase (Current)
- **Day 8-14**: Core Movement Implementation
- **Day 15-21**: Gameplay Loop
- **Day 22-28**: Speedrun Features
- **Day 29-35**: Polish & Optimization
- **Day 36-42**: Pre-Release Testing

**Current Date**: Day 7 - Research Phase Complete, moving to Core Movement

---

## 🧪 Testing Protocol

- [ ] Physics consistency (50+ test runs)
- [ ] Performance benchmark (30+ FPS at target speed)
- [ ] Input latency measurement (<16ms)
- [ ] Determinism verification (replay match)

---

## 📚 References & Resources

- **Source Engine Physics**: [CS:GO Source Files](https://github.com/alliedmodders/csgo)
- **Godot 4 Physics**: [Godot Docs](https://docs.godotengine.org/en/4.x/)
- **Movement Systems**: [Advanced Godot Character Controllers](https://github.com/godotengine/godot/tree/master/editor/plugins)
- **Speedrunning Standards**: [Speedrun.com Godot Games](https://www.speedrun.com/category/godot)

---

**Last Updated**: 2026-04-22  
**Version**: 1.2  
**Maintained By**: Development Team
