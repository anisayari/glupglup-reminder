# GlupGlup Reminder 💧

A tiny macOS menu bar app that nudges you to drink water during the day.

It lives in the top bar, animates a little droplet, plays a water sound when you log a glass, keeps a score/streak, and gives you a proper history view with charts and a heatmap.

## Features ✨

- 💦 Animated menu bar droplet
- 🥤 One-click water tracking
- 🔔 Reminder presets + custom interval in minutes
- 📈 History window with chart, heatmap, and recent-day summary
- 🎯 Daily goal, streak, and lightweight gamification
- 🌍 English by default, with optional French UI
- 🔊 Small water-drop sound on clicks and reminders

## Easy install 🚀

1. Double-click [`Installer.command`](./Installer.command)
2. The app is built locally
3. It gets copied to `~/Applications/GlupGlup Reminder.app`
4. It launches automatically

## Manual install 🛠️

```bash
./Scripts/install_app.sh
```

## Local build 👩‍💻

```bash
./Scripts/build_app.sh
```

The app bundle is generated at `Build/GlupGlup Reminder.app`.

## How to use 👀

- `Click` the menu bar icon to add `250 ml`
- `Option-click` to remove `250 ml`
- `Right-click` to open stats and settings
- Open `History` to view your recent hydration activity
- Switch the reminder interval to `Custom` if you want an exact minute value

## Notes 📌

- Notifications use macOS local notifications
- Existing local data from the older `Glouglou` app name is migrated automatically
- The history view is built into the app already
