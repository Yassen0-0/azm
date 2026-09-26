# Azm — Architecture

## Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | **Flutter** (pinned, see README), Android + iOS only | No web/desktop targets. |
| State | **Riverpod** (`flutter_riverpod`) | If code generation (`riverpod_generator`) is adopted, it is used consistently across the app, not mixed per feature. |
| Database | **Drift** (SQLite) + `drift_flutter` + `sqlite3_flutter_libs` | Schema in [DATA.md](DATA.md). Codegen via `drift_dev` + `build_runner`. |
| Routing | **go_router** with `StatefulShellRoute` (3 tabs, state preserved per tab) | Settings is a pushed route from a header icon. |
| Localization | **gen-l10n** + ARB (`app_ar.arb`, `app_en.arb`) | Zero hard-coded UI strings. |
| Images | **cached_network_image** | Thumbnails/GIFs via `MediaResolver`. |
| Notifications | **flutter_local_notifications** | Rest-timer end notification. |
| IDs | **uuid** (v4) | All user records. |
| Files | **path_provider** | DB file, backup export. |
| Crash reporting | Firebase Crashlytics, **TODO** | Needs the owner's Firebase project; tracked in PLAN.md. |

Exact package versions are recorded in `README.md` and locked by `app/pubspec.lock` (committed).

## Folder structure (feature-first, two layers)

```
app/lib/
  main.dart                bootstrap: ProviderScope, DB open, catalog check, router
  app.dart                 MaterialApp.router, themes, locale resolution
  core/
    theme/                 tokens (colors, type, spacing, radii, sizes, motion), ThemeData builders
    l10n/                  generated localizations + helpers (digits, number formats)
    db/                    Drift database, tables, DAOs, migrations, catalog installer
    media/                 MediaResolver + config (base URL)
    utils/                 units (kg↔lb), lifted/PR math, Arabic normalization, clock, haptics
    widgets/               shared components (SetRow, WeightKeypad, RestTimerBar, ExerciseCard, …)
  features/
    workout/   data/ ui/   active workout, rest timer, summary, workout home tab
    routines/  data/ ui/   routine list + editor, ready programs
    exercises/ data/ ui/   library, picker, detail
    history/   data/ ui/   history list/calendar, past workout detail/edit, stats, PRs
    settings/  data/ ui/   settings, onboarding, backup export/import
```

- **`data/`** = repositories + Riverpod providers talking to DAOs in `core/db`. No widgets.
- **`ui/`** = screens and feature-local widgets. No SQL, no direct DAO access.
- A feature may import `core/**` and another feature's `data/` providers, never another feature's `ui/`.
- Pure logic (normalization, lifted, PRs, unit conversion) lives in `core/utils`, has no Flutter imports, and is unit-tested. The Arabic normalizer is also imported by `tools/build_catalog.dart`.

## Core rules

- **Weights stored in kg, always.** Convert to lb only at display and input boundaries (`core/utils/units.dart`).
- **All user records use UUID v4 string ids** (future sync). Catalog exercises keep the dataset's 4-digit string id.
- **Every change to an active workout is written to the DB immediately.** No in-memory-only state for sets. UI state is derived from DB streams (Drift `watch`). Killing the app loses nothing, and launch resumes the `active` workout.
- **At most one workout with `status = active`** (enforced in the DAO and by a partial unique index).
- **Rest timer = end timestamp + scheduled local notification.** Remaining time = `endsAt − now()`, recomputed on each frame/tick for display only. It never counts down a stored value.
- **Directionality:** only `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`. A check script in `tools/` fails the build if `left/right` APIs appear in `app/lib/`.
- **Localization:** every user-visible string comes from ARB. Language setting: System (default) / العربية / English. Numbers use Western digits in both locales.
- **Theme:** dark default, light optional, tokens only (see DESIGN.md).
- **Catalog vs user data:** catalog tables are read-only and replaced wholesale when the bundled catalog version changes. User tables are never touched by catalog updates.

## Media

`MediaResolver(exerciseId) → thumbnailUrl | gifUrl | null`, built from a **base URL in config**:
- **dev:** a local static server serving `media/` (e.g. `http://<mac-ip>:8080/`), or null.
- **production:** Cloudflare **R2** public bucket/custom domain holding only **licensed** media.
- `null` (not licensed, not configured, or offline with no cache) → fallback UI (muscle icon).
- Lists request thumbnails only. GIFs are requested only on the exercise detail screen.
- **Media is never bundled in the app** (licensing, see [LICENSES.md](LICENSES.md)).

## Backend plan

- **v1:** no backend. **Cloudflare R2 for media only.** Supabase is deliberately not used in v1: free projects pause when inactive and hard-stop on egress limits, which would break media for every user.
- **v2:** **Supabase** (Postgres schema mirroring the Drift user tables, UUID ids make this straightforward) for auth, sync and coach ↔ client.
- **Crash reports:** Firebase Crashlytics once the owner creates a Firebase project (TODO in PLAN.md).

## Build & run

All commands run from ROOT through the sandbox:

```sh
source ./env.sh && cd app && flutter run                    # emulator / simulator
./ios_env flutter run -d <iphone-id>                         # physical iPhone (signing)
```

See README.md for the full setup and the sandbox rules.
