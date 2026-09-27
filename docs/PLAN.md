# Azm — Plan (backlog by folder ownership)

**How to use this file:** each task **owns** a set of paths. An agent edits ONLY the paths its task owns. Everything else is read-only for it. That lets several Claude Code windows run in parallel without touching the same files. Need something outside your paths? Add it under **Requests** at the bottom and work around it. Status marks: `[ ]` todo · `[~]` in progress (write your window/date) · `[x]` done.

**Frozen for feature windows** (changed only by the owner / a bootstrap-type task): `app/pubspec.yaml`, `app/lib/{app,main,bootstrap}.dart`, `app/lib/core/{router,db,theme,utils,media}/**`, `app/lib/core/l10n/*.dart`, `app/integration_test/screenshot_harness.dart`, `tools/**`, `env.sh`, `CLAUDE.md`.
**Append-only, shared:** `docs/PLAN.md` (your own section + Requests), `docs/DECISIONS_LOG.md`, `docs/DEVICE_TEST_CHECKLIST.md`.
**Generated, never hand-edited** (regenerate after any merge): `app/lib/core/l10n/arb/*`, `app/lib/core/l10n/gen/*` (`tools/gen_l10n.sh`), `*.g.dart` (`dart run build_runner build`), `app/assets/catalog/*` (`tools/build_catalog.sh`).
**Strings:** each owner has its own ARB fragment `app/lib/core/l10n/arb_src/<owner>/{ar,en}.arb`, with keys prefixed by the owner (`workout…`, `exercises…`). `tools/gen_l10n.sh` merges and validates them.

**Definition of done for every task** (CLAUDE.md): `flutter analyze` + `flutter test` + `tools/check_directionality.sh` pass; **Platform Parity Rule**, meaning `tools/screenshots.sh <feature>` captures every screen on the Android emulator AND the iOS Simulator in Arabic and English into `docs/screenshots/<feature>/`, and the images were reviewed; real-device-only checks added to `docs/DEVICE_TEST_CHECKLIST.md`; assumptions logged in `docs/DECISIONS_LOG.md`; committed locally, never pushed.

## Parallel windows (how to run two agents at once)

Two windows in the **same checkout** would overwrite each other's `app/build`, `.dart_tool` and generated files, and install onto the same devices. So each window gets its **own git worktree + branch + device set**.

**Round 2 (2026-09-27): window C = routines + onboarding (§2), window D = history + stats + PRs (§4).**

| Window | Task | Branch / worktree | Device set | Screenshot features |
|---|---|---|---|---|
| **C** | §2 Routines, ready programs, onboarding | `feature/routines` · `.worktrees/routines` | **A** (`azm_api37` :5554 + "Azm iPhone A") | `routines`, `onboarding` |
| **D** | §4 History, stats, PRs, Lifted total | `feature/history` · `.worktrees/history` | **B** (`azm_api37_b` :5556 + "Azm iPhone B") | `history` |

```sh
# from ROOT, once per window (worktrees live inside ROOT, gitignored):
git worktree add .worktrees/routines -b feature/routines
git worktree add .worktrees/history  -b feature/history
# open Claude Code in ROOT/.worktrees/<name>. Its env.sh finds the shared ROOT/.tooling automatically.
# C (routines) window: export AZM_DEVICE_SET=A   (azm_api37 + "Azm iPhone A")
# D (history) window:  export AZM_DEVICE_SET=B   (azm_api37_b + "Azm iPhone B")
# first command in a new worktree: source ./env.sh && cd app && flutter pub get
# ownership check (must print OK): source ./env.sh && dart run tools/check_plan_overlap.dart C D
```

**Pre-registered on `main` for round 2** (so neither window edits a shared or frozen file). Keep every class name, constructor and function signature below; replace the placeholder bodies.

