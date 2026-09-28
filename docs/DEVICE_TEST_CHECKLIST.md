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
- [ ] Swipe-to-delete a set feels right in Arabic (swipe toward the RIGHT edge = start in RTL) and English (toward the left). (workout, 2026-09-26; direction changed to the start edge 2026-09-28)
- [ ] Reduced motion (iOS Settings → Accessibility → Motion / Android "Remove animations"): Lifted counter and PR badge jump without animation; haptics stay. (workout, 2026-09-26)
- [ ] Performance: a long workout (8 exercises × 5 sets) scrolls smoothly while the rest timer runs. (workout, 2026-09-26)

### Integration (added by integrator, 2026-09-26)
- [ ] **Android 14+ exact-alarm sheet:** fresh install → first ✓ → after the notification prompt, the explanation sheet appears once. "Open settings" → toggle "Alarms & reminders" ON → Back: this rest's notification now arrives on time with the screen off. Reinstall, choose "Not now": the sheet never appears again, rests still notify (possibly late). Revoking the permission later in system settings: the app is restarted by Android; check an active workout resumes intact. (integrator, 2026-09-26)
- [ ] Android 12–13 phone (exact alarms granted by default): no sheet ever appears. (integrator, 2026-09-26)
- [ ] Finish with unticked sets on a real phone: the three-button dialog fits (buttons stack vertically in both languages) and "Mark all done" fills empty sets from "previous" as expected. (integrator, 2026-09-26)
- [ ] Low-end Android phone: "Start workout" opens the active workout every time (the stale-provider bounce fixed at integration never reappears). (integrator, 2026-09-26)

### Routines + onboarding (window C, round 2)

_(window C appends here only)_
- [ ] Routine editor on a real phone: tapping the name/notes fields opens the system keyboard; tapping a weight/reps cell closes it and shows the WeightKeypad (never both). The keypad's step haptic is felt. (window C, 2026-09-27)
- [ ] Swipe a target set toward the start edge to delete it (left in English, right in Arabic; changed 2026-09-28) on both platforms; drag-to-reorder exercises in the sheet feels smooth. (window C, 2026-09-27)
- [ ] Fresh install on a real phone (both platforms): onboarding appears once; after finishing, killing and reopening the app lands on the Workout tab. Updating over an install that already has workouts skips onboarding. (window C, 2026-09-27)
- [ ] Start a routine, kill the app during the workout, reopen: the prefilled workout resumes exactly (targets, routine rest times). (window C, 2026-09-27)

### History (window D, round 2)

_(window D appends here only)_
- [ ] Edit a past workout on a phone: keypad edits, "Add set" and swipe-to-delete (toward the start edge since 2026-09-28) feel like the live workout; there is no ✓ column; leaving the screen removes nothing; the History card and exercise detail show the new values at once. (history, 2026-09-27; ✓/removal wording updated by the integrator 2026-09-27)
- [ ] Add an exercise to a past workout, kill the app at once, reopen that workout: the new exercise's sets are there and logged (values from the workout before, or 0 × 0); nothing was removed. (history, 2026-09-27; rewritten by the integrator 2026-09-27: sets are logged, never removed)
- [ ] Performance with a long history (1–2 years, ~300 workouts): History tab, calendar month switching and Stats open without visible lag; logging sets in the active workout stays smooth while the History tab is alive. (history, 2026-09-27)
- [ ] Device in a UTC+2/+3 time zone: a workout started just after midnight shows on that day in the calendar and in that week in Stats; the calendar week starts on Saturday in Arabic, Sunday in English. (history, 2026-09-27)
- [ ] VoiceOver / TalkBack: calendar days read the full date and the workout count; the 🏆 badge on a card reads "N personal records". (history, 2026-09-27)

### Integration round 2 (2026-09-27)

- [ ] The keypad's ± key gives a light selection haptic on every screen that edits sets (live workout, past workout, routine editor), same feel everywhere. (integrator, 2026-09-27)
- [ ] Library/picker search on a real keyboard: type, use the keyboard's undo (iOS shake / three-finger swipe, Android keyboard undo) — the result list follows the text in the field every time; × clears and the full list returns. (integrator, 2026-09-27)
- [ ] History header with a large all-time total (e.g. a restored backup over 100,000 kg): shows `450K kg` / `1.2M kg` in English and `450 ألف kg` / `1.2 مليون kg` in Arabic, reading right-to-left, and counts up smoothly on change. (integrator, 2026-09-27)

