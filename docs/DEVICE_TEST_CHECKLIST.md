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
_Feature sections below._

### Exercises (added by exercises, 2026-09-26)
- [ ] Search feels instant while typing in a **release** build on a mid-range phone (Android and iPhone): every keystroke < 50 ms, first open of the Exercises tab (one-time catalog load) < 300 ms. Emulator debug numbers are in DECISIONS_LOG. (exercises, 2026-09-26)
- [ ] Arabic keyboard input in the search box (Gboard Arabic, iOS Arabic keyboard): letters with hamza/tashkeel, and switching AR↔EN mid-query, still find results. (exercises, 2026-09-26)
- [ ] With licensed media: thumbnails in the library scroll smoothly (1,324 rows); the detail GIF plays smoothly, memory stays stable when opening 20+ details in a row, and the attribution line shows. Offline after a first view: cached media still shows; uncached → fallback icon. (exercises, 2026-09-26)
- [ ] The equipment sheet: swipe-down dismiss and the home indicator/gesture bar don't conflict (iPhone with Face ID, Android gesture navigation). (exercises, 2026-09-26)
- [ ] VoiceOver / TalkBack read the picker rows as "selected, number N", and the 🏆 badge as "your record: …". (exercises, 2026-09-26)

### Workout (added by workout, 2026-09-26)

Emulator/Simulator can't prove these; check on real phones (both platforms unless marked).

- [ ] Light haptic on ✓ of a set; selection click when ✓ is tapped on an empty set (keypad opens). (workout, 2026-09-26)
- [ ] Rest timer end with the app **in the foreground**: heavy haptic + notification banner **with sound** (iOS presents it in the foreground via the `UNUserNotificationCenter` delegate). (workout, 2026-09-26)
- [ ] Rest timer end with the app **in the background**, **killed** (swipe away) and with the phone **locked**: notification arrives on time with sound/vibration. Note the delay if any. (workout, 2026-09-26)
- [ ] −15 / +15 while running, then background the app: the notification fires at the NEW time; Skip → no notification at all. (workout, 2026-09-26)
- [ ] Permission prompt appears once, on the first ✓ (first rest timer), not at launch. Denying it still lets you log sets; the in-app timer still works. (workout, 2026-09-26)
- [ ] **Android 14+ exact alarms:** a fresh install has `SCHEDULE_EXACT_ALARM` denied → the app uses an inexact alarm + shows the notification itself while running. With the screen off for 2–5 min during a rest, measure how late the notification is. Then grant "Alarms & reminders" in system settings and repeat (should be on time). (workout, 2026-09-26)
- [ ] Android: reboot the phone during a long rest (e.g. +15 several times): the pending notification is re-scheduled (boot receiver). (workout, 2026-09-26)
- [ ] Android notification icon: the monochrome dumbbell (`ic_stat_azm`) shows correctly in the status bar in a **release** build (R8 keep rule). (workout, 2026-09-26)
- [ ] Tapping the rest notification opens the app on the active workout (cold start resumes it). (workout, 2026-09-26)
- [ ] Kill the app mid-workout (and pull the battery / force-stop): reopen → the active workout opens with every set, value and ✓ exactly as left, rest timer still counting if not over. (workout, 2026-09-26)
- [ ] Custom keypad: the system keyboard never appears; keys respond quickly; typing speed feels OK with one thumb. (workout, 2026-09-26)
- [ ] Swipe-to-delete a set feels right in Arabic (swipe toward the LEFT edge = end in RTL) and English (toward the right). (workout, 2026-09-26)
- [ ] Reduced motion (iOS Settings → Accessibility → Motion / Android "Remove animations"): Lifted counter and PR badge jump without animation; haptics stay. (workout, 2026-09-26)
- [ ] Performance: a long workout (8 exercises × 5 sets) scrolls smoothly while the rest timer runs. (workout, 2026-09-26)

### Integration (added by integrator, 2026-09-26)
- [ ] **Android 14+ exact-alarm sheet:** fresh install → first ✓ → after the notification prompt, the explanation sheet appears once. "Open settings" → toggle "Alarms & reminders" ON → Back: this rest's notification now arrives on time with the screen off. Reinstall, choose "Not now": the sheet never appears again, rests still notify (possibly late). Revoking the permission later in system settings: the app is restarted by Android; check an active workout resumes intact. (integrator, 2026-09-26)
- [ ] Android 12–13 phone (exact alarms granted by default): no sheet ever appears. (integrator, 2026-09-26)
- [ ] Finish with unticked sets on a real phone: the three-button dialog fits (buttons stack vertically in both languages) and "Mark all done" fills empty sets from "previous" as expected. (integrator, 2026-09-26)
- [ ] Low-end Android phone: "Start workout" opens the active workout every time (the stale-provider bounce fixed at integration never reappears). (integrator, 2026-09-26)

### Routines + onboarding (window C, round 2)

_(window C appends here only)_

### History (window D, round 2)

_(window D appends here only)_
- [ ] Edit a past workout on a phone: keypad edits, "Add set", swipe-to-delete (toward the end edge) and ✓ feel like the live workout; leave the screen → unticked/empty sets are gone, History card and exercise detail show the new values at once. (history, 2026-09-27)
- [ ] Kill the app while editing a past workout with an unticked set → reopen that workout: the unticked set has been removed; nothing else changed. (history, 2026-09-27)
- [ ] Performance with a long history (1–2 years, ~300 workouts): History tab, calendar month switching and Stats open without visible lag; logging sets in the active workout stays smooth while the History tab is alive. (history, 2026-09-27)
- [ ] Device in a UTC+2/+3 time zone: a workout started just after midnight shows on that day in the calendar and in that week in Stats; the calendar week starts on Saturday in Arabic, Sunday in English. (history, 2026-09-27)
- [ ] VoiceOver / TalkBack: calendar days read the full date and the workout count; the 🏆 badge on a card reads "N personal records". (history, 2026-09-27)
