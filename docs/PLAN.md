# Azm — Plan (backlog by folder ownership)

**How to use this file:** each task **owns** a set of paths. An agent edits ONLY the paths its task owns. Everything else is read-only for it. That lets several Claude Code windows run in parallel without touching the same files. Need something outside your paths? Add it under **Requests** at the bottom and work around it. Status marks: `[ ]` todo · `[~]` in progress (write your window/date) · `[x]` done.

**Frozen for feature windows** (changed only by the owner / a bootstrap-type task): `app/pubspec.yaml`, `app/lib/{app,main,bootstrap}.dart`, `app/lib/core/{router,db,theme,utils,media}/**`, `app/lib/core/l10n/*.dart`, `app/integration_test/screenshot_harness.dart`, `tools/**`, `env.sh`, `CLAUDE.md`.
**Append-only, shared:** `docs/PLAN.md` (your own section + Requests), `docs/DECISIONS_LOG.md`, `docs/DEVICE_TEST_CHECKLIST.md`.
**Generated, never hand-edited** (regenerate after any merge): `app/lib/core/l10n/arb/*`, `app/lib/core/l10n/gen/*` (`tools/gen_l10n.sh`), `*.g.dart` (`dart run build_runner build`), `app/assets/catalog/*` (`tools/build_catalog.sh`).
**Strings:** each owner has its own ARB fragment `app/lib/core/l10n/arb_src/<owner>/{ar,en}.arb`, with keys prefixed by the owner (`workout…`, `exercises…`). `tools/gen_l10n.sh` merges and validates them.

**Definition of done for every task** (CLAUDE.md): `flutter analyze` + `flutter test` + `tools/check_directionality.sh` pass; **Platform Parity Rule**, meaning `tools/screenshots.sh <feature>` captures every screen on the Android emulator AND the iOS Simulator in Arabic and English into `docs/screenshots/<feature>/`, and the images were reviewed; real-device-only checks added to `docs/DEVICE_TEST_CHECKLIST.md`; assumptions logged in `docs/DECISIONS_LOG.md`; committed locally, never pushed.

## Parallel windows (how to run two agents at once)

Two windows in the **same checkout** would overwrite each other's `app/build`, `.dart_tool` and generated files, and install onto the same devices. So each window gets its **own git worktree + branch + device set**:

```sh
# from ROOT, once per window (worktrees live inside ROOT, gitignored):
git worktree add .worktrees/exercises -b feature/exercises
git worktree add .worktrees/workout   -b feature/workout
# open Claude Code in ROOT/.worktrees/<name>. Its env.sh finds the shared ROOT/.tooling automatically.
# exercises window: export AZM_DEVICE_SET=A   (azm_api37 + "Azm iPhone A")
# workout window:   export AZM_DEVICE_SET=B   (azm_api37_b + "Azm iPhone B")
# first command in a new worktree: source ./env.sh && cd app && flutter pub get
```

Merging (owner, or one window after both are done): commit in each worktree → from ROOT `git merge feature/exercises` then `git merge feature/workout`. Because ownership doesn't overlap, the only conflicts can be in **generated** files. Resolve them by taking either side and re-running `tools/gen_l10n.sh` (+ `build_runner` if needed). Then run the full definition of done on `main`, and `git worktree remove .worktrees/<name>`.

---

## 0. Bootstrap — DONE (2026-09-26)

All four bootstrap phases are complete; sections 1–10 below are the remaining work. What exists and can be built on:
- **DB** `app/lib/core/db/`: `AppDatabase` (all tables, one-active-workout index, `readSetting`/`writeSetting`), `CatalogInstaller`, `CatalogRepository` (`search`, `exercise`, `exercisesByIds`, `programs`). Provider: `appDatabaseProvider`, `catalogRepositoryProvider`.
- **Logic** `app/lib/core/utils/`: `normalizeForSearch`, `Units` (kg↔lb, keypad step), `liftedKg`, `epley1Rm`, `detectPrs`/`PrBests`, `liftedComparison`, `SetType`.
- **Media** `app/lib/core/media/`: `MediaResolver` (+ `mediaResolverProvider`), `ExerciseThumbnail` (lists), `ExerciseAnimation` (detail only).
- **Settings** `features/settings/data/app_settings.dart`: language + theme, persisted.
- **Routes** (all pre-registered in `core/router/app_router.dart`, placeholders in the owning feature): tabs `workout`/`history`/`exercises`, pushed `settings`, `exercise(id)`, `exercisePicker`, `activeWorkout`, `workoutSummaryFor(id)`; shell slot `ActiveWorkoutBarSlot` above the tab bar.
- **Names**: `context.namesOf(exercise)` → primary/secondary per SPEC.
- **Tools**: `build_catalog.sh`, `gen_l10n.sh` (ARB fragments → merged + gen-l10n), `check_directionality.sh`, `screenshots.sh <feature>` (parity screenshots, both platforms, ar + en), `serve_media_dev.dart`, `relocate.sh`.
- **Devices**: set A = `azm_api37` + "Azm iPhone A", set B = `azm_api37_b` + "Azm iPhone B".



