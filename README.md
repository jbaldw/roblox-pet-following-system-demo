# Roblox Pet Follower & Needs System

A modular, server-authoritative pet system featuring constraint-based physics following, lifecycle need loops, and event-driven client UI.

![Pet Demo](./pet-demo.gif)

## Architecture

- **`src/server/PetManager.luau`**: Handles pet spawning, assigns network ownership to the client for local physics smoothing, and drives loose-follow logic via `AlignPosition` and `AlignOrientation`.
- **`src/server/PetNeedsService.luau`**: Asynchronous state machine that drives random pet needs based on interval timers. Uses Roblox Attributes (`CurrentNeed`) for replication.
- **`src/server/StationService.luau`**: Validates interactions from `ProximityPrompt` stations (e.g., Food Bowl, Bed, Bathtub), clears active needs, and awards currency.
- **`src/server/LeaderStatsService.luau`**: Manages player leaderstats and coin persistence state.
- **`src/client/PetClientController.luau`**: Listens for attribute changes via `GetAttributeChangedSignal` to toggle overhead `BillboardGui` elements, and handles reward sound/visual feedback on task completion.
- **`src/shared/Configs/NeedsConfig.luau`**: Data-driven configuration defining task parameters, intervals, coin rewards, and icon asset IDs.

## Tech Highlights
- **Decoupled Architecture:** Balance variables and UI references are separated into a shared config module.
- **Performance:** Relies on event-driven attribute listeners rather than per-frame polling.
- **Authoritative Server:** Currency rewards and task validations are enforced on the server to prevent client-side exploits.
