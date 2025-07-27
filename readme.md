Snake Game in x86 Assembly (MASM & Irvine32)

A classic Snake game implemented in x86 Assembly Language using MASM and Irvine32 library, built for educational and nostalgic DOS/console gameplay.

Built with love and registers.

---

Features

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

How It Works

This game uses:
- .386 Flat memory model
- BIOS text-mode functions
- Irvine32 library for:
  - Console input/output
  - Text coloring
  - Cursor positioning
  - Random number generation
- Low-level memory access for game state (positions, score, etc.)
- Classic game loop for real-time interaction

---

Controls

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

File Structure

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

Requirements

- MASM32 or compatible x86 Assembly compiler
- `Irvine32.inc`, `Irvine32.lib`, `Irvine32.dll`
- Windows machine (due to dependency on Irvine32)

---

Setup & Run

1. Ensure MASM and Irvine32 are correctly installed.
2. Include `Irvine32.inc` and `Irvine32.lib` in your project path.
3. Assemble and link using:

```bash
ml /c /coff snake.asm
link /subsystem:console snake.obj Irvine32.lib