| Phase | Status | Owns |
|---|---|---|
| Phase 0: sandboxed tooling (`env.sh`, `.tooling/`) | [x] | `env.sh`, `ios_env`, `.tooling/` |
| Phase 1: project folder, docs, data import, git | [x] | everything at ROOT |
| **Phase 2: Flutter skeleton** | [x] (iOS build not yet run — see DECISIONS_LOG) | `app/**`, `tools/check_directionality.sh` |
| **Phase 3: data layer** | [x] | `app/lib/core/db/**`, `app/lib/core/utils/**`, `app/lib/core/media/**`, `tools/build_catalog.dart`, `data/ar/**` (first 50), `data/programs/**`, `data/catalog/**`, `app/test/**` |

Phase 2 acceptance: `flutter create` (org `app.azm.gym`, android+ios); deps pinned in README; Readex Pro the only font; gen-l10n with ar/en and the System/ع/EN setting; localized launcher name (`عزم`/`Azm`); theme ported with gym adaptations (dark default); `go_router` `StatefulShellRoute` with 3 tabs + glass tab bar + settings route; directionality check script; zero hard-coded strings.

Phase 3 acceptance: Drift schema per DATA.md; `build_catalog` produces `catalog.sqlite`; catalog replace-on-version logic; shared normalizer; 50 Arabic names (owner-reviewed 2026-09-26); 3 programs; `MediaResolver` with base-URL config + fallback; unit tests for normalization, lifted total, PR detection, kg↔lb, catalog update not touching user data.

---

## 1. WORKOUT window — logging, rest timer, summary  (branch `feature/workout`, device set **B**) — [x] done 2026-09-26 (window B), not merged yet

- **Goal:** the core loop: start (empty or from a routine), log sets, rest, finish, see the summary. North star: app open → first set logged in ≤ 3 taps.
- **Owns (only these):**
  - `app/lib/features/workout/**`: already contains the pre-registered placeholders `workout_home_screen.dart` (Workout tab), `active_workout_screen.dart` (route `AppRoutes.activeWorkout`), `workout_summary_screen.dart` (route `AppRoutes.workoutSummaryFor(id)`) and `active_workout_bar_slot.dart` (rendered by the shell above the tab bar). Keep those class names and constructors.
  - `app/lib/core/widgets/{set_row,weight_keypad,rest_timer_bar,active_workout_bar,lifted_counter}.dart`
  - `app/lib/core/l10n/arb_src/workout/{ar,en}.arb` (keys `workout…`)
  - `app/test/features/workout/**`, `app/integration_test/workout_screens_test.dart`, `docs/screenshots/workout/**`
  - Native notification setup (this window only, this round): `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/src/main/res/**` (notification icon), `app/ios/Runner/AppDelegate.swift`, `app/ios/Runner/Info.plist`
