# Azm — Data

## Sources

| Path | What | Edited by |
|---|---|---|
| `data/raw/exercises.json` | 1,324 exercises from [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset), commit `7455efae41b3` (2026-07-16) | **Never edited.** Re-import to update. |
| `data/raw/exercises.schema.json` | JSON Schema of the above | never |
| `data/raw/LICENSE`, `data/raw/NOTICE.md` | Dataset license (MIT for text/data) and media notice | never |
| `data/ar/exercise_names_ar.json` | Arabic names + Egyptian gym slang aliases | humans / agents (reviewed flag) |
| `data/programs/programs.json` | Ready-made routines | humans / agents |
| `data/catalog/catalog.sqlite` | **Build output** of `tools/build_catalog.dart`. Gitignored. | generated only |
| `data/catalog/catalog_version.json` | `{version, input_sha256}`: the version bumps only when the inputs change. Committed. | generated only |
| `app/assets/catalog/catalog.sqlite` + `catalog_version.txt` | Copies bundled into the app. **Committed**, so a fresh clone builds without running the tool. | generated only |
| `media/images`, `media/videos` | 1,324 thumbnails (JPEG 180×180) + 1,324 GIFs (180×180) | **dev only, gitignored**, see LICENSES.md |

### Raw dataset shape

Each record (all fields required):

```jsonc
{
  "id": "0001",                    // 4-digit string, unique (range 0001–5201, not contiguous)
  "name": "3/4 sit-up",            // English, lowercase
  "category": "waist",             // mirrors body_part
  "body_part": "waist",            // 10 values, see below
  "equipment": "body weight",      // 28 values
  "target": "abs",                 // 19 values (primary muscle)
  "muscle_group": "hip flexors",   // 29 values (loose synergist label, not used for filtering)
  "secondary_muscles": ["hip flexors", "lower back"],   // 40 distinct values
  "instructions":      { "en": "…", "es": "…", … },     // one string per language
  "instruction_steps": { "en": ["…", "…"], … },         // same, split into steps
  "media_id": "2gPfomN",
  "image":   "images/0001-2gPfomN.jpg",
  "gif_url": "videos/0001-2gPfomN.gif",
  "attribution": "© Gym visual — https://gymvisual.com/",
  "created_at": "2026-03-18T12:31:32.854798+00:00"
}
```

- **Instruction languages:** en, es, it, tr, ru, zh, hi, pl, ko, fr. **No Arabic.** `instructions_ar` is null until translated (PLAN.md).
- **body_part:** upper arms 292, upper legs 227, back 203, waist 169, chest 163, shoulders 143, lower legs 59, lower arms 37, cardio 29, neck 2.
- **equipment (top):** body weight 325, dumbbell 294, cable 157, barbell 154, leverage machine 81, band 54, smith machine 48, kettlebell 41, weighted 36, stability ball 28, ez barbell 23, … (28 total).
- **target:** abs, pectorals, biceps, glutes, delts, triceps, upper back, lats, calves, quads, forearms, cardiovascular system, hamstrings, spine, traps, adductors, serratus anterior, abductors, levator scapulae.
- 6 English names appear twice with different ids (e.g. "lever chest press"). They are distinct records (different media); keep both.
- Every record has an existing image and GIF in `media/`.

## Data model (Drift, `app/lib/core/db/`)

Timestamps are **UTC**, stored as ISO-8601 text with milliseconds (Drift option `store_date_time_values_as_text`, see `app/build.yaml`). Weights are **kg** (`REAL`). JSON columns are TEXT holding JSON. Enums (`type`, `status`) are stored as their Dart enum name. Code: `app/lib/core/db/tables.dart`.

### Catalog tables (read-only in the app, replaced on version bump)

**`catalog_meta`**
| column | type | notes |
|---|---|---|
| `version` | INTEGER NOT NULL | single row; bumped by `build_catalog` whenever its input changes |

