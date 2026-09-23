<h1 align="center">
  <img src="Resources/logo_aligned.png" height="34" alt="DeepSeek Logo" /> Deepeak
</h1>

<p align="center">
  <b>A polished, ultra-lightweight macOS menu bar tool for DeepSeek.</b><br/>
  Tracks live API peak & off-peak discount hours, converts schedules to your local system timezone, and provides real-time token pricing.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue" alt="macOS 13+" />
  <img src="https://img.shields.io/badge/Swift-5.9%2B-F05138" alt="Swift 5.9+" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" />
  <img src="https://img.shields.io/badge/Bundle%20Size-584%20KB-success" alt="Bundle Size 584 KB" />
</p>

---

## ✨ Features

- **🐋 Dynamic Menu Bar Icon**:
  - Displays the official **DeepSeek Whale logo** in the macOS menu bar.
  - Automatically turns **Electric Blue** during **Off-Peak (50% discount)** hours.
  - Automatically turns **Graphite / Black** during **Peak** hours.

- **⏰ System Timezone Sync & Countdown**:
  - Tracks DeepSeek's Monday–Friday UTC windows (`01:00–04:00 UTC` and `06:00–10:00 UTC`).
  - Automatically translates intervals into your Mac's current local system timezone.
  - Dynamically updates on system timezone or clock adjustments.
  - Real-time countdown displaying remaining time until the next peak/off-peak transition.

- **💰 Token Pricing Breakdown (USD / 1M Tokens)**:
  - Tracks active models: **DeepSeek V4.1 Flash** and **DeepSeek V4 Pro**.
  - Shows **Cache Hit**, **Input Miss**, and **Output** rates with automatic 50% discount calculation and strikethrough peak rates.
  - Background auto-refresh every **12 hours** with an instant manual refresh trigger.

- **⚡ Featherweight & Resource Conscious**:
  - Entire app bundle is only **584 KB** on disk.
  - **Lazy Popover Allocation**: View hierarchy and window backing stores are torn down immediately on dismiss.
  - Zero-lag, instant presentation.
  - Pure menu bar utility with no dock icon.

---

## 🚀 Installation

### Option 1: Direct Download (Recommended)
1. Download the latest **[Deepeak.zip](https://github.com/lucentxo/Deepeak/releases/latest/download/Deepeak.zip)** from [Releases](https://github.com/lucentxo/Deepeak/releases/latest).
2. Unzip and drag `Deepeak.app` into your **Applications** folder.
3. Launch `Deepeak` — the whale logo will appear directly in your macOS menu bar!

---

### Option 2: Build from Source
If you prefer to compile it yourself:

```bash
git clone https://github.com/lucentxo/Deepeak.git
cd Deepeak
./build.sh
open Deepeak.app
```


---

## 🛠 Project Structure

```
DeepSeekStatus/
├── Package.swift               // Swift Package Manager configuration
├── build.sh                    // Automated build & .app bundling script
├── Resources/
│   ├── Info.plist              // LSUIElement=true configuration
│   └── deepseek_logo.png       // Official DeepSeek whale asset
└── Sources/
    ├── DeepSeekStatusApp.swift // App entry point, menu item & popover lifecycle
    ├── Models/
    │   ├── ScheduleManager.swift // UTC peak schedule, timezone converter & timer
    │   └── PricingManager.swift  // Token pricing rates, cache & 12h refresh timer
    ├── Views/
    │   ├── PopoverContentView.swift // Unified container
    │   ├── StatusHeaderView.swift   // Whale badge, status pill & discount indicator
    │   ├── ScheduleCardView.swift   // Local timezone peak schedule table
    │   └── PricingCardView.swift    // Tabular token pricing rates
    └── Assets/
        └── DeepSeekWhaleLogo.swift  // Official logo loader & dynamic tint generator
```

---

## 📄 License

Distributed under the MIT License.