- **Uses, read-only:** `AppDatabase` tables `workouts`/`workout_exercises`/`workout_sets`/`settings` (write your queries in `features/workout/data/`), `core/utils` (`liftedKg`, `detectPrs`, `PrBests`, `liftedComparison`, `Units`, `SetType`), `context.namesOf(e)`, `ExerciseThumbnail`, `AzmMotion`/tokens.
- **Contract with EXERCISES:** add exercises with `final ids = await context.push<List<String>>(AppRoutes.exercisePicker);`. You get catalog ids in selection order, or null if cancelled. Until the exercises window ships the picker, the placeholder returns null. Handle that, and seed exercises directly in the DB for tests/screenshots.
- **Acceptance:**
  - [x] Workout tab home: big "Start workout" (empty workout) → active workout in 1 tap. Routines/programs lists come later (routines task).
  - [x] Active workout: exercises with SetRows (type · previous · weight · reps · ✓), add exercise (picker contract above), add/remove sets, reorder exercises.
  - [x] Set type menu on label tap; labels `إ/W`, `د/D`, `ف/F`, numbers for normal sets; warm-up in amber; failure never red.
  - [x] "Previous" = same set index from the last finished workout with that exercise; tap fills weight + reps.
  - [x] ✓ → `setDoneTint`, light haptic, rest timer auto-starts (per-exercise override → default 90 s).
  - [x] Swipe to delete (toward the end edge, mirrored in RTL).
  - [x] WeightKeypad (digits, decimal, ±2.5 in the display unit via `Units.stepKg`, backspace, next/done); never the system keyboard.
  - [x] Header: duration | Lifted | sets; Lifted animates (`AzmMotion.value`, 600 ms; reduced motion respected).
  - [x] Every edit persisted immediately; kill the app mid-workout → reopen resumes exactly (at most one `active` workout; the DB enforces it).
  - [x] Minimize → `ActiveWorkoutBarSlot` shows the ActiveWorkoutBar (name, elapsed, mini rest timer) on every tab; tap restores.
  - [x] RestTimerBar from an end timestamp + scheduled local notification; −15/+15/skip; haptic + sound at end; survives background/kill (`active_rest_ends_at`, `active_rest_notification_id` settings keys).
  - [x] Notification setup for `flutter_local_notifications` 22 (per its README): Android receivers, `POST_NOTIFICATIONS` (13+), exact vs inexact alarms (decide + log), iOS permission request, localized text. Desugaring is already on.
  - [x] Finish → summary (`workoutSummaryFor(id)`): duration, Lifted + comparison (SPEC rule), PRs with celebration (🏆, `celebrate` spring), best set per exercise. Discard with confirmation.
  - [x] Tests: SetRow states, keypad, timer remaining-time math, persistence/resume, previous-set lookup.
  - [x] Parity: `AZM_DEVICE_SET=B tools/screenshots.sh workout`, covering home, active workout (with seeded sets: normal/warm-up/drop/failure, some ✓, a PR), keypad open, rest timer running, minimized bar on another tab, summary, in ar + en on both platforms. Checklist items: haptics, timer sound/vibration, notification delivery (background, killed, locked), exact alarms on Android 14+.
- **Merge notes (window B, 2026-09-26):**
  - **Remove at merge (DEBUG ONLY):** `app/lib/features/workout/debug/debug_seed.dart`, the `kDebugMode` "DEBUG: add sample exercises" button in `features/workout/ui/active_workout_screen.dart` (+ its `debug_seed.dart` import), and the ARB key `workoutDebugSeed` in `arb_src/workout/{ar,en}.arb` (then `tools/gen_l10n.sh`). Once the real picker is merged, check `Add exercise` → picker → exercises appear in selection order.
  - `ActiveWorkoutBarSlot` is now a `ConsumerStatefulWidget` (same name + const constructor).
  - After merging, re-run `tools/gen_l10n.sh` (generated ARB/gen files will conflict) and the full definition of done on `main`.

## 2. `app/lib/features/routines/**` — Routines & ready programs

- **Owns:** `app/lib/features/routines/**`, `app/test/features/routines/**`, `app/lib/core/l10n/arb_src/routines/**`, `app/integration_test/routines_screens_test.dart`, `docs/screenshots/routines/**` (needs a routine-editor route → Request)
- **Acceptance:**
  - [ ] Routine list (Workout tab section) and editor: name, notes, add exercises (multi-select picker), target sets (type, reps, optional weight), rest override, drag to reorder, delete.
  - [ ] Start routine in one tap → active workout prefilled.
  - [ ] Ready programs list (`CatalogRepository.programs()`) → "Add to my routines" copies them as editable routines, names in the app language; `target_reps` = range max (DATA.md).
  - [ ] Onboarding hook: the program chosen in onboarding is copied on finish.

## 3. EXERCISES window — library, picker, detail  (branch `feature/exercises`, device set **A**) — DONE 2026-09-26 (awaiting merge)

- **Goal:** find any exercise fast in Arabic, Egyptian slang or English; pick several for a workout/routine; see an exercise's details and your own history with it.
- **Owns (only these):**
  - `app/lib/features/exercises/**`: already contains the pre-registered placeholders `exercises_screen.dart` (Exercises tab), `exercise_detail_screen.dart` (route `AppRoutes.exercise(id)`) and `exercise_picker_screen.dart` (route `AppRoutes.exercisePicker`). Keep those class names and constructors.
  - `app/lib/core/widgets/{exercise_card,muscle_chips}.dart`
  - `app/lib/core/l10n/arb_src/exercises/{ar,en}.arb` (keys `exercises…`, including the localized dataset keys, e.g. `exercisesTargetPectorals`, `exercisesEquipmentBarbell`, `exercisesBodyPartChest`)
  - `app/test/features/exercises/**`, `app/integration_test/exercises_screens_test.dart`, `docs/screenshots/exercises/**`
