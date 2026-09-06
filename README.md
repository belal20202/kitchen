# 🍔 Happy Kitchen Story

A cute, fast-paced **Cooking & Restaurant Management** mobile game built with **Godot 4.x** and **GDScript**.

> Fully original project: no assets, characters, names, UI, levels, or audio are copied from any
> existing game (including *Happy Dinner Story* or any other title). All placeholder art/audio
> referenced in this project is original and simple, intended to be replaced with your own
> licensed or commissioned assets before release.

---

## 📖 Game Overview

The player runs a small restaurant. Customers walk in, place orders, and the player must:

1. Select the waiting customer.
2. See what they ordered.
3. Tap the required ingredients **in the correct order** to prep the dish.
4. Tap the correct piece of equipment (Grill, Oven, Fryer, Coffee Machine, Juice Machine) to cook it.
5. Serve the finished dish before it burns.
6. Collect payment + tip, build combos, earn stars, and unlock new restaurants, recipes,
   equipment upgrades, and employees.

## ✨ Features

- **6 customer types** (Normal, Patient, Impatient, VIP, Family, Rush) with different patience,
  tip, and order-size behavior.
- **10 recipes** across 4 equipment types, fully data-driven (add new recipes with zero code
  changes — see [Development Guide](#-development-guide)).
- **20 handcrafted levels** for the starter Burger Restaurant, increasing in difficulty.
- **5 unlockable restaurants**: Burger, Pizza, Coffee Shop, Chicken, Dessert.
- **Combo system** (x2 → x10) that boosts tips.
- **Star rating** (1–3 ⭐) per level based on earnings.
- **Equipment upgrades**, **employee hiring/upgrades** (Chef, Waiter, Cashier), and a
  **non-Pay-to-Win economy** (Coins for gameplay progress, Gems only for convenience/cosmetics).
- **Daily/weekly missions + achievements.**
- **Local JSON save system**, versioned and easy to extend.
- **Mobile-first UI**: portrait orientation, touch controls, responsive layout, Android back
  button support (via Godot's default `ui_cancel`/back handling).
- **Automated GitHub Actions pipeline** that runs the test suite and builds a debug APK on every push.

## 🧩 Requirements

- [Godot Engine **4.2.x**](https://godotengine.org/download) (or newer 4.x) — GDScript, no C#.
- For Android export: Android SDK (command-line tools, platform-tools, `platform;android-34`,
  `build-tools;34.0.0`) and a JDK (17+). Godot's Android export also needs the
  **Godot Android build template** installed *only if* you enable Gradle builds — this project
  defaults to the simpler non-Gradle export, which needs no extra template.
- Godot **export templates** matching your installed Godot version (Editor → Manage Export
  Templates → Download and Install).

## 🚀 Installation

```bash
git clone https://github.com/<your-username>/happy-kitchen-story.git
cd happy-kitchen-story
```

Open Godot 4.x → **Import** → select the `project.godot` file in this folder.

## ▶️ How to Run

1. Open the project in the Godot editor.
2. Press **F5** (Run Project) or click the ▶ button. The game boots into `MainMenu.tscn`.
3. To run on a connected Android device/emulator during development: **Project → Export →
   Android → One-click Deploy**, or use `godot --headless --export-debug "Android" build/test.apk`.

## 📦 How to Export an APK

### Locally, from the Godot editor
1. **Project → Export...**
2. Select the **Android** preset (already configured in `export_presets.cfg`).
3. Make sure you have export templates installed (Editor → Manage Export Templates).
4. Click **Export Project**, choose an output path, and Godot will produce
   `HappyKitchenStory.apk`.

### Locally, from the command line
```bash
godot --headless --path . --export-debug "Android" build/HappyKitchenStory.apk
```
(Use `--export-release` for a signed release build — you'll need to configure a release keystore
in `export_presets.cfg` or via the editor first.)

### Via GitHub Actions (fully automated)
Every push to `main` (or a manual run from the **Actions** tab) will:
1. Run the GDScript test suite headlessly.
2. Install the Android SDK + Godot export templates.
3. Export a debug APK named `HappyKitchenStory.apk`.
4. Upload it as a downloadable **workflow artifact**.

See `.github/workflows/android.yml`.

## 🔗 Connecting This Project to GitHub

```bash
cd happy-kitchen-story
git init
git add .
git commit -m "Initial commit: Happy Kitchen Story"
git branch -M main
git remote add origin https://github.com/<your-username>/happy-kitchen-story.git
git push -u origin main
```

After pushing, go to your repository's **Actions** tab — the `Build Android APK` workflow will
run automatically and produce a downloadable APK artifact once it finishes.

## 🗂️ Project Structure

```
res://
├── scenes/
│   ├── main/          # MainMenu
│   ├── restaurant/     # (per-restaurant scenes go here as you add them)
│   ├── customers/      # Customer.tscn
│   ├── kitchen/        # Kitchen.tscn (core gameplay)
│   ├── ui/             # (shared UI components)
│   └── menus/          # RestaurantSelect, LevelSelect, LevelComplete,
│                        # UpgradesMenu, ShopMenu, EmployeesMenu,
│                        # AchievementsMenu, SettingsMenu
├── scripts/
│   ├── core/           # LevelData, RestaurantData
│   ├── gameplay/       # Order, OrderSystem, Equipment, Kitchen
│   ├── customers/      # Customer, CustomerSpawner, CustomerTypeData
│   ├── recipes/        # RecipeData, IngredientData
│   ├── economy/        # UpgradeData, EmployeeData/Manager, AchievementData/Manager
│   ├── save/           # (reserved for future save-related helpers)
│   └── ui/             # MainMenu, RestaurantSelect, LevelSelect, LevelComplete,
│                        # UpgradesMenu, ShopMenu, EmployeesMenu, AchievementsMenu,
│                        # SettingsMenu
├── data/
│   ├── recipes/        # recipes.json, ingredients.json
│   ├── customers/      # customer_types.json
│   ├── restaurants/     # restaurants.json
│   ├── levels/          # burger_restaurant_levels.json (20 levels)
│   └── upgrades/        # equipment_upgrades.json, employees.json, achievements.json
├── assets/
│   ├── sprites/, backgrounds/, ui/, audio/, fonts/   # placeholders — see below
├── autoload/
│   ├── GameManager.gd, SaveManager.gd, AudioManager.gd,
│   └── EconomyManager.gd, LevelManager.gd
├── tests/               # test_runner.gd + test_*.gd
├── .github/workflows/android.yml
├── export_presets.cfg
├── project.godot
├── README.md
└── .gitignore
```

## 🎮 Controls

- **Tap** a customer avatar to select them and see their order.
- **Tap** ingredients in the exact order shown to prep the dish.
- **Tap** the matching equipment to start cooking.
- **Tap Serve** once the dish is ready (or before it fully burns, at reduced value).
- **Pause button** (top-right during a level) opens the pause menu.
- Android **system back button** returns to the previous menu (default Godot behavior on `Control`
  scenes using `ui_cancel`; wire additional back-button handling per scene if you add more screens).

## 🛠️ Development Guide

- **Adding a new recipe**: add an entry to `data/recipes/recipes.json`. No code changes required.
- **Adding a new ingredient**: add an entry to `data/recipes/ingredients.json`.
- **Adding a new level**: add an entry to the relevant file under `data/levels/` (or create a new
  JSON file for a new restaurant's levels — `LevelManager` loads every `.json` file in that folder).
- **Adding a new restaurant**: add an entry to `data/restaurants/restaurants.json`, then create its
  scene (duplicate `scenes/kitchen/Kitchen.tscn` as a starting point) and levels file.
- **Adding a new equipment/employee/achievement**: add entries to the corresponding JSON file under
  `data/upgrades/`.
- **Autoloads** (`GameManager`, `SaveManager`, `AudioManager`, `EconomyManager`, `LevelManager`) are
  the only global singletons — everything else is a plain node/resource, kept out of one giant file
  by design.
- **Running tests locally**:
  ```bash
  godot --headless --path . --script res://tests/test_runner.gd
  ```

## 🎨 Original Art & Animation Included

Simple original vector (SVG) art is now included and fully wired into the game (still stylized
flat-cartoon placeholders, not final production art, but real visuals with real feedback instead
of colored boxes):

- **Customer portraits**: one distinct SVG per customer type (`assets/sprites/customer_*.svg`),
  automatically applied to each spawned `Customer` and to their selection button, via
  `CustomerTypeData.portrait_path` in `data/customers/customer_types.json`.
- **Chef avatar**: `assets/sprites/chef.svg` (not yet wired into a scene — available for a
  future player-avatar or menu portrait).
- **12 ingredient icons** (`assets/sprites/ingredients/*.svg`) — shown directly on the prep
  buttons in the Kitchen scene, wired via `IngredientData.icon_path`.
- **10 recipe icons** (`assets/sprites/recipes/*.svg`) — shown on the order ticket next to the
  dish name, wired via `RecipeData.icon_path`.
- **All 5 restaurant interiors** (`assets/backgrounds/*_interior.svg`) — Burger, Pizza, Coffee
  Shop, Chicken, and Dessert each have their own background, automatically loaded into
  `Kitchen.tscn` based on `RestaurantData.background_path` for whichever restaurant is active.
- **City street backdrop**: `assets/backgrounds/city_street.svg` (shows all 5 restaurant
  storefronts), used as the background for `MainMenu.tscn` and `RestaurantSelect.tscn`.

**Procedural animation / game feel** (all done in code with `Tween`, no animation files needed):
- Customers have a gentle idle "breathing" bob while waiting.
- Customers play a happy scale-pop when served satisfied, or an angry shake when their patience
  runs out — both before being removed from the scene.
- Ingredient and equipment buttons "punch" (scale bounce) on a correct tap, and shake on a wrong
  tap, giving immediate tactile feedback.
- The **Serve** button gently pulses while a dish is ready, drawing the eye to the next action.

**Sound** (previously completely silent — now fully functional, all synthesized in code, zero
external/copyrighted audio):
- 10 original UI/gameplay sound effects (`assets/audio/sfx/*.wav`) generated as simple synthesized
  tones/noise bursts — clicks, chops, sizzling, cash register, happy/angry customer stingers,
  burn warnings, and a star-earned fanfare.
- 6 original looping background music tracks (`assets/audio/music/*.wav`) — one per restaurant
  plus a menu theme — short chiptune-style melodies generated from note sequences.
  `AudioManager` automatically sets `loop_mode = LOOP_FORWARD` on these so they loop seamlessly.
- **Equipment icons**: Grill, Oven, Fryer, Coffee Machine, and Juice Machine now each have their
  own SVG icon on their Kitchen buttons (`assets/sprites/equipment/*.svg`).

**Onboarding**: first-time players get a simple "How to Play" overlay at the start of Level 1
(Burger Restaurant), explaining the 4-step loop before the timer starts. It's shown once — tracked
via `GameManager.tutorial_completed` and persisted in the save file.

Because Godot imports `.svg` files as regular `Texture2D` resources, you can swap any of these
for a raster (`.png`) replacement later with zero code changes — just replace the file and update
the relevant `*_path` field in the JSON data. Same for audio: any `.wav` can be swapped for a
real recording/composition with no code changes.

## 🖼️ Placeholder Assets Still Needing Replacement

The items above are original but still simple placeholders (synthesized audio, flat-vector art).
Still missing entirely:

- `assets/sprites/icon.svg` — simple placeholder app icon.
- Real recorded/composed music and voice-acted or sampled SFX (current audio is code-synthesized
  tones, not produced by a sound designer or musician).
- Employee portraits (`EmployeeData.portrait`).
- Real hand-drawn/animated character sprites and sprite-sheet animations (walk cycles, cooking
  animations) — current motion is procedural (Tween-based), not frame animation.
- App launcher icons referenced in `export_presets.cfg` (`launcher_icons/*`) — left blank; Godot
  will fall back to its default icon until you supply your own.

## 📄 License

This project's original code, data files, and placeholder assets are provided as-is for you to
build upon. Add your preferred license text here (e.g. MIT) before publishing, and make sure any
replacement art/audio/fonts you add are properly licensed for your use case.
