# Azm (عزم) — Product spec

> Source of truth for *what* the app does. For *how it looks* see [DESIGN.md](DESIGN.md); for *how it is built* see [ARCHITECTURE.md](ARCHITECTURE.md) and [DATA.md](DATA.md). Assumptions and later changes are recorded in [DECISIONS_LOG.md](DECISIONS_LOG.md).

## Identity

| | Arabic | English |
|---|---|---|
| App name | عزم | Azm |
| Launcher label | `عزم` (Arabic devices) | `Azm` (all other locales) |
| Store title | `عزم - متتبع الجيم` | `Azm - Gym Tracker` |
| Package / bundle id | `app.azm.gym` | |

**What it is:** a Hevy-style gym workout tracker for Android and iOS.

**Differentiator:** built for the **Egyptian gym-goer**. The Arabic sounds like the gym: exercises have Egyptian slang names, and search understands them (`بنش` finds bench press). Proper RTL, bilingual everywhere.

**North-star metric:** from app open to the **first set logged in ≤ 3 taps**.

## Scope of v1

- **Fully offline.** No accounts, no backend. The only network use is downloading exercise media (thumbnails/GIFs) from a CDN.
- **Backup** is a JSON file the user exports and imports (settings → backup).
- Android + iOS phones. Arabic (RTL) and English (LTR), switchable in-app.

## v1 features

### 1. Exercise library
- **Bilingual search:** Arabic formal name, Egyptian slang aliases and English all find the same exercise. Search runs over a normalized field (see DATA.md → *Arabic search normalization*), so `أ/ا/إ`, `ة/ه`, `ى/ي`, tashkeel, etc. don't matter.
- **Filters** (library + exercise picker): a filter bar under the search with three chips, **Place · Muscle group · Equipment**, each opening a bottom sheet with a grid of cards (icon + name), **multi-select**, a live **"Show N results"** button and **"Clear filters"** (clears that sheet). Filters combine **OR within a type, AND across types**, and AND with the search text. An active chip shows how many of its cards are selected; the result bar offers "Clear filters" (all types). The **last-used filters are remembered per screen** (library and picker separately).
  - **Place:** Gym (everything) · Home (bodyweight, dumbbell, kettlebell, bands) · Resistance bands (band-type only), derived from the equipment through `data/place_mapping.json`.
  - **Muscle group** in three sections: Upper body (abs, biceps, chest, forearms, lats, lower back, neck, shoulders, traps, triceps, upper back) · Lower body (abductors, adductors, calves, glutes, hamstrings, quads) · Other (cardio, full body, other); from the dataset `target` (then `body_part`) through `data/muscle_mapping.json`.
  - **Equipment:** none/bodyweight, barbell, dumbbell, kettlebell, machine, cable, plate, resistance band, suspension band, other; every dataset value mapped in `data/equipment_mapping.json`.
  - Arabic labels use Egyptian gym words (بطن، باي، صدر، سواعد، ضهر، كتف، ترابيس، تراي، رجل أمامي، خلفي، سمانة، مؤخرة، دمبل، بار، كيتل بل، أحبال مقاومة). Card icons are Azm's own (brand pipeline), incl. a body silhouette with the muscle group highlighted.
- **Two names per exercise:** the primary name in the app language, and the secondary name smaller, in the other language. If an exercise has no Arabic name yet, the Arabic UI shows the English name as primary and no secondary.
- List rows show **thumbnails only** (static). The animated GIF plays, looping, on the exercise detail screen and in the **quick preview**: tapping a row's thumbnail (library, picker, active workout, routines, history, stats) opens a bottom sheet with the looping GIF, the exercise name in the app language and the Gym visual credit; tapping the rest of the row keeps its own action.
- Missing media (no license or offline) → fallback UI (muscle icon).

### 2. Live workout logging
Each exercise in a workout shows a table of sets. Columns per set: **type · previous · weight · reps · ✓**.

- **Set types:**

  | Type | Label AR / EN | Color |
  |---|---|---|
  | normal | its number (1, 2, 3, …; counts normal sets only) | default |
  | warm-up | `ح` / `W` | amber (`warmup`) |
  | drop | `د` / `D` | default |
  | failure | `ف` / `F` | default (**never red**: failure sets are intentional, not mistakes) |

  Tap the set label to change its type.
- **Previous:** shows the same set (same exercise, same set index) from the last finished workout that contained this exercise, e.g. `60 kg × 8`. Tapping it fills weight + reps.
- **✓ (complete):** the row tints green (`setDone`), light haptic, and the rest timer starts automatically.
- **Delete a set:** swipe the row toward the **start** edge (the platform convention: right→left in English, left→right in Arabic), or **long-press** it → "Delete set" (fallback). A snackbar offers **Undo for ~4 s**. The remaining sets renumber and Lifted / sets / PRs update at once. Works for any set (✓ or not, the last one of an exercise too), in the live workout, a past workout and the routine editor. A deleted set is gone from the database immediately, so no total, PR, "previous" or history ever counts it; Undo puts the same row back.
- **Custom numeric keypad** (not the system keyboard): digits 0–9, decimal point, `−2.5` / `+2.5` steppers (in the display unit), backspace, next/done.
- **Header** shows 3 live stats: **duration | Lifted (شِلت) | sets** (completed sets count).
- The screen can **minimize** into a persistent bar above the tab bar (ActiveWorkoutBar: name, elapsed time, mini rest timer). Tap it to restore.
- **Every change is written to the database immediately.** Killing the app or a dead battery loses nothing. On launch, if a workout with status `active` exists, the app resumes it.
- At most **one** active workout at a time.