| What | Frozen side (done, don't edit) | Owner's side (placeholder → implement) |
|---|---|---|
| Route `AppRoutes.onboarding` | router; **initial location** = onboarding while `onboardingDoneAtLaunchProvider` is false | C: `features/onboarding/ui/onboarding_screen.dart` `OnboardingScreen()` |
| First-run gate | `bootstrapApp()` overrides `onboardingDoneAtLaunchProvider` with `await loadOnboardingDone(db)`; runs with `settingsOverride` (screenshots, integration tests) always count as done | C: `features/onboarding/data/onboarding_gate.dart` `loadOnboardingDone(AppDatabase)` (placeholder returns `true`) + `onboardingDoneAtLaunchProvider` |
| Routes `routineNew`, `routineEditorFor(id)` | router | C: `features/routines/ui/routine_editor_screen.dart` `RoutineEditorScreen({String? routineId})` |
| Routes `programs`, `programFor(id)` | router | C: `features/routines/ui/{programs_screen,program_detail_screen}.dart` `ProgramsScreen()`, `ProgramDetailScreen({required programId})` |
| Workout-tab slot | `WorkoutHomeScreen` renders `const RoutinesHomeSection()` under the Start/Resume card | C: `features/routines/ui/routines_home_section.dart` |
| Route `pastWorkoutFor(id)` | router | D: `features/history/ui/past_workout_screen.dart` `PastWorkoutScreen({required workoutId})` |
| Route `stats` | router | D: `features/history/ui/stats_screen.dart` `StatsScreen()` |
| Route `exerciseHistoryFor(id)` | router | D: `features/history/ui/exercise_history_screen.dart` `ExerciseHistoryScreen({required exerciseId})` |
| Exercise-detail slot ("See all history") | `ExerciseDetailScreen` renders `ExerciseHistoryLinkSlot(exerciseId:, sessionCount:)` under its recent sessions | D: `features/history/ui/exercise_history_link_slot.dart` |
| Exercise history hook (Request from exercises) | `bootstrapApp()` overrides `exerciseHistorySourceProvider` with `createExerciseHistorySource(db)` | D: `features/history/data/history_exercise_source.dart` (default returns `DbExerciseHistorySource`) |
| ARB fragments | `tools/gen_l10n.sh` picks up every folder | C: `arb_src/routines/` (`routines…`) + `arb_src/onboarding/` (`onboarding…`); D: `arb_src/history/` (`history…`) |
| Shared docs | per-window sections already created | append only inside your own section of `docs/DECISIONS_LOG.md`, `docs/DEVICE_TEST_CHECKLIST.md` and *Requests* below |

`test/core/router/pre_registered_routes_test.dart` (core) checks that every route above opens its screen. Keep it passing.

**Shared, read-only for both** (use, never edit): `features/workout/**` (`WorkoutRepository`: `startEmpty`, `active`, `loadDetail`/`watchDetail`, `updateSet`, `setCompleted`, `deleteSet`, `previousSets`, `prBests`, …), `features/exercises/**` (picker contract, `exerciseHistoryProvider`, `exerciseRecordsProvider`), `features/settings/**` (`TrainingSettingsWriter`, `weightUnitProvider`, `defaultRestSecondsProvider`), `core/widgets/**` (incl. `SetRow`, `WeightKeypad`, `LiftedCounter`), `core/{db,utils,theme,l10n,router,media}`. Write your own queries in your own `data/` folder. Need a change there (new theme token, DB index, repository method, …)? Add it to *Requests* and work around it; the integrator applies it at merge.

Merging (owner, or one window after both are done): commit in each worktree → from ROOT `git merge feature/routines` then `git merge feature/history`. Because ownership doesn't overlap, the only conflicts can be in **generated** files. Resolve them by taking either side and re-running `tools/gen_l10n.sh` (+ `build_runner` if needed). Then run the full definition of done on `main`, and `git worktree remove .worktrees/<name>`.

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
  - [x] Set type menu on label tap; labels `ح/W` (was `إ`, changed at integration), `د/D`, `ف/F`, numbers for normal sets; warm-up in amber; failure never red.
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
  - **Done at integration (2026-09-26):** debug seeding removed; real picker in use.

## 1b. INTEGRATION — merge exercises + workout (main) — [x] done 2026-09-26

- [x] Merged `feature/exercises` then `feature/workout`; conflicts (docs only) logged in DECISIONS_LOG.
- [x] Workout debug seeding removed; `Add exercise` → real picker → exercises in selection order.
- [x] Requests resolved: theme tokens, shared unit/rest providers, `timezone` direct dep, DATA.md keys.
- [x] Warm-up label `ح` (AR, amber) / `W` (EN).
- [x] Finish with unticked sets: count + "Mark all done" / "Remove them".
- [x] Android exact alarms: one-time explanation sheet on the first rest timer → system screen; inexact fallback kept; never asked again automatically.
- [x] E2E integration test `app/integration_test/workout_flow_screens_test.dart` (start → picker ×3 → keypad → ✓ → rest ±/skip → finish → summary → exercise detail history + records), both platforms, ar + en; proof in `docs/screenshots/workout_flow/`. Android run: `flutter drive … --dart-define=AZM_E2E_OPEN_ALARM_SETTINGS=true` with the host helper (DECISIONS_LOG); iOS: `AZM_DEVICE_SET=B tools/screenshots.sh workout_flow ios`.
- [x] Parity screenshots regenerated on both platforms: `workout` (2 new screens: finish dialog, exact-alarm sheet), `exercises`, `workout_flow`.
- [x] Definition of done on `main`; worktrees removed (branches kept).

## 1c. Round 2 setup (main) — [x] done 2026-09-27

- [x] `tools/e2e_android_helper.sh` committed (bounded waits) + README.
- [x] Windows C (routines + onboarding, set A) and D (history, set B) defined; routes, slots, first-run gate, history-source hook and ARB fragments pre-registered (see *Parallel windows*); `test/core/router/pre_registered_routes_test.dart`.
- [x] `tools/check_plan_overlap.dart C D` → OK. analyze, test (153), directionality pass. No visible UI change (both slots render nothing), so parity screenshots were not regenerated.

## 1d. INTEGRATION round 2 — merge routines + history (main) — [x] done 2026-09-27

- [x] Merged `feature/routines` then `feature/history`; only generated l10n conflicted (re-ran `tools/gen_l10n.sh`); docs auto-merged per section. Logged in DECISIONS_LOG.
- [x] Past workout editing: no ✓ (every set done), delete = swipe only, no removal on leaving (`HistoryRepository.tidy` gone; added exercises logged via `logUnticked`).
- [x] One `SetRow` / keypad (`SetKeypadBuffer`, `SetValueKeypad`) / set-type sheet in `core/widgets`, labels in `core/l10n/set_labels.dart` + `commonSet…`/`commonKeypad…` strings; duplicates removed from workout, history, routines (and exercises' set letters).
- [x] `LiftedCounter(compact: true)` (`core/l10n/compact_number.dart`, ألف/مليون/مليار, K/M/B above 100,000); History header uses it.
- [x] Drift watch audit: three dummy `SELECT 1` streams replaced by real joins; rule in CLAUDE.md; `test/core/db/watch_queries_audit_test.dart`.
- [x] Picker "second search": not reproducible on either platform; controller-driven search fix for text changes without `onChanged`; regression tests.
- [x] E2E full journey (onboarding kg → ready program → routine ▶ → log → finish → History → edit → PRs recompute) passes on Android + iOS, ar + en (`workout_flow`).
- [x] Every screenshot suite re-run on both platforms (device set A) and reviewed: shell, exercises, workout, workout_flow, routines, onboarding, history — all `exit 0` with "All tests passed", every image regenerated (except the manual launcher captures in `shell/`).
- [x] analyze clean, `flutter test` 214 passing, directionality OK; worktrees removed (branches kept); devices + Gradle stopped.

## 2. C window — Routines, ready programs, onboarding  (branch `feature/routines`, device set **A**) — [x] done 2026-09-27 (window C), merged 2026-09-27

- **Goal:** build a routine once, start it in one tap; copy a ready program into "my routines"; first-run onboarding (unit + optional ready program).
- **Owns (only these):**
  - `app/lib/features/routines/**` (pre-registered: `ui/routines_home_section.dart`, `ui/routine_editor_screen.dart`, `ui/programs_screen.dart`, `ui/program_detail_screen.dart`)
  - `app/lib/features/onboarding/**` (pre-registered: `ui/onboarding_screen.dart`, `data/onboarding_gate.dart`)
  - `app/lib/core/l10n/arb_src/routines/{ar,en}.arb` (keys `routines…`), `app/lib/core/l10n/arb_src/onboarding/{ar,en}.arb` (keys `onboarding…`)
  - `app/test/features/routines/**`, `app/test/features/onboarding/**`
  - `app/integration_test/routines_screens_test.dart`, `app/integration_test/onboarding_screens_test.dart`
  - `docs/screenshots/routines/**`, `docs/screenshots/onboarding/**`
- **Uses, read-only:** tables `routines`/`routine_exercises`/`routine_sets` (yours to write), `workouts`/`workout_exercises`/`workout_sets` (write only to create the workout started from a routine; honour the one-active-workout rule like `WorkoutRepository.startEmpty`), `CatalogRepository.programs()`, picker contract (`context.push<List<String>>(AppRoutes.exercisePicker)`), `TrainingSettingsWriter` (unit in onboarding), `AppDatabase.writeSetting` for `onboarding_done` only, `SetRow`/`WeightKeypad`, `context.namesOf`, tokens.
- **Acceptance:**
  - [x] Workout tab (`RoutinesHomeSection`): "My routines" list (name, exercise count, ▶ start) + entry to ready programs; empty state with "New routine". The Start/Resume card above stays as is.
  - [x] Routine editor (`routineNew` / `routineEditorFor(id)`): name, notes, add exercises (multi-select picker), target sets (type, reps, optional weight via `WeightKeypad`, display unit), per-exercise rest override, drag to reorder, delete set/exercise/routine (with confirmation). Every edit persisted immediately.
  - [x] Start routine in one tap → active workout prefilled (`workouts.routine_id` set; set rows from the targets; *previous* still shown by the workout screen); if a workout is already active, resume it instead of starting a second one.
  - [x] Ready programs (`programs` → `programFor(id)`): list + preview (days, exercises in the app language, sets × reps range) → "Add to my routines" copies each day as an editable routine; `target_reps` = range max (DATA.md). Copying twice creates independent copies.
  - [x] Onboarding (first run only, ≤ 2 screens, `AppRoutes.onboarding`): 1) unit kg/lb (`TrainingSettingsWriter.setWeightUnit`); 2) optional ready program (copied with the same logic) or Skip. Finish writes `onboarding_done` = `true` and `context.go(AppRoutes.workout)`. Implement `loadOnboardingDone` (missing/false → onboarding). Existing users with data: logged decision.
  - [x] Tests: routine CRUD + reorder persistence, program copy (names per language, `target_reps` = max), start-from-routine prefill + one-active rule, onboarding gate + finish.
  - [x] Parity: `AZM_DEVICE_SET=A tools/screenshots.sh routines` (Workout tab with routines, empty state, editor with sets, picker return, programs list, program preview, active workout started from a routine) and `AZM_DEVICE_SET=A tools/screenshots.sh onboarding` (both steps; open with `ScreenStep.go(…, AppRoutes.onboarding)`), ar + en, both platforms. Checklist items for anything device-only.
