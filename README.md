# Pumpkin RNG

Pumpkin RNG is a multiplayer Roblox game developed using **Roblox Studio** and **Luau**. Players roll for pumpkins with different probabilities, purchase them, and place them on their plots to generate money over time.

Players can upgrade their luck, expand their pumpkin collection, protect their plots, and attempt to steal pumpkins from other players.

![Pumpkin RNG Gameplay](assets/InGameScreenshot5.PNG)

## Play the Game

**Roblox Experience:** [Play Pumpkin RNG](https://www.roblox.com/games/96643977079347/Pumpkin-RNG)

Play Pumpkin RNG directly on Roblox.

## Gameplay

- **Roll Pumpkins:** Roll for pumpkins with different probabilities, prices, and income values.
- **Purchase and Collect:** Purchase rolled pumpkins and add them to your inventory.
- **Grid-Based Placement:** Place pumpkins on your plot using a grid-based placement system. A green outline indicates a valid position, while a red outline indicates an invalid position.
- **Passive Income:** Placed pumpkins generate money over time, which players can collect.
- **Pumpkin Pickup:** Use the hammer tool to pick up previously placed pumpkins and reposition them.
- **Plot Protection:** Activate a protective barrier to prevent other players from entering your plot. An extended 20-minute barrier is also available for purchase using Robux.
- **Pumpkin Stealing:** Enter another player's unprotected plot and attempt to steal their pumpkins.
- **Luck Upgrades:** Upgrade your luck to improve your chances of rolling rarer pumpkins.
- **Progress Saving:** Player progression is saved between sessions.

## Technology

| Technology | Use in this project |
| --- | --- |
| **Roblox Studio** | Game development environment used to build the experience, create interfaces, and configure game objects. |
| **Luau** | Programming language used to implement the game's systems and gameplay logic. |
| **Roblox DataStores** | Saving player progression between gameplay sessions. |

## Gameplay Preview

https://youtu.be/cs7-2hGLkk8

## Project Documentation

This repository contains Luau source code and technical documentation explaining how the game's systems work.

For more information:

- [Game Overview](docs/01-Game-Overview.md) — An overview of the gameplay mechanics, player progression, and core features.
- [System Architecture](docs/02-System-Architecture.md) — An explanation of the game's architecture and how its major systems interact.
- [Gameplay Systems](docs/03-Gameplay-Systems.md) — A technical explanation of the rolling, inventory, placement, income, and stealing systems.

## AI-Assisted Development

The Luau code for this project was developed with assistance from **ChatGPT**.

AI-assisted development was used during the implementation of gameplay systems and programming functionality.

## Source Code

The `src/` directory contains the Luau source files used to implement the game's functionality.

**Note:** This repository showcases the Luau source code and technical documentation. The complete Roblox Studio project, including its models and other game assets, is not included.
