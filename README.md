# Lane-Based Autonomous Obstacle Avoidance Simulator using x86 Assembly Language

## Computer Architecture Project

**Hankuk University of Foreign Studies**
**Spring 2026**

---

## Project Overview

This project implements a lane-based autonomous obstacle avoidance simulator using x86 Assembly Language.

The simulator demonstrates a simplified autonomous driving system in a text-based road environment. A vehicle travels along a three-lane road while obstacles continuously appear ahead. The system automatically detects obstacles in the current lane and performs lane-changing maneuvers to avoid collisions.

The project was inspired by existing 8086 Assembly racing game implementations and was extended with an autonomous decision-making mechanism.

---

## Features

* Three-lane road environment
* Autonomous obstacle avoidance
* Manual driving mode (A/D keys)
* Obstacle generation and movement
* Collision detection
* Score tracking system
* Game Over condition
* Toggle between manual and autonomous driving modes

---

## System Workflow

```text
Obstacle Generation
        ↓
Obstacle Detection
        ↓
Lane Evaluation
        ↓
Safe Lane Selection
        ↓
Automatic Lane Change
        ↓
Continue Driving
```

---

## Development Environment

* x86 Assembly Language
* EMU8086 / MASM-compatible Assembly
* Visual Studio Code
* DOS-based execution environment

---

## Project Structure

```text
Lane-Based-Autonomous-Obstacle-Avoidance-Simulator-x86/

├── src/
│   └── lane_auto_avoid.asm
│
├── docs/
│   ├── screenshots/
│   ├── report/
│   └── demo_video/
│
├── references/
│   └── references.md
│
└── README.md
```

---

## References

1. 8086 Assembly Racing Game Reference
   https://github.com/Mahmoud-Khaled-Nasr/Car-Racing-Game-x8086

2. Assembly Driving Game Reference
   https://github.com/yousseftawakal/driving-car-asm

3. NASM Official Documentation
   https://www.nasm.us/docs.php

4. Visual Studio Code
   https://code.visualstudio.com/

5. 8086 Assembly Language Projects
   https://github.com/yousefkotp/8086-Assembly-Projects

---

## Future Improvements

* More sophisticated obstacle prediction
* Multiple obstacle types
* Variable vehicle speed
* Dynamic difficulty adjustment
* Enhanced graphics and animation

---

## Author

**Lee Shinbi**

Department of Computer Engineering

Hankuk University of Foreign Studies