### Settings, backup, licences (window E, round 3)

_(window E appends here only)_
- [ ] Export on a real phone (both platforms): the share sheet opens with `azm-backup-YYYYMMDD-HHmm.json`; save it to **Files / Downloads**, send it to **Google Drive** and to **WhatsApp** (as a document). The saved file opens as readable JSON. On iPad the sheet is anchored to the Export row. (window E, 2026-09-27)
- [ ] Import on a real phone: pick the backup from **Files** (iOS), **Downloads** and **Drive** (Android document picker), and from a WhatsApp-received copy. The confirmation shows the right date and counts; after Restore, routines, history, PRs, unit, rest time, language and theme match the source phone. (window E, 2026-09-27)
- [ ] Round trip across phones: export on phone A (with a few months of history), import on phone B (fresh install, after onboarding) and on another platform (Android → iOS and back): History totals, calendar, stats and PRs are identical. (window E, 2026-09-27)
- [ ] Large backup (e.g. 2+ years, 500 workouts, ~15,000 sets): export and import each finish within a few seconds with no ANR/jank; the busy spinner shows on the row meanwhile. (window E, 2026-09-27)
- [ ] Import errors on a device: pick a photo/PDF (→ "isn't a JSON file"), some other `.json` (→ "isn't an Azm backup"), a backup edited to `"version": 2` (→ "newer version"), a truncated backup (→ "isn't a JSON file" or "damaged"). Each time the data is unchanged. Try importing during a workout → refused. (window E, 2026-09-27)
- [ ] Licences → "Open-source packages" on a release/profile build lists **every** package (flutter, drift, go_router, …) plus "exercises-dataset (Hasan Emir Yıldırım)" and "Readex Pro font"; tapping them shows the MIT and OFL texts. (Integration tests can't show the package list: the test binding never loads NOTICES.) (window E, 2026-09-27)

### Brand: icons, splash (window F, round 3)

_(window F appends here only)_

Reference: `brand/exports/review_sheet.png` (every variant) and `docs/screenshots/brand/{android,ios}/` (emulator + simulator captures).

- [ ] **Pixel (Android 13+), stock launcher:** home screen + app drawer icon: black circle, blue plate, white lifter; nothing clipped. Long-press → the same icon in the shortcut popup.
- [ ] **Pixel, themed icons on** (Wallpaper & style → Themed icons): Azm shows the monochrome mark (plate with its hole, lifter, line) in the wallpaper tint, not the full-colour icon.
- [ ] **Samsung One UI launcher** (squircle mask) and one other launcher with a different mask (e.g. a teardrop/square): mark centred, nothing cut off, the line's ends inside the mask.
- [ ] **Android < 12 device if available:** launch window = black + the mark in the centre, no white flash before the first screen.
- [ ] **Android 12+:** splash = black background + the mark, then the app; with the system in **light** mode too (the splash stays dark by design).
- [ ] **Rest-timer notification** (tick a set, leave the app, let the rest end): status-bar icon is the white mark (plate + lifter), legible, not a white square; expanded notification shows the same mark.
- [ ] **iPhone (iOS 18+):** home screen icon in **Light**, **Dark** and **Tinted** (long-press home screen → Edit → Customize): light = black plate square; dark = blue/white mark on the system dark backdrop; tinted = grayscale mark taking the tint.
- [ ] **iPhone:** Settings → Notifications, Spotlight and the app switcher show the icon sharp (Xcode derives the small sizes from the 1024 image).
- [ ] **iPhone:** launch screen = black + the mark centred, same size as on Android; no white flash (cold launch after deleting and reinstalling: iOS caches launch screens).
- [ ] **iPhone launch screen colour:** the plate is the same blue as the app's accent (`#4D9BFF`, e.g. the Next button in onboarding), not a more saturated blue (the simulator capture showed `#239DFF`).
- [ ] **Small-size legibility on real screens:** at the smallest system sizes (Android notification shade, iOS Settings list 29 pt, Spotlight) the plate and the rising line read; the lifter may read as a white shape at 16–20 px (expected, see `brand/exports/legibility_16-64px.png`).

### Integration round 3 (2026-09-27)

- [ ] **Upgrade install on a real phone** (both platforms): install a pre-round-3 build, log a workout with an exercise that is now hidden (e.g. 0077 "Barbell Rear Lunge V. 2"), then install this build over it. The app opens, the old workout still shows that exercise's name in History, and the library no longer lists 0077 (1,291 exercises).
- [ ] **App version on a release/TestFlight build:** Settings → About and Licences show the store version; an exported backup's `app_version` is `version+build` of that build (e.g. `1.0.0+1`).
- [ ] **Search with Egyptian spellings on a real keyboard (Gboard + iOS Arabic):** ضهر / ظهر, دراع / ذراع, تقيل / ثقيل, فخد / فخذ return the same exercises.

### Tester APK (2026-09-27)

- [ ] **Install from the GitHub release on a real Android phone:** open the private release page logged in, download `azm-1.0.0-rc1-<build>.apk`, allow "Install unknown apps" for the browser/Files, install. Play Protect may warn about an unknown developer: "Install anyway". The app opens, onboarding shows.
- [ ] **Update path:** with build N installed and some workouts logged, install build N+1 from its release: it installs as an update (no uninstall), data is kept, About shows the new version.
- [ ] **Rest notification on the real phone from the release build:** tick a set, lock the phone, the notification arrives on time with the white Azm mark (status bar + lock screen), sound/vibration per the system settings.

### Exercise quick preview + looping GIFs (2026-09-28)

Media shows only in the owner's `personal` build (or a dev run with `tools/serve_media_dev.dart`); tester builds show the fallback icon.

- [ ] **Personal build on a real Android phone, airplane mode:** tap the thumbnail of a row in the library, the picker, the active workout, a routine, a past workout and Stats → the sheet opens with the GIF playing and looping, the name in the app language, "© Gym visual — https://gymvisual.com/" under it; tapping the rest of the row still opens the detail / selects / etc.
- [ ] **Play-once GIFs keep looping on the phone:** open 0053 (or any of the 27 GIFs without a loop block, e.g. 0087, 0105, 0114, 0295) in the preview and on the detail screen: still moving after 10 s.
- [ ] **Memory on a low-end phone:** open and close the preview ~30 times quickly from a long library scroll: no stutter building up, no crash; the app's memory (Android Studio profiler or `adb shell dumpsys meminfo app.azm.gym.personal`) drops back after the sheets close.
- [ ] **Swipe down / tap outside / system Back** all close the preview; with TalkBack / VoiceOver the thumbnail reads "Preview <name>" / "معاينة حركة <name>" as a button.

### Delete a set + exercise filters (2026-09-28)

- [ ] **Swipe feel on real phones (2026-09-28 redesign):** the row follows the finger at 60 fps with no lag at the start; the red panel reaches the screen edge; "Delete"/"امسح" is never cut off (also with the largest system font size: then only the trash icon shows until the panel is wide enough); release at ~1/3 rests open, at ~2/3 deletes with a light haptic tick when crossing; only one row stays open; scrolling closes it.
- [ ] **Swipe vs. system back gesture (Android gesture navigation + iPhone edge swipe):** swipe a set from the middle of the row toward the start edge (left in English, right in Arabic): it deletes and never triggers Back/minimize. Starting the swipe right at the screen edge may be taken by the system: note how far from the edge it starts to work.
- [ ] **Long-press on a set row:** ~0.5 s opens the set menu with a selection haptic; a normal tap on weight/reps/✓/label still does its own thing; scrolling the workout with a finger resting on a row doesn't open the menu.
- [ ] **Undo snackbar on a real phone:** readable above the keypad, the rest timer bar and the home indicator; "Undo" is easy to hit within the ~4 s; with TalkBack / VoiceOver the snackbar is announced and stays until acted on is acceptable (the OS may extend it).
- [ ] **Delete during a running rest timer / after ✓:** the timer keeps running, Lifted and the set count drop at once, Undo brings both back.
- [ ] **Filter sheets on a small phone (iPhone SE size, Android 5 inch):** the three chips fit side by side in Arabic and English; the Muscle group sheet scrolls to "Other" with the Show / Clear buttons always visible above the home indicator; cards are easy to tap.
- [ ] **Filter icons at real size:** every muscle highlight is recognizable at 44 dp (esp. abductors, adductors, neck, lats vs. upper back) in dark and light themes.
- [ ] **Remembered filters:** set filters in the library, kill the app, reopen: the library is still filtered (chip counts), the picker keeps its own filters.