**`exercises`**
| column | type | notes |
|---|---|---|
| `id` | TEXT PK | dataset id, e.g. `"0025"` |
| `name_en` | TEXT NOT NULL | Title Case display form of dataset `name` |
| `name_ar` | TEXT NULL | from `exercise_names_ar.json` |
| `aliases_ar` | TEXT NOT NULL (JSON array) | slang aliases, `[]` if none |
| `body_part` | TEXT NOT NULL | dataset value (English key; UI localizes it) |
| `target` | TEXT NOT NULL | primary muscle key |
| `secondary_muscles` | TEXT NOT NULL (JSON array) | keys |
| `equipment` | TEXT NOT NULL | key |
| `instructions_en` | TEXT NOT NULL (JSON array of steps) | from `instruction_steps.en` |
| `instructions_ar` | TEXT NULL (JSON array of steps) | future translation |
| `media_id` | TEXT NOT NULL | used by `MediaResolver` (file stem `<id>-<media_id>`) |
| `search_norm` | TEXT NOT NULL | normalized `name_en + name_ar + aliases_ar`, space-joined |

**`catalog_programs`**
| column | type | notes |
|---|---|---|
| `id` | TEXT PK | program id (`ppl`, `upper_lower`, `full_body_3x`) |
| `sort` | INTEGER | display order |
| `data` | TEXT (JSON) | the whole program object from `programs.json` |

Muscle, body-part and equipment keys are localized through ARB (`muscle_pectorals`, `equipment_barbell`, …), not stored translated.

### User tables (never touched by catalog updates)

| table | columns |
|---|---|
| `routines` | `id` TEXT PK (uuid), `name` TEXT, `notes` TEXT NULL, `sort` INTEGER, `created_at`, `updated_at` |
| `routine_exercises` | `id` uuid PK, `routine_id` → routines (cascade), `exercise_id` TEXT (catalog id, *no FK*: catalog is replaceable), `sort`, `rest_seconds` INTEGER NULL, `notes` TEXT NULL |
| `routine_sets` | `id` uuid PK, `routine_exercise_id` → routine_exercises (cascade), `sort`, `type` (`normal`\|`warmup`\|`drop`\|`failure`), `target_reps` INTEGER NULL, `target_weight_kg` REAL NULL |
| `workouts` | `id` uuid PK, `routine_id` TEXT NULL (no FK: routine may be deleted), `name`, `started_at`, `ended_at` NULL, `status` (`active`\|`finished`), `notes` NULL. **Partial unique index: at most one row with `status='active'`.** |
| `workout_exercises` | `id` uuid PK, `workout_id` → workouts (cascade), `exercise_id` TEXT, `sort`, `notes` NULL |
| `workout_sets` | `id` uuid PK, `workout_exercise_id` → workout_exercises (cascade), `sort`, `type` (`normal`\|`warmup`\|`drop`\|`failure`), `weight_kg` REAL NOT NULL DEFAULT 0, `reps` INTEGER NOT NULL DEFAULT 0, `completed_at` NULL (null = not ✓) |
| `settings` | `key` TEXT PK, `value` TEXT (JSON-encoded) |

Settings keys (values JSON-encoded): `locale` (`"system"`\|`"ar"`\|`"en"`, implemented), `theme` (`"dark"`\|`"light"`, implemented), `unit` (`"kg"`\|`"lb"`), `default_rest_seconds` (90), `onboarding_done` (bool), `active_rest_ends_at` (ISO UTC or null), `active_rest_notification_id`, `active_rest_total_seconds` (int: current rest length incl. ±15, for the progress bar; null when no rest), `workout_notifications_asked` (bool: notification permission prompt shown once), `workout_exact_alarms_asked` (bool: Android exact-alarm explanation sheet shown once).

`unit` and `default_rest_seconds` are owned by settings: written only through `TrainingSettingsWriter`, read by every feature through `weightUnitProvider` / `defaultRestSecondsProvider` (`features/settings/data/training_settings.dart`). The `active_rest_*` and `workout_*` keys are owned by the workout feature.

**Why no FKs from user tables to `exercises`:** catalog tables are dropped and re-filled on a version bump. User history must survive, even for an exercise removed from a future catalog (the UI then shows "Unknown exercise" with the stored id).

## Catalog pipeline

```
data/raw/exercises.json ─┐
                         ├─ tools/build_catalog.dart ─► data/catalog/catalog.sqlite ─► app/assets/catalog/catalog.sqlite
data/ar/exercise_names_ar.json ─┘         (uses the shared normalizer)
```

Run: `tools/build_catalog.sh` (or `source ./env.sh && (cd tools && dart run build_catalog.dart)`). `tools/` is a small pure-Dart package (`sqlite3`, `crypto`) and imports the app's normalizer by relative path.

