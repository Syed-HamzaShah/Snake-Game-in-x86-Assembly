# Snake Game in x86 Assembly (MASM & Irvine32)

A classic Snake game implemented in x86 Assembly Language using MASM and the **Irvine32 library**, built for educational and nostalgic DOS/console gameplay.

> ⚠ **Note on Irvine32 Library**  
> This project depends on the `Irvine32` library, which is **not included in this repository** due to licensing and distribution restrictions.  
> You must obtain it from the official source provided by Kip Irvine (usually bundled with the *Assembly Language for x86 Processors* textbook or downloadable from his official course resources).  
> See [Requirements](#requirements) for details.

Built with love and registers.

---

## Why Irvine32 Is Not Included

The **Irvine32** library is created and distributed by Kip Irvine as part of his assembly programming textbook.  
While it is free to use for educational purposes, it is **not open-source** and redistribution is restricted.  
Re-hosting the library files (`Irvine32.inc`, `Irvine32.lib`, `Irvine32.dll`) on GitHub would violate the licensing terms.  
Therefore, this repository contains only my original source code and compiled files — you must download Irvine32 from the **official source** to build the game yourself.

---

## Features

- Move the snake using `W`, `A`, `S`, `D` keys.
- Collect coins (`X`) to grow the snake.
- Collision detection with:
  - Walls
  - Itself
- Score tracking with a scoreboard.
- Game over & retry option.
- Dynamic snake growth.
- Random coin generation avoiding snake body.
- User-friendly start prompt.

---

## How It Works

This game uses:
- `.386` Flat memory model
- BIOS text-mode functions
- **Irvine32 library** for:
  - Console input/output
  - Text coloring
  - Cursor positioning
  - Random number generation
- Low-level memory access for game state (positions, score, etc.)
- Classic game loop for real-time interaction

---

## Controls

| Key | Action        |
|-----|---------------|
| `W` | Move Up       |
| `A` | Move Left     |
| `S` | Move Down     |
| `D` | Move Right    |
| `X` | Exit Game     |

At the start, you're prompted:
> `Do you want to play the game? 1 = Yes, 2 = No`

After game over:
> `Try Again? 1 = yes, 0 = no`

---

## File Structure

| File/Section | Description |
|--------------|-------------|
| `.data`      | Stores messages, snake and coin data, position arrays, score variables |
| `main PROC`  | Main game loop, input handling, collision logic |
| `DrawWall`   | Renders the border walls of the game area |
| `DrawScoreboard` | Initializes the score display |
| `DrawPlayer`, `DrawBody` | Renders the snake head and body |
| `EatingCoin` | Updates score and grows the snake |
| `CheckSnake` | Detects self-collision |
| `CreateRandomCoin` | Places coins in random positions, avoiding snake |
| `PromptScreen`, `YouDied`, `ReinitializeGame` | UI/UX logic and game state resets |

---

## Requirements

- **MASM32** or compatible x86 Assembly compiler
- **Irvine32 library** (`Irvine32.inc`, `Irvine32.lib`, `Irvine32.dll`)  
  - Download from the official Kip Irvine distribution (not included in this repo)
- Windows machine (due to dependency on Irvine32)

---

## Setup & Run

1. Install MASM and download the `Irvine32` library from its official source.
2. Place `Irvine32.inc` and `Irvine32.lib` in your project path or MASM include/lib directories.
3. Assemble and link using:

```bash
ml /c /coff snake.asm
link /subsystem:console snake.obj Irvine32.lib
```

---

## Disclaimer

This repository contains **only**:
- Source code (`snake.asm`)
- Compiled object file (`snake.obj`)
- Executable (`snake.exe`) for testing

It **does not** include the Irvine32 library files, in compliance with licensing restrictions.  
To rebuild from source, you must download Irvine32 externally.