- **Uses, read-only:** `CatalogRepository` (`search(query, target:, equipment:)`, `exercise`, `exercisesByIds`), `ExerciseThumbnail` / `ExerciseAnimation`, `mediaResolverProvider`, `context.namesOf(e)`, workout tables for "your history" (queries in `features/exercises/data/`), `epley1Rm`/`PrBests.fromSets`, `Units`, tokens.
- **Contract with WORKOUT (you provide):** `ExercisePickerScreen` = multi-select, search + filters like the library, selection order visible (1, 2, 3…), confirm → `context.pop(<String>[ids in selection order])`, back/cancel → `context.pop()` (null). Keep this exact contract. Routines will use it too.
- **Acceptance:**
  - [x] Library: search box (normalized AR/slang/EN via `CatalogRepository.search`), MuscleChips (target), equipment filter bottom sheet, list of ExerciseCards (thumbnail with fallback icon, primary + secondary name, PR badge if any). Empty and no-results states.
  - [x] Two names per row via `context.namesOf`; English-only exercises show just the English name.
  - [x] Picker (contract above).
  - [x] Detail: GIF via `ExerciseAnimation` (only here) + attribution line "© Gym visual — https://gymvisual.com/" when media is shown; instructions (AR if present, else EN); target + secondary muscles + equipment (localized); your history (recent sets), chart (best set / e1RM / volume over time), PRs. Empty states when there's no history.
  - [x] Search < 50 ms for any query over 1,324 rows (measure on the emulator; add a real-device check to the checklist). Result: in-memory index, worst query 17.5 ms on the debug emulator (see DECISIONS_LOG); real-device check in the checklist.
  - [x] Tests: search UI (Arabic, slang, English, filters), picker returns ordered ids, names logic in cards, detail with and without history.
  - [x] Parity: `AZM_DEVICE_SET=A tools/screenshots.sh exercises`, covering library (default, a search in Arabic, filtered), equipment sheet, picker with 3 selected, detail with no media (fallback) and with seeded history, in ar + en on both platforms. (With the dev media server + `AZM_MEDIA_ALLOW_ALL`, media may appear in LOCAL screenshots only. **Never commit screenshots that show Gym visual media**, see LICENSES.md; commit the fallback versions.)

## 4. `app/lib/features/history/**` — History, stats, PRs

- **Owns:** `app/lib/features/history/**`, `app/test/features/history/**`, `app/lib/core/l10n/arb_src/history/**`, `app/integration_test/history_screens_test.dart`, `docs/screenshots/history/**` (needs a past-workout route → Request)
- **Acceptance:**
  - [ ] List of workout cards (name, date, duration, Lifted, PR count, best set per exercise) + calendar view toggle.
  - [ ] All-time Lifted header ("شِلت لحد دلوقتي …"), with compact number formatting (e.g. 1.2 مليون / 1.2M).
  - [ ] Past workout detail, editable (same SetRow components); edits recompute PRs.
  - [ ] Stats: workouts per week, total sets, per-exercise PR list.

## 5. `app/lib/features/settings/**` — Settings, onboarding, backup

- **Owns:** `app/lib/features/settings/**`, `app/test/features/settings/**`, `app/lib/core/l10n/arb_src/settings/**`, `app/integration_test/settings_screens_test.dart`, `docs/screenshots/settings/**`
- **Acceptance:**
  - [x] Language (System/العربية/English) + theme (dark/light), persisted (Phase 2/3).
  - [ ] Unit (kg/lb), default rest time, backup export/import, Licenses page (MIT dataset + OFL font + Gym visual attribution when media is shown).
  - [ ] Onboarding (first run, ≤ 2 screens): unit; optional ready program.
  - [ ] Backup export via the share sheet (format in DATA.md); import with confirmation replaces user tables; round-trip test.

## 6. `data/ar/**` — Arabic names for the remaining exercises

- **Owns:** `data/ar/exercise_names_ar.json` (append-only per batch; never rename existing keys)
- **Goal:** Egyptian-gym Arabic name + slang aliases for the remaining **1,274** exercises (50 done in Phase 3), in **batches of 100** ordered by likely usage (barbell/dumbbell/cable/machine staples first; stretches and rare equipment last). All new entries `reviewed: false`. After each batch run `tools/build_catalog.sh` (validates ids, bumps the catalog version, refreshes the app asset) and commit the updated asset + `catalog_version.json`.
- **Acceptance per batch:** 100 new ids; each has `ar` + ≥ 0 aliases; ids validated by `build_catalog`; list the batch in the PR/commit message for native review.
- [ ] Batch 1 … [ ] Batch 13 (final). Start with the variants of the first 50 (incline/decline/smith/cable versions, other curls/rows/presses) so related exercises read consistently.
- [ ] Owner review pass: flip `reviewed` to `true` after human review.
- [ ] Later: `instructions_ar` translation (separate task, same batching).

