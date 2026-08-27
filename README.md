# 🚀 3D Platformer Odyssey

A complete, responsive 3D Platformer game built with **Godot 4.4**.

🔗 **GitHub Repository:** [https://github.com/TheDevCharlie/3d-platformer-test](https://github.com/TheDevCharlie/3d-platformer-test)

---

## 🎮 Controls

* **WASD / Arrow Keys**: Move
* **Space**: Jump
  * Tap for short hop, Hold for full jump height
  * **Double Jump**: Press `Space` again while in mid-air!
* **Mouse**: Orbit Camera (Click anywhere to capture cursor)
* **Escape / P**: In-Game Pause Menu
* **Shift**: Sprint
* **Attack**: Double-jump or high-jump and land directly onto an enemy's head!
* **Objective**: Collect coins, eliminate enemies, and reach the **Golden Victory Beacon** on top of the Sky Island!
* **R**: Quick Stage Restart

---

## 🌟 Key Features

### 1. Main Menu & In-Game Pause Menu
* **Frontend Main Menu ([`scenes/main_menu.tscn`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scenes/main_menu.tscn))**: Features an animated 3D floating backdrop, "Play Game", interactive "Controls & Guide" popup, and "Quit" button.
* **In-Game Pause Menu ([`scenes/pause_menu.tscn`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scenes/pause_menu.tscn))**: Toggle with `Escape` or `P` to freeze the 3D world with options to Resume, Restart Stage, or return to the Main Menu.

### 2. Randomized & Procedural Level Progression ([`scripts/level_generator.gd`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scripts/level_generator.gd))
* Each time you complete a stage, clicking **"Next Stage"** procedurally generates a brand new layout with:
  * **4 Distinct Themes**: *Emerald Haven*, *Sunset Canyon*, *Cyber Metropolis*, and *Glacial Peaks* with custom skies, lighting, fog, and materials.
  * **Dynamic Platforming**: Procedural CSG platform heights, moving platforms, and spring jump pads.
  * **Randomized Enemies & Coins**: Enemies patrol generated platforms, and coins scatter along tricky jump trajectories.
  * **Sky Island Goal**: Each level ends with a majestic floating island holding the Golden Victory Beacon.

### 3. Combat, Health & Enemy AI ([`scripts/enemy.gd`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scripts/enemy.gd))
* **100 HP Player System**: Full HUD health bar with damage flashing.
* **1.8m Tall Aggro Enemies**: Billboarded 3D health bars, 9m aggro chase, hit recoil separation, and head stomping.
* **Universal Defeat Counter**: Eliminating enemies (via stomps or luring them off cliffs) updates the counter.

### 4. Speedrun Timer & World Freeze Loop ([`scripts/main.gd`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scripts/main.gd))
* Real-time timer (`⏱ MM:SS.ms`) tracking level duration that freezes on Win and Loss.
* Interactive modal popups with restart and next stage buttons.