- **Merge notes (window C, 2026-09-27):**
  - New files only under `features/routines/**`, `features/onboarding/**`, their tests, ARB fragments, integration tests and screenshots. Generated l10n files will conflict with D: take either side, re-run `tools/gen_l10n.sh`.
  - Tests: `test/features/routines/` (repository, start-from-routine, program copy, stream-collision regression, widget flows) and `test/features/onboarding/`; full suite 173 passing on the branch.
  - Screenshot suites: `routines` (10 screens) and `onboarding` (4 screens), ar + en, Android + iOS.
  - `routines_flow_test.dart` imports `FakeRestAlarm` from `test/features/workout/workout_test_helpers.dart` (read-only use).
  - See *Requests from C*: Drift `SELECT 1` stream sharing (affects any new watch query).

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

## 4. D window — History, stats, PRs, all-time Lifted  (branch `feature/history`, device set **B**) — [x] done 2026-09-27 (window D), merged 2026-09-27

- **Goal:** see every past workout (list + calendar), fix a logged mistake, watch totals and records grow.
- **Owns (only these):**
  - `app/lib/features/history/**` (pre-registered: `ui/history_screen.dart` (History tab), `ui/past_workout_screen.dart`, `ui/stats_screen.dart`, `ui/exercise_history_screen.dart`, `ui/exercise_history_link_slot.dart`, `data/history_exercise_source.dart`)
  - `app/lib/core/l10n/arb_src/history/{ar,en}.arb` (keys `history…`)
  - `app/test/features/history/**`, `app/integration_test/history_screens_test.dart`, `docs/screenshots/history/**`
