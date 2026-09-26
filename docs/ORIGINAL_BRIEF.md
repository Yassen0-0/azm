# Azm (عزم) — Project Bootstrap Prompt

> Paste everything below the line into Claude Code, opened in an EMPTY folder that contains an `inputs/` folder with:
> `theme.json`, `theme.css`, `ReadexPro.ttf` (from AtHer), and optionally AtHer's `lib/core/theme/` copied to `inputs/ather_theme/`.

---

You are the lead engineer bootstrapping **Azm (عزم)**, a Hevy-style gym tracker built in Flutter for Android and iOS, Arabic-first and fully bilingual. Your job is to build ONE self-contained, portable project folder that holds everything needed to keep building on any machine: data, design system, specs, decisions, tooling, and the app skeleton. The folder will be moved to another drive, so **no absolute paths anywhere, no dependency on anything outside the folder** (except installing Flutter/tools, documented in README).

Work in phases. **Stop at the end of each phase**, print a short report (what you did, what's left, any doubt), and wait for my "go".

## SANDBOX RULE — highest priority, overrides everything else

**Nothing leaves the project folder.** You must never read from, write to, install into, or download to any location outside the folder you were opened in (call it `ROOT`). This includes `~`, `/tmp`, `/usr/local`, `/opt`, Homebrew, global npm/pip/gem, and global git config.

- Everything you download (Flutter SDK, packages, the dataset, tools, gems) goes inside `ROOT` and is used from there.
- Layout for tooling:
```
ROOT/
  inputs/                  my files (read-only for you)
  azm/                     the project (see Phase 1)
  .tooling/                GITIGNORED — all SDKs and caches
    flutter/               Flutter SDK (git clone, stable channel, pinned tag)
    pub-cache/             PUB_CACHE
    gradle/                GRADLE_USER_HOME
    gems/                  GEM_HOME / GEM_PATH (CocoaPods if needed)
    cocoapods/             CP_HOME_DIR
    android-sdk/           ANDROID_HOME (cmdline-tools + platform + build-tools + emulator)
    android-user/          ANDROID_USER_HOME (+ ANDROID_AVD_HOME=android-user/avd) — emulators must NOT go to ~/.android
    tmp/                   TMPDIR for every command
```
- Create `ROOT/env.sh` that exports all of the above with paths **relative to the script's own location** (`$(cd "$(dirname "$0")" && pwd)`), prepends `.tooling/flutter/bin` and `.tooling/gems/bin` to `PATH`, and sets `TMPDIR`. **Every shell command you run starts with `source ./env.sh &&`** (from ROOT). Verify with `which flutter` that it points inside ROOT before any Flutter command.
- Pin versions: record the exact Flutter tag, Dart version, and every tool version in `azm/README.md`.
- The ONLY things allowed outside ROOT: Xcode itself (App Store, system-level — cannot be relocated) and the system `git`/`curl`/`ruby` binaries. If a step would need anything else installed globally (brew, global gem, sudo), **stop and ask me** instead.
- Xcode builds: always pass `-derivedDataPath ROOT/.tooling/xcode-derived` when you build from the command line.
- Never modify my shell profile (`.zshrc`, `.bashrc`), global git config, or system settings.
- Portability: the project starts on the Mac's internal disk and will later be MOVED to an external SSD. Add `azm/tools/relocate.sh` that, after the whole ROOT is moved, (1) deletes path-bound caches (`app/.dart_tool`, `app/build`, `app/ios/Pods`, `.tooling/xcode-derived`), (2) rewrites absolute paths inside `.tooling/android-user/avd/*.ini` to the new location, (3) re-runs `flutter pub get` + `pod install` through `env.sh`, and (4) runs `flutter doctor` to confirm. Document in README: move with `ditto OLD_ROOT NEW_ROOT` (preserves symlinks and permissions), then run `relocate.sh`. Keep ROOT's path free of spaces and non-ASCII characters.

## Phase 0 — Check before touching anything

1. Verify `inputs/` has `theme.json`, `theme.css`, `ReadexPro.ttf`. If anything is missing, stop and tell me.
2. Create `.tooling/` and `env.sh` per the SANDBOX RULE. Clone Flutter stable into `.tooling/flutter`, run `flutter --version` and `flutter doctor` through `env.sh`. Check Xcode exists. For Android: install the SDK inside `.tooling/android-sdk` (download cmdline-tools into it, then platform-tools, the latest stable platform and build-tools, and an emulator image). Download whatever you need at any size — no need to ask. Report all versions and where each tool lives (every path must be inside ROOT except Xcode).
3. Ask nothing else — everything you need is in this prompt. If something is truly ambiguous, pick the most sensible option and log it in `docs/DECISIONS_LOG.md`.

## Phase 1 — Assemble the project folder

Create this exact structure at `./azm/`:

```
azm/
  README.md              How to set up on a fresh Mac, run, build, and where everything is
  CLAUDE.md              Rules every agent must follow in this repo (see "Agent rules")
  docs/
    SPEC.md              Full product spec (copy the "Product spec" section below, cleaned up)
    DESIGN.md            Design system + gym adaptations (from inputs + "Design" section)
    ARCHITECTURE.md      Tech decisions (from "Architecture" section)
    DATA.md              Data model, catalog pipeline, Arabic search normalization
    LICENSES.md          Media license status and rules (see "Media license")
    PLAN.md              Backlog of remaining work, split by FOLDER OWNERSHIP (see "Plan")
    DECISIONS_LOG.md     Every assumption you make, dated
  data/
    raw/                 exercises.json + exercises.schema.json from the dataset (MIT text)
    ar/                  exercise_names_ar.json (Arabic names + Egyptian gym slang aliases)
    programs/            programs.json (ready-made routines)
    catalog/             build output: catalog.sqlite (generated, not hand-edited)
  media/                 DEV ONLY — images/ + videos/ from the dataset. GITIGNORED. Never shipped.
  brand/                 logo-concept-a.svg (below) + README on icon exports still to do
  design/                theme.json, theme.css, ReadexPro.ttf (copied from inputs)
  tools/                 Dart scripts: build_catalog, normalize test, (later) upload_media_r2
  app/                   The Flutter project
```

Steps:
1. Clone `https://github.com/hasaneyldrm/exercises-dataset` into `ROOT/.tooling/tmp/` (never a system temp folder), copy `data/*` into `azm/data/raw/`, `images/` and `videos/` into `azm/media/`, then delete the temp clone. Keep the dataset's `LICENSE` and `NOTICE.md` in `azm/data/raw/`.
2. Copy design inputs into `azm/design/`.
3. Write `brand/logo-concept-a.svg` with exactly this content (initial concept, will be refined):
```svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#000000"/>
  <line x1="10" y1="84" x2="90" y2="44" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>
  <circle cx="58.4" cy="36.9" r="18" fill="#4D9BFF"/>
  <circle cx="58.4" cy="36.9" r="4" fill="#000000"/>
  <g stroke="#FFFFFF" stroke-width="3.2" stroke-linecap="round" fill="none">
    <line x1="33" y1="64" x2="37" y2="54"/>
    <line x1="36.2" y1="56" x2="45" y2="48.9"/>
    <line x1="33" y1="64" x2="26" y2="75.5"/>
    <line x1="33" y1="64" x2="36" y2="70.8"/>
  </g>
  <circle cx="39" cy="48.9" r="3.4" fill="#FFFFFF"/>
</svg>
```
4. Write all `docs/` files from the sections below. They are the source of truth for future agents — make them complete and self-explanatory for someone who never saw this prompt.
5. `git init` inside `azm/`, add `.gitignore` (Flutter defaults + `media/` + `data/catalog/*.sqlite` + secrets). Set user name/email with `git config` **local to this repo only** (never `--global`). First commit. **Never push.** `.tooling/` stays outside `azm/` so it is never committed.

**STOP — report.**

## Phase 2 — Flutter app skeleton

1. `flutter create` in `azm/app/` — org/package `app.azm.gym`, platforms android + ios only.
2. Dependencies (latest stable, then commit `pubspec.lock` and list exact versions in README): `flutter_riverpod` (+ codegen if you use it consistently), `go_router`, `drift` + `drift_flutter` + `sqlite3_flutter_libs` (+ `drift_dev`, `build_runner` dev), `flutter_localizations` + `intl`, `cached_network_image`, `flutter_local_notifications`, `uuid`, `path_provider`. Add Firebase Crashlytics only as a TODO in PLAN.md (needs my Firebase project).
3. Fonts: bundle `ReadexPro.ttf` as the only family.
4. Localization with `gen-l10n` + ARB (`app_ar.arb`, `app_en.arb`). **Zero hard-coded UI strings.** Language setting: System (default) / العربية / English.
5. Localized launcher name: `عزم` on Arabic devices, `Azm` otherwise (Android `values-ar/strings.xml` + `values/strings.xml`; iOS `InfoPlist.strings` for ar/en with `CFBundleDisplayName`).
6. Port the design system from `design/` (and `inputs/ather_theme/` if present, which is the real Flutter source) into `app/lib/core/theme/`, applying the gym adaptations in "Design" below.
7. **Directionality rule:** only `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end` — never `left/right` — anywhere. Add a lint or a grep check script in `tools/` that fails if `EdgeInsets.only(left` / `right:` / `Alignment.centerLeft` etc. appear in `app/lib/`.
8. App shell: `go_router` with `StatefulShellRoute`, 3 tabs (Workout / History / Exercises) using the floating glass tab bar from the design system, placeholder screens with real localized titles, settings reachable from a header icon.
9. Dark theme is the default; light available in settings.

**STOP — report.**

## Phase 3 — Data layer

1. Drift database in `app/lib/core/db/`, schema in "Data model" below. Catalog tables and user tables are separate; catalog has a `version`.
2. `tools/build_catalog.dart`: reads `data/raw/exercises.json` + `data/ar/exercise_names_ar.json`, writes `data/catalog/catalog.sqlite` (copied into app assets). App on first launch / on catalog version change: replaces catalog tables only, never touches user tables.
3. Arabic normalization function (shared by build script and app): strip tashkeel and tatweel, أ/إ/آ → ا, ة → ه, ى → ي, ؤ → و, ئ → ي, lowercase Latin, collapse spaces. Store a `search_norm` column containing normalized en + ar + aliases. Search matches normalized query against it.
4. `data/ar/exercise_names_ar.json` format: `{ "<id>": { "ar": "ضغط بار مستوي", "aliases": ["بنش", "بنش برس"], "reviewed": false } }`. Draft Arabic names for the **50 most common gym exercises only** in Egyptian gym language (e.g. bench press → ضغط بار مستوي, lat pulldown → سحب عالي, lateral raise → رفرفة جانبي, squat → سكوات, deadlift → ديدلفت). All `reviewed: false`. List them in your report for my review. Don't do the rest — it's in PLAN.md.
5. `data/programs/programs.json`: Push/Pull/Legs, Upper/Lower, Full Body 3×/week — referencing real exercise ids, names in ar + en.
6. Media: a `MediaResolver` (`exerciseId → thumbnail URL / gif URL / null`) reading a base URL from config. In dev it can point to a local server serving `media/`; in production it will point to Cloudflare R2. Null → fallback UI (muscle icon). Lists show thumbnails only; GIF plays only on the exercise detail screen.
7. Unit tests: normalization, lifted-total calc, PR detection, kg↔lb conversion, catalog update does not touch user data.

**STOP — final report**, then make sure `docs/PLAN.md` reflects exactly what's left.

---

# Product spec

**Name:** Azm / عزم. Launcher: `Azm` / `عزم`. Store title: `Azm - Gym Tracker` / `عزم - متتبع الجيم`.
**Differentiator:** built for the Egyptian gym-goer — Arabic that sounds like the gym (slang names, search that understands them), proper RTL, bilingual everywhere.
**v1 is fully offline.** No accounts, no backend except media hosting. Backup = export/import a JSON file.

## v1 features
1. **Exercise library:** bilingual search (Arabic, slang aliases, English all find the same exercise), filter by muscle (chips) and equipment (sheet). Every exercise shows two names: primary in app language, secondary smaller in the other language.
2. **Live workout logging:** per set — type, previous, weight, reps, ✓.
   - Set types: normal (shows number), warm-up (amber, "إ"/"W"), drop ("د"/"D"), failure ("ف"/"F"). Tap the set label to change type.
   - "Previous" shows the same set from the last time; tapping it fills weight + reps.
   - ✓ → row tints green, light haptic, rest timer auto-starts.
   - Swipe to delete a set (direction mirrors in RTL).
   - Custom numeric keypad (not system keyboard): digits, decimal, −2.5 / +2.5.
   - Header shows 3 live stats: duration | **Lifted (شِلت)** | sets.
   - Screen can minimize into a persistent bar above the tab bar.
   - **Every change is written to the DB immediately** — app kill / battery death loses nothing; reopening resumes the active workout.
3. **Rest timer:** bottom bar, countdown, −15 / +15 / skip; haptic + sound at end. Default 90s, per-exercise override. Implemented from an **end timestamp** + scheduled local notification, never a ticking counter.
4. **Routines:** create/edit (add exercises, target sets/reps, drag to reorder), start in one tap. Ready-made programs in Arabic.
5. **History & PRs:** workout cards (name, date, duration, lifted, PR count, best set per exercise), edit past workouts, per-exercise chart. PR types: heaviest weight, best estimated 1RM (Epley: w × (1 + reps/30)), best single-set volume. PR celebration: number scales with celebration curve + 🏆 badge on the set.
6. **Lifted (شِلت / Lifted):** sum of weight × reps for all ✓ sets **including warm-ups** (it's about the feeling of strength). Bodyweight exercises count only added weight (0 otherwise) until user bodyweight exists. The number animates up (value duration) on each ✓.
   - Post-workout summary shows a fun comparison, e.g. "شِلت 8,450 kg — وزن 6 عربيات ملاكي 🚗". Comparison table (approximate): car 1,400 kg, pyramid stone block 2,500 kg, elephant 6,000 kg. Pick the one that gives a count between 1 and 20.
   - History shows an all-time lifted total ("شِلت لحد دلوقتي 1.2 مليون kg").
7. **Onboarding (first run only, max 2 screens):** unit kg/lb, optional ready program. Language follows device.
8. **Settings:** language (System/ع/EN), theme (dark default/light), unit, default rest time, backup export/import.

**North-star metric:** app open → first set logged in ≤ 3 taps.

## Postponed (v2+)
Accounts + sync (Supabase), social feed, coach ↔ client, payments (InstaPay/Fawry), Live Activities / widgets / Apple Watch, body measurements, AI features, plate calculator.

## Navigation
3 tabs: **Workout** (home: big "Start workout", my routines, ready programs) · **History** (list/calendar, stats, PRs, all-time lifted) · **Exercises** (library). Settings from header icon. Screens: onboarding, routine editor, active workout, workout summary, exercise picker (multi-select), exercise detail (GIF, instructions, muscles, your history, chart, PR), past workout detail (editable), settings.

---

# Design

Base: AtHer design system in `design/` (tokens, type scale, motion, radii, spacing ladder 4·8·12·16·20·24, no shadows, no gradients, glass only on tab bar, tabular figures everywhere, max weight 700). Gym adaptations:
- **Dark is the default theme.**
- **Rename semantic tokens by function:** `right/wrong/mastery` → `setDone` (green), `destructive` (red, delete/missed only), `pr`, `warmup`. Remove study-specific names (`lesson-number`, `lock-wordmark`, etc.) or rename to gym equivalents.
- **One new color:** amber for warm-up sets. Red never means "failure set" — failure sets are intentional.
- **Set row:** min height 52, numbers use `row-number` (19px/700), all touch targets ≥ 48.
- **Digits:** Western 0-9 for all numbers in both languages.
- **New components:** SetRow, WeightKeypad, RestTimerBar (+ mini in minimized bar), ActiveWorkoutBar, ExerciseCard (thumbnail + bilingual name + PR badge), MuscleChips, LiftedCounter.
- Reduced-motion respected everywhere.

---

# Architecture

- Flutter, Android + iOS. State: Riverpod. DB: Drift (SQLite). Routing: go_router. l10n: gen-l10n. Images: cached_network_image.
- Folder structure — feature-first, two layers:
```
app/lib/
  core/      theme · l10n · db · media · utils · widgets
  features/
    workout/  data/ ui/
    routines/ data/ ui/
    exercises/ data/ ui/
    history/  data/ ui/
    settings/ data/ ui/
```
- Weights stored in **kg always**; convert on display only.
- All user records use **UUID** ids (future sync).
- Backend plan: v1 — Cloudflare R2 for media only (no Supabase: free projects pause when inactive and hard-stop on egress limits). v2 — Supabase (Postgres mirrors the Drift schema) for auth/sync/coach. Firebase Crashlytics (TODO: needs Firebase project) for crash reports.

# Data model (Drift)

Catalog (read-only, replaced on version bump): `catalog_meta(version)`, `exercises(id, name_en, name_ar, aliases_ar json, body_part, target, secondary_muscles json, equipment, instructions_en json steps, instructions_ar json steps nullable, media_id, search_norm)`.

User: `routines(id uuid, name, notes, sort, created_at, updated_at)`, `routine_exercises(id, routine_id, exercise_id, sort, rest_seconds nullable, notes)`, `routine_sets(id, routine_exercise_id, sort, type, target_reps, target_weight_kg nullable)`, `workouts(id, routine_id nullable, name, started_at, ended_at nullable, status active|finished, notes)`, `workout_exercises(id, workout_id, exercise_id, sort, notes)`, `workout_sets(id, workout_exercise_id, sort, type normal|warmup|drop|failure, weight_kg, reps, completed_at nullable)`, `settings(key, value)`. At most one workout with status `active`.

---

# Media license (critical)

- Dataset **text/data** (names, muscles, instructions) = MIT → free to use.
- **Images/GIFs are © Gym visual.** The repo's permission does NOT transfer to us. Using them in a released app requires buying a license from gymvisual.com (one-time, commercial use in apps allowed).
- Rules for agents: `media/` is dev-only and gitignored; never commit it to a public repo; never upload it to a public URL; never ship it in a build; **never use the media as input to AI image/animation generation** (explicitly forbidden by their license).
- Launch plan: buy the ~150–200 most-used exercises, host them on R2, everything else uses the fallback UI.

---

# Agent rules (put in CLAUDE.md)

- **Sandbox:** never read, write, install or download outside the project root. Always `source ./env.sh` first; all SDKs, caches and temp files live in `.tooling/`. Anything that needs a global install → stop and ask.
- Read `docs/SPEC.md`, `docs/DESIGN.md`, `docs/ARCHITECTURE.md` before any task.
- Only touch files inside the folders your task owns (see PLAN.md). Coordinate through `docs/PLAN.md`.
- No hard-coded strings, no left/right, no new colors/sizes outside the theme, Western digits, kg internally.
- Every DB change for an active workout is persisted immediately.
- Run tests + the directionality check before finishing a task.
- Log assumptions in `docs/DECISIONS_LOG.md`. Never push to git. Never touch `media/` licensing rules.

# Plan (docs/PLAN.md)

Write the remaining backlog as tasks grouped by owned folder so several Claude Code windows can run in parallel without touching the same files — e.g. `features/workout/**`, `features/routines/**`, `features/exercises/**`, `features/history/**`, `features/settings/**`, `data/ar/**` (Arabic names for remaining exercises, batches of 100), `brand/**` (icon exports: Android adaptive + monochrome, iOS dark/tinted), `tools/**` (R2 upload script), Crashlytics setup. Each task: goal, owned paths, acceptance criteria.