### 3. Rest timer
- Bottom bar with countdown and **−15 / +15 / skip**. Haptic + sound when it ends.
- Default **90 s**; per-exercise override (stored on the routine exercise, else the global default from settings).
- Implemented from an **end timestamp** plus a **scheduled local notification**, never a ticking counter. The UI derives the remaining time from `endsAt − now`, so it survives backgrounding, app kill and clock-display pauses. ±15 s moves `endsAt` and reschedules the notification; skip cancels it.

### 4. Routines
- Create and edit: name, notes, add exercises (multi-select picker), target sets per exercise (type, target reps, optional target weight), rest override, **drag to reorder**.
- **Start in one tap** from the Workout tab. The workout is prefilled from the routine; set rows start from the targets and show *previous* values.
- **Ready-made programs** in Arabic + English (Push/Pull/Legs, Upper/Lower, Full Body 3×/week). The user copies one into their routines, and can then edit it.

### 5. History & PRs
- **Workout cards:** name, date, duration, lifted, PR count, best set per exercise.
- **Edit past workouts** (sets, weights, reps, types, add/remove exercises). Edits recompute PRs.
- **Per-exercise chart** on the exercise detail screen (best set / est. 1RM / volume over time).
- **PR types** (per exercise, over completed sets of finished workouts):
  1. **Heaviest weight**: max `weight_kg`.
  2. **Best estimated 1RM**: Epley, `w × (1 + reps / 30)`. For reps = 1, e1RM = w.
  3. **Best single-set volume**: max `weight_kg × reps`.
  - A set is a PR if it strictly beats the best value from all *earlier* workouts. Warm-up sets never count as PRs; they do count toward Lifted.
- **PR celebration:** the number scales with the *celebration* motion curve, and the set gets a 🏆 badge.

### 6. Lifted (شِلت / Lifted)
- **Definition:** the sum of `weight × reps` over all ✓ sets, **including warm-ups** (it's about the feeling of strength).
- **Bodyweight exercises** count only the added weight, which is 0 if none, until the user's bodyweight exists (a v2 feature).
- The number **animates up** (motion `value`, 600 ms) on each ✓.
- **Post-workout summary** shows a fun comparison. For example: `شِلت 8,450 kg — وزن 6 عربيات ملاكي 🚗`.

  | Object | Approx. kg | AR | EN |
  |---|---|---|---|
  | car | 1,400 | عربية ملاكي 🚗 | car 🚗 |
  | pyramid stone block | 2,500 | حجر من الهرم 🗿 | pyramid stone block 🗿 |
  | elephant | 6,000 | فيل 🐘 | elephant 🐘 |

  Pick the **smallest** object whose count (`round(lifted / kg)`) falls between **1 and 20**: cars first, then pyramid blocks, then elephants. This matches the example: 8,450 kg → 6 cars. If none qualifies (< 700 kg lifted), show no comparison. Above 20 elephants, show the elephant count anyway.
- **History** shows the all-time lifted total, e.g. `شِلت لحد دلوقتي 1.2 مليون kg` / `Lifted so far: 1.2M kg`.

### 7. Onboarding (first run only, max 2 screens)
1. Unit: **kg / lb**.
2. Optional: pick a ready program (or skip).

Language follows the device (changeable later in settings).

### 8. Settings
- Language: **System (default) / العربية / English**
- Theme: **Dark (default) / Light**
- Unit: kg / lb
- Default rest time
- Backup: export / import JSON

## Units & numbers
- All weights are stored in **kg**. lb is a display conversion only (`1 kg = 2.2046226218 lb`). Display is rounded to 0.1 in the chosen unit; the keypad's ±2.5 step is in the display unit.
- **Western digits (0–9)** in both languages, with tabular figures.

## Navigation

Three tabs, with settings reachable from a header icon:

| Tab | AR | Content |
|---|---|---|
| **Workout** (home) | تمرين | Big "Start workout" (empty workout), my routines, ready programs |
| **History** | السجل | List / calendar, stats, PRs, all-time lifted |
| **Exercises** | التمارين | Library (search + filters) |

**Screens:** onboarding · routine editor · active workout · workout summary · exercise picker (multi-select) · exercise detail (GIF, instructions, muscles, your history, chart, PRs) · past workout detail (editable) · settings.

## Postponed (v2+)
Accounts + sync (Supabase) · social feed · coach ↔ client · payments (InstaPay / Fawry) · Live Activities / widgets / Apple Watch · body measurements (and so bodyweight-based Lifted) · AI features · plate calculator.
