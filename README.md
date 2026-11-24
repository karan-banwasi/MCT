<div align="center">

<img src="MCT_Logo.png" alt="MetaCompletionTracker Logo" width="220" />

# MetaCompletionTracker (MCT)

**A World of Warcraft addon for tracking nested criteria, missing requirements, and active World Quests across expansion-wide and custom meta-achievements.**

[![GitHub Release](https://img.shields.io/github/v/release/karan-banwasi/MCT?style=flat-square)](https://github.com/karan-banwasi/MCT/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/karan-banwasi/MCT/ci.yml?branch=main&label=CI&style=flat-square)](https://github.com/karan-banwasi/MCT/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![WoW Retail](https://img.shields.io/badge/WoW%20Retail-12.1.5%20(Midnight)-purple?style=flat-square)](MetaCompletionTracker.toc)
[![CurseForge](https://img.shields.io/badge/CurseForge-MetaCompletionTracker-orange?style=flat-square)](https://www.curseforge.com/wow/addons/meta-completion-tracker)

</div>

---

## Key Features

- **Recursive Criteria Tree (Up to 5 Levels Deep)** — Drill cleanly from expansion super-metas down through zone metas, sub-achievements, and individual quest, kill, or exploration requirements.
- **Expansion & Zone Presets** — Two-tier navigation across *Battle for Azeroth*, *Shadowlands*, *Dragonflight*, *The War Within*, *Midnight*, and *World Events*.
- **Custom Achievement & Link Tracking** — Enter any achievement ID or paste an in-game achievement link into the **Custom ID** box (or pass an ID to `/mct`) to inspect any meta-achievement on demand.
- **Live World Quest Tracking & Alert Bar** — Highlights when a required World Quest is currently up (with remaining time, zone map navigation, Shift-click objective tracking, and practical completion notes) or shows offline WQ requirements.
- **Right-Click Wowhead Link Copy** — Right-click any meta-achievement, sub-achievement, criteria row, or World Quest badge to open a quick-copy dialog with the corresponding Wowhead URL.
- **Native Blizzard UI Integration** — Left-click achievements to open them in the Blizzard Achievement UI, Shift-click or click the pin icon to toggle Objective Tracker pinning, and toggle **Hide Done** to focus only on remaining criteria.

---

## Slash Commands

| Command | Description |
| :--- | :--- |
| `/mct` | Toggle the MetaCompletionTracker window |
| `/mct <achievementID>` | Open and load a specific achievement by numeric ID (e.g. `/mct 61451`) |
| `/mct reset` | Reset saved preferences, filter state, and window position |
| `/hidemct` | Hide the MetaCompletionTracker window |

---

## Supported Presets

| Expansion | Achievement | ID | Category | Reward |
| :--- | :--- | :--- | :--- | :--- |
| **Battle for Azeroth** | A Farewell to Arms | `40953` | Expansion Super-Meta | *Jani's Trashpile* (Mount) |
| **Battle for Azeroth** | Mecha-Done | `13541` | Zone Super-Meta | *Keys to the Model W* (Mount) |
| **Battle for Azeroth** | Undersea Usurper | `13638` | Zone Super-Meta | *Snapback Scuttler* (Mount) |
| **Battle for Azeroth** | Two Sides to Every Tale | `13517` | Faction Campaign | *Bloodflank Charger & Ironclad Frostclaw* (Mounts) |
| **Shadowlands** | Back from the Beyond | `20501` | Expansion Super-Meta | *Zovaal's Shadebeast Collar* (Mount) |
| **Dragonflight** | A World Awoken | `19458` | Expansion Super-Meta | *Taivan* (Mount) |
| **The War Within** | Worldsoul-Searching | `61451` | Expansion Super-Meta | *Geargrinder Mk. 11* (Mount) & *Drained Dark Heart of Galakrond* (Decor) |
| **The War Within** | Khaz Algar Diplomat | `40537` | Expansion Meta | *Renown Progress* |
| **Midnight** | Light Up the Night | `62386` | Expansion Super-Meta | *Brilliant Petalwing* (Mount) |
| **Midnight** | Assault the Vault | `63630` | Zone Super-Meta | *Venomous Coiler* (Mount) |
| **Midnight** | Bane of the Swarm | `64150` | Zone Super-Meta | *Bane of the Swarm* (Title) |
| **World Events** | What a Long, Strange Trip It's Been | `2144` | Holiday Super-Meta | *Reins of the Violet Proto-Drake* (310% Mount) |

---

## Installation

### CurseForge (Recommended)
Install directly via the CurseForge app or download from the [MetaCompletionTracker CurseForge page](https://www.curseforge.com/wow/addons/meta-completion-tracker).

### GitHub Releases
1. Download `MetaCompletionTracker-v*.zip` from the [GitHub Releases](https://github.com/karan-banwasi/MCT/releases) page.
2. Extract the archive so the `MetaCompletionTracker` folder sits directly inside your WoW Retail AddOns directory:
   - **Windows**: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\MetaCompletionTracker`
   - **macOS**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/MetaCompletionTracker`
3. Restart World of Warcraft or type `/reload` in-game.

### Manual (From Source)
Clone this repository and copy `MetaCompletionTracker.toc`, `Presets.lua`, `WorldQuests.lua`, `AchievementEngine.lua`, `MCT.lua`, and `LICENSE` into `<WoW>\_retail_\Interface\AddOns\MetaCompletionTracker\`.

---

## Local Development Workflow

1. Clone the repository:
   ```powershell
   git clone https://github.com/karan-banwasi/MCT.git
   cd MCT
   ```
2. Deploy addon files to your local Retail client using the helper script (edit `$destinationPath` inside [`move.ps1`](move.ps1) if WoW is installed on another drive):
   ```powershell
   .\move.ps1
   ```
3. Run `/reload` in World of Warcraft to test changes live.
4. Before opening a pull request, lint the Lua codebase with `luacheck` using the repository's [`.luacheckrc`](.luacheckrc):
   ```bash
   luacheck .
   ```

---

## Contributing & Security

- Contributions, bug reports, and new World Quest or expansion preset mappings are welcome! See [`CONTRIBUTING.md`](CONTRIBUTING.md).
- To report a security issue, see [`SECURITY.md`](SECURITY.md).
- Licensed under the [MIT License](LICENSE).