- **Uses, read-only:** tables `workouts`/`workout_exercises`/`workout_sets` (edit FINISHED workouts only; never touch the active one), `WorkoutRepository` read/update methods, `ExerciseHistorySource`/`DbExerciseHistorySource`, `detectPrs`/`PrBests`/`liftedKg`/`liftedComparison`/`epley1Rm`, `Units` + `weightUnitProvider`, `SetRow`/`WeightKeypad`/`LiftedCounter`, `ExerciseThumbnail`, `context.namesOf`, tokens.
- **Acceptance:**
  - [x] History tab (`HistoryScreen`): all-time Lifted header ("شِلت لحد دلوقتي 1.2 مليون kg" / "Lifted so far: 1.2M kg", compact formatting, Western digits; formatter lives in `features/history/`), list of workout cards (name, date, duration, Lifted, PR count, best set per exercise), list ↔ calendar toggle (month grid, days with workouts marked, tap a day → its workouts; week starts per locale), entry to Stats. Empty state.
  - [x] Past workout detail (`pastWorkoutFor(id)`), editable with the same `SetRow` components: weights/reps/type/add/delete sets, rename, delete workout (confirmation). Persisted immediately; Lifted, PR counts and records recompute (PRs = SPEC rules, evaluated chronologically, so editing an old workout can change later PRs).
  - [x] Stats (`stats`): workouts per week (chart, `AzmSize.chart*` tokens), total workouts/sets/Lifted, per-exercise PR list (heaviest, e1RM, best volume) → exercise detail.
  - [x] Exercise history hook: implement `createExerciseHistorySource` if your rules differ from the default (edited workouts are already live through the DB streams); `ExerciseHistoryLinkSlot` shows "See all history" when `sessionCount` > 10 (the detail shows 10) → `exerciseHistoryFor(id)` full list.
  - [x] Tests: lifted total + compact formatting (ar/en), PR recompute after an edit, calendar grouping by local day, stats per week, past-workout edits persisted.
  - [x] Parity: `AZM_DEVICE_SET=B tools/screenshots.sh history` (list with seeded workouts, calendar, past workout detail + keypad, stats, exercise full history, exercise detail with the "See all" link, empty state), ar + en, both platforms. Seed finished workouts in your own test (dedicated devices only).
  - Notes: all logic in `features/history/{data,ui}`; decisions in DECISIONS_LOG → Window D. Proof: `docs/screenshots/history/{android,ios}/` (11 screens × ar/en). Tests: `test/features/history/` (26; full suite 179 green). Screenshot suite waits (max 20 s) for the seeded list on slow hosts.

