# A Difficult Game About Becoming an AI

> Climb a suspicious AI tower. Trust literally nothing.

We made this for HackClub Haven(Ahmedabad) **Bounce Back** theme. You are Epoch 0.1, a tiny cursor-bot trying to climb an AI training tower and reach the shiny neural core at the top. Sounds normal enough, except the tower is kinda a liar. Some platforms vanish, some checkpoints are definitely not helping, and even the summit might be messing with you.

## Theme: Bounce Back

The main idea was simple: you fall, get annoyed, figure out why it happened, and go again. There is no big game-over speech. You just land lower down and have to climb back. Somtimes the thing you learnt is useful. Somtimes it is just that the game was being rude.

## Features

- Hold-to-charge jumping, air steering, coyote time, wall bounces, camera shake, and a little bonk feedback when things go bad.
- Four chunks of tower: Input Layer, GPU Fan Wind, Cryo Slide and Dropout, and Hallucination Crown.
- Wind, slippery ice, altered gravity, and controls that flip when you probaly need them most.
- Falling platforms, fake platforms, fake checkpoints, moving gears, a decoy summit, and one real finish. Maybe.
- Home screen, pause screen, restart button, HUD, subtitles, music, sound effects, and a narrator that is not really on your side.
- A falling scream that has about a one-in-three chance of happening on a big enough fall.
- If the scream cuts off another voice line, it gets played after instead of just disappearing.

## Controls

| Action | Keys |
| --- | --- |
| Charge and release a jump | `Space`, `W`, or `Up Arrow` |
| Move and steer | `A` / `D` or `Left Arrow` / `Right Arrow` |
| Pause or resume | `Esc` or `P` |

### Debug shortcuts

These are mostly here so we can check the whole tower without having to rage-climb it every single time.

| Key | Result |
| --- | --- |
| `1` | Teleport to Layer 1 |
| `2` | Teleport to Layer 2 |
| `3` | Teleport to Layer 3 |
| `4` | Teleport to Layer 4 |
| `5` | Start a long-fall audio test |

## Play at

https://hyper10203.itch.io/a-difficult-game-about-becoming-an-ai


## How it is built

The project is in GDScript and is mostly a few reusable Godot scenes plus scripts that do a lot of the weird stuff while the game is running.

| File or scene | Responsibility |
| --- | --- |
| `scenes/World.tscn` | Main game scene containing the player instance, background and HUD. |
| `scripts/WorldBuilder.gd` | Builds the tower, platforms, traps, backgrounds, menus, HUD updates, and narration zones at runtime. |
| `scenes/Player.tscn` and `scripts/Player.gd` | Implements the `CharacterBody2D` player, charged jumps, collision-based movement, layer effects, fall detection, knockback, animation, and camera shake. |
| `scenes/SpinningGear.tscn` and `scripts/SpinningGear.gd` | Reusable moving gear hazard with rotation, an `Area2D` teeth hitbox, and directional knockback. |
| `scripts/VoiceManager.gd` | Global audio and subtitle manager for narrator lines, effects, music, the falling scream, cooldowns, and queued dialogue. |

`WorldBuilder.gd` builds most of the tower from code, so we did not have to place every little ledge by hand in the editor. A normal ledge is basically a `StaticBody2D` with tile sprites and collision. A collapsing ledge also has an `Area2D` and a tween, so it shakes a bit, drops you, then eventually comes back. Fake platforms, fake checkpoints, and narrator zones work in a similar way.

The player uses `CharacterBody2D` and `move_and_slide()` so the movement does not completely fall apart around collisions. Holding jump builds charge for `0.80` seconds. Keep holding until `1.50` seconds and it backfires, which is very funny when it happens to someone else. The same script checks the player's height to decide when wind, ice, and upside-down controls should start happening.

## Audio and feedback

`VoiceManager` is an autoload, so the gameplay code can ask for sounds without needing to pass an audio node around everywhere. It has separate players for the narrator, normal sound effects, the falling scream, and music. It also puts captions in a `CanvasLayer`, so the text stays on screen while the camera goes up the tower.

Fall lines depend on how far you dropped. The bigger ones have cooldowns so the game does not just yell at you nonstop. A qualifying fall gets one 33% roll for the scream. If the scream cuts somebody off, that line is kept in a small queue and plays after it finishes.

The audio was made by the team members.

## AI assistance declaration

We used AI as a coding and debugging helper while making the project. Mostly it helped us think through some GDScript, find bugs in the movement, menu, and audio logic, and suggest things to test when the game was acting strange.

The final choices, integration, assets, and testing were still done by the project team. AI suggestions were reviewed before being kept.

## Assets and attribution

The art is either custom project stuff or from public and open-license asset repos. The cursor-bot sprites are in `assets/player/`. The environment, tiles, hazards, and backgrounds came from modular public/open-license sources that are listed in the bibliography.

See [ASSET_BIBLIOGRAPHY.md](ASSET_BIBLIOGRAPHY.md) for the full source links and licence references.

## Project structure

```text
a_difficult_game_about_becoming_an_ai/
├── assets/       Pixel-art player, tiles, gears, backgrounds and home-screen logo
├── audio/        Music, sound effects and narrator voice lines
├── compressed/   Optional compressed audio variants
├── scenes/       World, Player and SpinningGear scenes
├── scripts/      WorldBuilder, Player, SpinningGear and VoiceManager scripts
├── ASSET_BIBLIOGRAPHY.md
└── project.godot
```