## 7. `brand/**` — Icon and splash exports

- **Owns:** `brand/**`, and on hand-off `app/android/app/src/main/res/mipmap-*`, `app/ios/Runner/Assets.xcassets/AppIcon.appiconset` (coordinate with whoever owns `app/` scaffolding)
- **Acceptance:**
  - [ ] Refine `logo-concept-a.svg` (owner approval).
  - [ ] Android adaptive icon (foreground + background) + **monochrome** layer; legacy mipmaps; Play 512×512.
  - [ ] iOS 1024 icon with **light, dark, tinted** variants.
  - [ ] Splash (Android 12 splash API + iOS launch screen), dark background.

## 8. `tools/**` — Scripts

- **Owns:** `tools/**` (except files owned by bootstrap phases)
- **Acceptance:**
  - [ ] `tools/upload_media_r2.dart`: uploads **only licensed** ids (allow-list file) to R2 using credentials from a gitignored `.env`; refuses to run on unlicensed ids; prints the base URL for `MediaResolver`. **Blocked until media is purchased** (LICENSES.md).
  - [x] `tools/serve_media_dev.dart`: local static server for `media/` (dev only), done in Phase 3.
  - [ ] CI-style `tools/check_all.sh`: `flutter analyze` + `flutter test` (app) + `dart analyze` (tools) + directionality + `build_catalog` (validation, and fail if the committed asset is stale).
  - [x] Verify the iOS build: done 2026-09-26 (simulator build, launch, RTL, font, localized name, first-launch catalog install; screenshots in `docs/screenshots/shell/`).

## 9. Crashlytics — `app/lib/core/crash/**` + Firebase config

- **Owns:** `app/lib/core/crash/**`, `app/android/app/google-services.json`, `app/ios/Runner/GoogleService-Info.plist` (both gitignored), minimal edits to `main.dart`
- **Blocked:** needs the owner's Firebase project.
- **Acceptance:** [ ] `firebase_core` + `firebase_crashlytics` wired, disabled in debug, `FlutterError.onError` + `PlatformDispatcher.onError` forwarded; no PII.

## 10. Owner actions (not agent tasks)

- [ ] Review the 50 Arabic names (Phase 3 report).
- [ ] Buy the Gym visual license for ~150–200 exercises; record it in LICENSES.md.
- [ ] Create Cloudflare R2 bucket + custom domain; create Firebase project.
- [ ] Apple Developer + Google Play accounts; signing keys (kept out of git).

## Requests

_(Cross-folder requests go here: "@owner-of-X: need Y". Remove when handled.)_

- **@owner (theme):** tokens for the exercise detail/chart: `AzmSize.chartHeight` (144), `AzmSize.exerciseMedia` (216), chart stroke (2) and dot radius (4). Exercises currently derives them from existing tokens (`thumbnailCard × 2/3`, `opticalInset`, `xxs`); swap them in when they exist. (exercises, 2026-09-26)
- **@settings:** expose a shared `weightUnitProvider` (reads/writes the `unit` setting) in `features/settings/data/`. Exercises reads the key directly via `exercisesWeightUnitProvider` for now; switch it over when yours exists. (exercises, 2026-09-26)
- **@history:** per-exercise history for the detail screen and the library 🏆 badges goes through `ExerciseHistorySource` (`features/exercises/data/exercise_history.dart`). Override `exerciseHistorySourceProvider` if you need other rules (e.g. edited workouts). A "see all history" route from the detail screen would need a new route. (exercises, 2026-09-26)

- @owner (window B, 2026-09-26): make `timezone` a **direct** dependency in `app/pubspec.yaml` (same version as resolved, `^0.11.0`); `features/workout/data/rest_notifications.dart` imports it for `TZDateTime` with a lint suppression until then.
- @owner / data docs (window B, 2026-09-26): add the settings keys `active_rest_total_seconds` (int, rest length incl. ±15, for the progress bar) and `workout_notifications_asked` (bool) to DATA.md → Settings keys.
- @settings (window B, 2026-09-26): the workout reads `unit` (`"kg"`/`"lb"`) and `default_rest_seconds` (int) from settings on every detail load; writing them from the settings screen is enough, no API needed.
- @brand (window B, 2026-09-26): the Android notification icon `res/drawable/ic_stat_azm.xml` is a placeholder dumbbell; replace with the final monochrome mark.