1. `build_catalog` reads the three inputs and **validates** them: unique ids; every Arabic entry and every program exercise references an existing id; each Arabic entry has `ar`, `aliases` and `reviewed`. Any error fails the build.
2. It builds rows: `name_en` = Title Case of the dataset name (acronyms kept: EZ, POV, RDL; the `в°` → `°` encoding glitch fixed), `instructions_en` = `instruction_steps.en`, `search_norm` = normalized `name_en + name_ar + aliases`.
3. **Version:** `data/catalog/catalog_version.json` holds `{version, input_sha256}`. The hash covers the three input files + `builderRevision`, and the version is incremented only when it changes, so re-running is idempotent.
4. It writes `data/catalog/catalog.sqlite` (tables `catalog_meta`, `exercises`, `catalog_programs`) and copies it plus `catalog_version.txt` into `app/assets/catalog/`.
5. **App on launch** (`CatalogInstaller.installBundledIfNeeded`, before the first frame): reads the bundled `catalog_version.txt`. Only if the DB has no catalog or an older one, it copies the asset DB to a temp file, reads it, and in **one transaction** deletes and re-inserts `exercises`, `catalog_programs` and `catalog_meta`. User tables are never touched (unit test `catalog_update_test.dart` compares every user table before/after).

## Arabic search normalization

One function, `normalizeForSearch(String) → String`, in `app/lib/core/utils/normalize.dart`. It is pure Dart and is also imported by `tools/build_catalog.dart`. The index and the query go through the **same** function.

Steps, in order:
1. Remove **tashkeel** (Arabic diacritics U+064B–U+065F, U+0670 superscript alef, U+06D6–U+06ED Quranic marks).
2. Remove **tatweel** `ـ` (U+0640).
3. `أ إ آ ٱ` → `ا`
4. `ة` → `ه`
5. `ى` → `ي`
6. `ؤ` → `و`
7. `ئ` → `ي`
8. Lowercase Latin.
9. Collapse whitespace runs to one space and trim.

Examples: `ضَغْطُ بارٍ` → `ضغط بار`; `رفرفة جانبي` → `رفرفه جانبي`; `Bench  Press` → `bench press`.

**Matching** (`CatalogRepository.search`): the query is normalized and split into tokens. A row matches if **every** token is a substring of `search_norm` (SQL `LIKE '%tok%' ESCAPE '\'` per token; `%`/`_` in the query are literal). Ranking: exact alias/name match > prefix match > substring match, then English name. Optional filters: `target`, `equipment`.

## `data/ar/exercise_names_ar.json`

```json
{
  "0025": { "ar": "ضغط بار مستوي", "aliases": ["بنش", "بنش برس"], "reviewed": false }
}
```
- Keys are dataset ids. `ar` is the primary Arabic name as said in Egyptian gyms. `aliases` holds slang, English-in-Arabic-letters and common misspellings.
- `reviewed: false` until a native speaker confirms it. Unreviewed names are still shipped.
- Phase 3 drafts the **50 most common exercises only**. The rest is in PLAN.md (batches of 100).

## `data/programs/programs.json`

```jsonc
{
  "version": 1,
  "programs": [{
    "id": "ppl",
    "name": { "ar": "…", "en": "Push / Pull / Legs" },
    "description": { "ar": "…", "en": "…" },
    "days_per_week": 6,
    "level": "intermediate",            // beginner | intermediate
    "routines": [{
      "id": "ppl_push",
      "name": { "ar": "…", "en": "Push" },
      "exercises": [{ "exercise_id": "0025", "sets": 4, "reps": [6, 8], "rest_seconds": 150 }]
    }]
  }]
}
```
`reps` is a `[min, max]` range (`[5, 5]` = exactly 5). Every `exercise_id` must exist in `exercises.json` (checked by `build_catalog`). All exercises used by the three programs have Arabic names. When a program is copied into the user's routines, each set's `target_reps` = the range **max** (the routines feature may show the full range from the program JSON).

## Backup format (export/import)

A single JSON file `azm-backup-YYYYMMDD-HHmm.json`: `{ "format": "azm-backup", "version": 1, "exported_at": …, "app_version": …, "settings": {…}, "routines": [...], "routine_exercises": [...], "routine_sets": [...], "workouts": [...], "workout_exercises": [...], "workout_sets": [...] }`. Catalog data is not included. Import replaces user tables after a confirmation dialog (merge by UUID is a v2 idea).