## 5. `app/lib/features/settings/**` — Settings, onboarding, backup

- **Owns:** `app/lib/features/settings/**`, `app/test/features/settings/**`, `app/lib/core/l10n/arb_src/settings/**`, `app/integration_test/settings_screens_test.dart`, `docs/screenshots/settings/**`
- **Acceptance:**
  - [x] Language (System/العربية/English) + theme (dark/light), persisted (Phase 2/3).
  - [ ] Unit (kg/lb), default rest time, backup export/import, Licenses page (MIT dataset + OFL font + Gym visual attribution when media is shown).
  - Onboarding moved to §2 (window C, round 2); it writes the unit through `TrainingSettingsWriter`.
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

- @brand (window B, 2026-09-26): the Android notification icon `res/drawable/ic_stat_azm.xml` is a placeholder dumbbell; replace with the final monochrome mark.
- **@settings (integrator, 2026-09-26):** the unit / default-rest UI (settings screen + onboarding) must write through `TrainingSettingsWriter` (`features/settings/data/training_settings.dart`); every reader already watches `weightUnitProvider` / `defaultRestSecondsProvider`.

_Resolved at integration (2026-09-26): theme tokens `AzmSize.chartHeight/exerciseMedia/chartStroke/chartDot`; shared `weightUnitProvider` + `defaultRestSecondsProvider` (settings owns writing); `timezone` direct dependency; new settings keys documented in DATA.md._
_Pre-registered for round 2 (2026-09-27): the @history request above (override hook `createExerciseHistorySource`, route `exerciseHistoryFor(id)`, slot `ExerciseHistoryLinkSlot`), plus the routes, slots and ARB fragments listed under *Parallel windows*._

### Requests from C (routines + onboarding), round 2

_(append here only)_

- ~~@all / @history (window C, 2026-09-27): Drift shares stream queries with identical SQL, whatever their `readsFrom` …~~ **Resolved at integration (2026-09-27):** no tick queries remain; every watch reads real tables (CLAUDE.md rule + audit test).

### Requests from D (history), round 2

_(append here only)_
- ~~@core/widgets (D, 2026-09-27, optional): `LiftedCounter` could take a `format` callback …~~ **Resolved at integration (2026-09-27):** `LiftedCounter(compact: true)`; `CompactLiftedNumber` removed.
