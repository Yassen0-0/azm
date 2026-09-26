# Azm — Plan (backlog by folder ownership)

**How to use this file:** each task **owns** a set of paths. An agent works only inside the paths its task owns. Several Claude Code windows can then run in parallel without editing the same files. To change a file you don't own, add a note under **Requests** in the owning task instead of editing the file. Mark status inline: `[ ]` todo · `[~]` in progress (write your window/date) · `[x]` done.

Shared files, where edits must be minimal and coordinated: `app/pubspec.yaml`, `app/lib/app.dart`, `app/lib/core/router*`, `app/lib/core/l10n/arb/*.arb`, `docs/PLAN.md`, `docs/DECISIONS_LOG.md` (append-only). For ARB files, add keys **only under your feature's camelCase prefix** (`workout…`, `history…`) and keep both `app_ar.arb` and `app_en.arb` in sync.

Before finishing any task: `flutter test`, `flutter analyze`, the directionality check (`tools/check_directionality.sh`), and log assumptions in DECISIONS_LOG.md.

---

## 0. Bootstrap — DONE (2026-09-26)

All four bootstrap phases are complete; sections 1–10 below are the remaining work. What exists and can be built on:
- **DB** `app/lib/core/db/`: `AppDatabase` (all tables, one-active-workout index, `readSetting`/`writeSetting`), `CatalogInstaller`, `CatalogRepository` (`search`, `exercise`, `exercisesByIds`, `programs`). Provider: `appDatabaseProvider`, `catalogRepositoryProvider`.
- **Logic** `app/lib/core/utils/`: `normalizeForSearch`, `Units` (kg↔lb, keypad step), `liftedKg`, `epley1Rm`, `detectPrs`/`PrBests`, `liftedComparison`, `SetType`.
- **Media** `app/lib/core/media/`: `MediaResolver` (+ `mediaResolverProvider`), `ExerciseThumbnail` (lists), `ExerciseAnimation` (detail only).
- **Settings** `features/settings/data/app_settings.dart`: language + theme, persisted.
- **Tools**: `tools/build_catalog.sh`, `tools/check_directionality.sh`, `tools/serve_media_dev.dart`, `tools/relocate.sh`.



| Phase | Status | Owns |
|---|---|---|
| Phase 0: sandboxed tooling (`env.sh`, `.tooling/`) | [x] | `env.sh`, `ios_env`, `.tooling/` |
| Phase 1: project folder, docs, data import, git | [x] | everything at ROOT |
| **Phase 2: Flutter skeleton** | [x] (iOS build not yet run — see DECISIONS_LOG) | `app/**`, `tools/check_directionality.sh` |
| **Phase 3: data layer** | [x] | `app/lib/core/db/**`, `app/lib/core/utils/**`, `app/lib/core/media/**`, `tools/build_catalog.dart`, `data/ar/**` (first 50), `data/programs/**`, `data/catalog/**`, `app/test/**` |

Phase 2 acceptance: `flutter create` (org `app.azm.gym`, android+ios); deps pinned in README; Readex Pro the only font; gen-l10n with ar/en and the System/ع/EN setting; localized launcher name (`عزم`/`Azm`); theme ported with gym adaptations (dark default); `go_router` `StatefulShellRoute` with 3 tabs + glass tab bar + settings route; directionality check script; zero hard-coded strings.

Phase 3 acceptance: Drift schema per DATA.md; `build_catalog` produces `catalog.sqlite`; catalog replace-on-version logic; shared normalizer; 50 Arabic names (`reviewed:false`); 3 programs; `MediaResolver` with base-URL config + fallback; unit tests for normalization, lifted total, PR detection, kg↔lb, catalog update not touching user data.

---

## 1. `app/lib/features/workout/**` — Active workout, rest timer, summary

