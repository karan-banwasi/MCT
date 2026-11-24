# Contributing to MetaCompletionTracker

Thanks for helping improve **MetaCompletionTracker**!

## Ways to Contribute

- **Bug Reports**: Open an issue with your WoW client version, the achievement ID you were viewing, steps to reproduce, and any Lua stack trace (e.g., from BugSack or `/console scriptErrors 1`).
- **New Presets & World Quest Mappings**: Include the exact Wowhead **Achievement ID**, **Quest ID(s)** (plus `altQuestIDs` if rotating), **Map ID**, and concise completion notes so they can be verified in-game.
- **Code Improvements**: Open a pull request against `main` with clear, focused changes.

## Local Testing & Linting

1. Sync files into your local World of Warcraft `_retail_\Interface\AddOns\MetaCompletionTracker` directory (update `$destinationPath` in `move.ps1` if your installation lives elsewhere):
   ```powershell
   .\move.ps1
   ```
2. In-game, run `/reload` and verify `/mct`, preset switching, and custom achievement IDs produce zero Lua errors.
3. Run `luacheck .` locally if installed; every PR is also checked automatically by GitHub Actions (`.github/workflows/ci.yml`), which runs `luacheck`, validates `MetaCompletionTracker.toc`, and tests addon zip packaging.
