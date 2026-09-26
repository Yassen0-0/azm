# Real-device test checklist

Things that **cannot be verified** on the Android emulator or the iOS Simulator. These must be checked by a tester with a real phone before release. Every feature agent adds its items here (see CLAUDE.md → Platform Parity Rule). Tick an item only after testing it on a real device, and note the device, OS version and date.

Format: `- [ ] <what to check> — <how> (added by <feature>, <date>)`

## iPhone (no physical device available to the owner)

### App shell & platform
- [ ] Home-screen name shows `عزم` with the phone in Arabic and `Azm` in English. The Simulator already confirms it, but check once on hardware. (bootstrap, 2026-09-26)
- [ ] Readex Pro renders with correct Arabic shaping and weights (the `wght` axis visibly changes between 400/600/700), with no fallback font. (bootstrap, 2026-09-26)
- [ ] Glass tab bar blur performance: scrolling under the bar stays smooth (60/120 Hz ProMotion), no frame drops. (bootstrap, 2026-09-26)
- [ ] Cold start time of a **release** build (debug builds on the Simulator took ~25 s because of JIT, which is not representative). First launch includes the catalog install. Target: under 2 s to the first screen. (bootstrap, 2026-09-26)
- [ ] Safe areas: Dynamic Island / notch and home indicator don't overlap the header or the tab bar. (bootstrap, 2026-09-26)
- [ ] Reduced Motion (Settings → Accessibility → Motion) removes page-rise and press-scale animations. (bootstrap, 2026-09-26)
- [ ] Code signing with `./ios_env flutter run -d <iphone>` works with the owner's Apple account and the real HOME. (bootstrap, 2026-09-26)

## Android phone

- [ ] The launcher label shows `عزم` with the phone in Arabic. The emulator image (Google Play, not rootable) could not switch the system locale; the APK resources were verified with `aapt2` (`docs/screenshots/shell/android/launcher_label.txt`). (bootstrap, 2026-09-26)
- [ ] Per-app language: the in-app language switch and the system per-app language (Android 13+) don't fight each other. (bootstrap, 2026-09-26)
- [ ] Release-build cold start and first-launch catalog install on a mid-range phone. Target: under 2 s. (bootstrap, 2026-09-26)

## Both platforms — to be filled by feature agents
- _workout: haptics on ✓ (light impact), rest-timer end sound + vibration, notification delivered with the app in background / killed / phone locked, exact-alarm behavior on Android 14+, notification permission prompts…_
- _exercises: GIF playback smoothness and memory on the detail screen, image cache after going offline…_