- **Goal:** the core loop: start (empty or from a routine), log sets, rest, finish, see the summary.
- **Owns:** `app/lib/features/workout/**`, `app/test/features/workout/**`, `app/lib/core/widgets/{set_row,weight_keypad,rest_timer_bar,active_workout_bar,lifted_counter}.dart`
- **Acceptance:**
  - [ ] Workout tab home: big "Start workout", my routines (from routines data), ready programs entry. First set loggable in ≤ 3 taps from app open.
  - [ ] Active workout screen: exercises with SetRows (type · previous · weight · reps · ✓), add exercise (picker from exercises feature), add/remove sets, reorder exercises.
  - [ ] Set type menu on label tap; labels `إ/W`, `د/D`, `ف/F`, numbers for normal sets; warm-up in amber; failure never red.
  - [ ] "Previous" value from the last finished workout with that exercise, same set index; tap fills.
  - [ ] ✓ → `setDoneTint`, light haptic, rest timer auto-starts (per-exercise override → default).
  - [ ] Swipe to delete (end direction, mirrored in RTL).
  - [ ] WeightKeypad (digits, decimal, ±2.5 in display unit, backspace, next/done); no system keyboard.
  - [ ] Header: duration | Lifted | sets, with Lifted animating (`value` 600 ms, reduced-motion respected).
  - [ ] Every edit persisted immediately; kill app mid-workout → reopen resumes exactly.
  - [ ] Minimize to ActiveWorkoutBar above the tab bar; tap restores.
  - [ ] RestTimerBar from end timestamp + scheduled notification; −15/+15/skip; haptic + sound at end; works in background and after app kill.
  - [ ] Notification setup for `flutter_local_notifications` 22 (per its README): Android receivers in `AndroidManifest.xml`, `POST_NOTIFICATIONS` runtime permission (Android 13+), exact-alarm policy (`SCHEDULE_EXACT_ALARM` vs inexact; decide and log), iOS permission request, and localized notification text. Core-library desugaring is already enabled (Phase 2).
  - [ ] Persist the running rest timer (`active_rest_ends_at`, `active_rest_notification_id` settings keys) so it survives app kill.
  - [ ] Finish → summary: duration, Lifted + comparison (car/pyramid block/elephant rule in SPEC), PRs with celebration, best set per exercise. Discard workout with confirmation.
  - [ ] Widget tests for SetRow states and keypad; unit tests for the timer's derived remaining time.

## 2. `app/lib/features/routines/**` — Routines & ready programs

- **Owns:** `app/lib/features/routines/**`, `app/test/features/routines/**`
- **Acceptance:**
  - [ ] Routine list (Workout tab section) and editor: name, notes, add exercises (multi-select picker), target sets (type, reps, optional weight), rest override, drag to reorder, delete.
  - [ ] Start routine in one tap → active workout prefilled.
  - [ ] Ready programs list (`CatalogRepository.programs()`) → "Add to my routines" copies them as editable routines, names in the app language; `target_reps` = range max (DATA.md).
  - [ ] Onboarding hook: the program chosen in onboarding is copied on finish.

## 3. `app/lib/features/exercises/**` — Library, picker, detail

- **Owns:** `app/lib/features/exercises/**`, `app/test/features/exercises/**`, `app/lib/core/widgets/{exercise_card,muscle_chips}.dart`
- **Acceptance:**
  - [ ] Library: search box (normalized, AR/slang/EN), MuscleChips (target/body-part), equipment filter sheet, list of ExerciseCards with thumbnails (fallback icon). Use `CatalogRepository.search()` and `ExerciseThumbnail`; add ARB keys for body-part/target/equipment dataset keys (`muscle…`, `equipment…`).
  - [ ] Two names per row (primary = app language, secondary = the other); English-only exercises show just the English name.
  - [ ] Multi-select picker mode (used by workout + routines) returning ordered ids.
  - [ ] Detail: GIF (only here), attribution line, instructions (AR if present else EN), muscles, your history for this exercise, chart (best set / e1RM / volume), PRs.
  - [ ] Search performance: < 50 ms for any query over 1,324 rows on a mid-range Android.

## 4. `app/lib/features/history/**` — History, stats, PRs

- **Owns:** `app/lib/features/history/**`, `app/test/features/history/**`
- **Acceptance:**
  - [ ] List of workout cards (name, date, duration, Lifted, PR count, best set per exercise) + calendar view toggle.
  - [ ] All-time Lifted header ("شِلت لحد دلوقتي …"), with compact number formatting (e.g. 1.2 مليون / 1.2M).
  - [ ] Past workout detail, editable (same SetRow components); edits recompute PRs.
  - [ ] Stats: workouts per week, total sets, per-exercise PR list.

## 5. `app/lib/features/settings/**` — Settings, onboarding, backup

- **Owns:** `app/lib/features/settings/**`, `app/test/features/settings/**`
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
  - [ ] **Verify the iOS build** (not run yet: the owner declined it in Phase 2): `source ./env.sh && cd app && flutter build ios --simulator --debug`, then fix whatever it reports (Xcode project / InfoPlist.strings / pods-vs-SPM).

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
