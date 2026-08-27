# Godot 4 3D Platformer Starter

A complete, responsive 3D Platformer prototype built with **Godot 4.4**.

---

## 🎮 Controls & Objective

* **WASD / Arrow Keys**: Move
* **Space**: Jump
  * Tap for short hop, Hold for full jump height
  * **Double Jump**: Press `Space` again while in mid-air!
* **Mouse**: Orbit Camera (Click anywhere to capture cursor)
* **Escape**: Toggle mouse capture / release cursor
* **Shift**: Sprint
* **Attack**: Double-jump or high-jump and land directly onto an enemy's head!
* **Objective**: Collect coins, eliminate enemies (by stomping them or luring them off cliffs), and reach the **Golden Victory Beacon** on top of the Sky Island!
* **R**: Quick Respawn / Play Again after Victory or Game Over

---

## 🚀 Features Breakdown

### 1. Tall Aggro Enemies ([`scripts/enemy.gd`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scripts/enemy.gd) & [`scenes/enemy.tscn`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scenes/enemy.tscn))
* **Tall 1.8m Proportions**: Upright humanoid/capsule height with an elevated head hurtbox (`1.85m`) preventing accidental stomps while running or bumping.
* **Smart Aggro AI**: Chases player within 9m; returns to patrol beyond 14m leash.
* **Multi-Hit / 3D Health Bar**: Billboarded floating health bar; stomps deal 60 damage (instant defeat).
* **Universal Defeat Tracking**: Enemy elimination counter updates regardless of whether enemies are stomped or lured off cliffs into the void.

### 2. Health & Combat Systems
* **Player Health (`100 HP`)**: Displayed on HUD with live progress bar and damage strobe frames.
* **Attack Damage**: Colliding with enemies deals 25 damage with knockback.

### 3. Speedrun Timer & Level Loop ([`scripts/main.gd`](file:///C:/Users/HP/.gemini/antigravity/scratch/godot_3d_platformer/scripts/main.gd))
* **Live Timer**: Real-time timer (`⏱ MM:SS.ms`) tracking level duration.
* **Frozen Win Time**: Time permanently freezes upon touching the Golden Goal Beacon.
* **Victory / Game Over Screens**: Display complete speedrun statistics and restart prompts (`R`).
