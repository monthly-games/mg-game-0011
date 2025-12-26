# MG-0011: Fairy Forest

> **Genre:** Idle/Healing  
> **Platform:** Android / iOS / Web  
> **Engine:** Flutter + Flame

## Overview

Relaxing fairy forest idle game

## Tech Stack

- **Framework:** Flutter 3.x
- **Game Engine:** Flame 1.x
- **State Management:** Riverpod
- **Common Library:** mg_common_game (submodule)

## Project Structure

```
mg-game-0011/
├── game/                    # Main game project
│   ├── lib/
│   │   ├── game/           # Game logic
│   │   ├── features/       # Feature modules
│   │   └── ui/             # UI components
│   └── assets/             # Game assets
├── libs/                    # Shared libraries (submodules)
│   ├── mg_common_game/     # Common game utilities
│   ├── mg_common_analytics/
│   ├── mg_common_backend/
│   └── mg_common_infra/
└── common/                  # Legacy common module
```

## Getting Started

```bash
# Clone with submodules
git clone --recursive https://github.com/monthly-games/mg-game-0011.git

# Install dependencies
cd game
flutter pub get

# Run
flutter run
```

## Features

- [x] Core gameplay
- [x] Gacha system
- [x] BattlePass system
- [x] VFX effects
- [x] Audio system
- [ ] Leaderboards
- [ ] Cloud save

## License

MIT License - Monthly Games Portfolio Project
