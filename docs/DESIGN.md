# Azm — Design system

Azm reuses the **Ather** design system (tokens in [`design/theme.json`](../design/theme.json), CSS mirror in [`design/theme.css`](../design/theme.css), font [`design/ReadexPro.ttf`](../design/ReadexPro.ttf)) with the **gym adaptations** below. `theme.json` is the raw source; **this document wins** wherever the two differ (renamed tokens, dark default, amber).

The Flutter port lives in `app/lib/core/theme/` (Phase 2). No widget may use a colour, size, radius, duration or text style that is not defined there.

## Principles (inherited, still binding)

- White + grey + black, **one** accent blue, one green, one red, and **one new amber** (Azm's only addition). No other hues. **No gradients, no glows, no shadows**: the card is the elevation (a card sits on a page of a different value).
- **Glass** (blur σ 24, card tint at 85%, `glassBorder` edge) is used **only on the floating tab bar**.
- **Blue means active**: selected tab, primary button, ticked checkbox, progress fill. It never means "done/correct".
- **Tabular figures** (`tnum`) on every number. **Max font weight 700.**
- Spacing ladder only: **4 · 8 · 12 · 16 · 20 · 24** (`xxs xs md xl xxl xxxl`). Page margin 16, card padding 16, gap between cards 12.
- **Concentric radii**: inner radius = outer radius − padding.
- No ripples, no scrollbars, no scroll tint. Press feedback = `scale(0.97)` over 140 ms.
- "No data yet" is grey `—` (`textNoData`), never `0` and never red.
- **Reduced motion is respected everywhere**: jump to the end state, with no scale/rise.
- **Arabic-first, RTL**. Page transitions fade + rise **vertically** (direction-neutral). Layout uses only `start/end` (`EdgeInsetsDirectional`, `AlignmentDirectional`), never `left/right`.
- **Western digits (0–9)** in both languages.

## Gym adaptations

### 1. Dark is the default theme
Dark is the default on first run; light is available in settings. Dark is a re-mapping of light (same tokens, different values), not a redesign.

### 2. Semantic tokens renamed by function

| Ather token | Azm token | Light | Dark | Meaning in Azm |
|---|---|---|---|---|
| `right` | **`setDone`** | `#34C759` | `#34C759` | Completed set (row tint, ✓), switch on |
| `rightText` | **`setDoneText`** | `#1B7F3B` | `#34C759` | Green text |
| — (new) | **`setDoneTint`** | `#34C7591F` | `#34C75926` | Background wash of a completed set row (derived: `setDone` at 12% / 15%) |
| `wrong` | **`destructive`** | `#FF3B30` | `#FF3B30` | Delete, missed/invalid, error. **Never a failure set.** |
| `wrongTint` | **`destructiveTint`** | `#FF3B301A` | `#FF3B3026` | Error banner, delete swipe background |
| `wrongText` | **`destructiveText`** | `#C93229` | `#FF3B30` | Red small text |
| — (new hue) | **`warmup`** | `#FF9F0A` | `#FF9F0A` | Warm-up set label/fill (amber) |
| — (new) | **`warmupText`** | `#B25F00` | `#FF9F0A` | Amber text on light cards (contrast-safe) |
| — (new) | **`warmupTint`** | `#FF9F0A1F` | `#FF9F0A26` | Amber wash (warm-up label chip) |
| — (new) | **`pr`** | = `accent` | = `accent` | PR 🏆 badge and PR numbers. It reuses the accent blue, so no extra hue is added; the 🏆 emoji carries the "gold" meaning. |
| `onState` | `onState` | `#FFFFFF` | `#FFFFFF` | Text/icons on `setDone`, `destructive`, `warmup` fills |

All other colour tokens (`pageBackground`, `card`, `muted`, `fill`, `track`, `text*`, `accent`, `onAccent`, `accentSoft`, `actionDisabled`, `divider`, `glassBorder`, `switch*`, `checkbox*`, `dashedBorder`, `scrim`, `actionPrimary`, `onPrimary`) keep Ather's names and values; see `design/theme.json` → `colors`.

**Removed from Ather's colour logic:** the `masteryRule` (study mastery %). Azm has no mastery score. Progress bars use `accent` for the fill.

### 3. Typography

Font: **Readex Pro** (variable, `wght` 200–700, Arabic + Latin), the **only** family. Always drive the `wght` axis explicitly (`fontVariations: [FontVariation('wght', w)]`) or every weight renders the same. `fontFeatures: [tnum]` everywhere.

The Ather type scale is kept (sizes/weights/line heights in `theme.json` → `typography.styles`). Study-specific styles are renamed:

| Ather style | Azm style | Size / weight | Azm use |
|---|---|---|---|
| `resultNumber` | `summaryNumber` | 56 / 700 | Big Lifted total on the workout summary |
| `celebrationNumber` | `prNumber` | 44 / 700 | PR celebration number |
| `lockWordmark` | `wordmark` | 38 / 700 | "عزم / Azm" wordmark on splash |
| `lessonNumber` | `liftedNumber` | 34 / 700 | LiftedCounter in the history header |
| `today` | `homeTitle` | 32 / 700 | Workout tab title (display) |
| `cardNumber` | `cardNumber` | 30 / 700 | Stat card number |
| `inputLarge` | `keypadValue` | 28 / 700 | Value shown above the WeightKeypad |
| `rowNumber` | `rowNumber` | **19 / 700** | **Set-row weight/reps**, stat values |
| `weekLabel` colour / `dayLabel` | `dayLabel` | 13 / 600 | Calendar weekday letters (History) |

Every other style (`stepTitle`, `sectionTitle`, `screenTitle`, `rowTitle`, `cardTitle`, `button`, `body`, `secondary`, `chipLabel`, `tabLabel`, `badgeLabel`, `micro`, …) keeps its Ather name and values. Material text theme mapping is as in `theme.json` → `materialTextTheme`, with `today` → `homeTitle`.

### 4. Motion

Unchanged from Ather (`theme.json` → `motion`): easing `standard / press / sheet / celebration / value`, durations (`press 140`, `tick 220`, `sheet 280`, `celebration 500`, `value 600`, …), springs `crisp / select / settle / celebrate`. Gym uses:

| Moment | Motion |
|---|---|
| ✓ a set | row tint cross-fade `tick` 220 ms + light haptic |
| Lifted number rising | `value` 600 ms, `value` easing (count-up) |
| PR number / 🏆 badge | `celebrate` spring (the only overshoot); the badge itself never overshoots past 1.0 |
| Rest timer bar in/out | `settle` spring / `exit` 200 ms |
| Workout ⇄ minimized bar | `sheet` 280 ms |
| Reduced motion | jump to the end state; haptics stay |
| Undo window after deleting a set | `undoWindow` 4 s (a duration token, not an animation) |

### 5. Sizes

Inherited: `minTouchTarget 48`, `primaryButton 52`, `headerButton 36`, `input 46`, tab bar 64 high lifted 12, sheet handle 36×5, card radius 16, button 14, input 12, sheet 22, pill 999.

Gym additions:

| Token | Value | Use |
|---|---|---|
| `setRowMinHeight` | **52** | Minimum height of a SetRow |
| `setCellMinWidth` | 48 | Weight / reps / ✓ cells (touch target ≥ 48) |
| `keypadKeyHeight` | 52 | WeightKeypad key |
| `restBarHeight` | 64 | RestTimerBar |
| `activeBarHeight` | 56 | ActiveWorkoutBar (minimized workout, above the tab bar) |
| `thumbnail` | 48 (list), 72 (card) | Exercise thumbnail square, radius `input` 12 |
| `chartHeight` | 144 | Progress chart on the exercise detail |
| `exerciseMedia` | 216 | Max edge of the exercise GIF / fallback square on the detail |
| `chartStroke` | 2 | Progress chart line width |
| `chartDot` | 4 | Progress chart data-point radius |
| `filterIcon` | 44 | Icon on a filter card |
| `filterCard` | 108 | Height of a filter card (icon + up to two label lines) |
| `filterCount` | 18 | Count bubble on an active filter chip; ✓ badge on a selected card |

All touch targets are ≥ 48 even when the visible element is smaller.

## New components

| Component | Description |
|---|---|
| **SetRow** | `[type label] [previous] [weight] [reps] [✓]`, min height 52, numbers in `rowNumber`. Type label: set number (normal), `ح/W` in `warmup`, `د/D`, `ف/F`. Tap label → type menu. Tap previous → fills weight + reps. ✓ → row gets `setDoneTint`, ✓ turns `setDone` with `onState` check, haptic. **Swipe to delete:** the whole row slides with the finger toward the *start* edge (left in English, right in Arabic; tracks from touch-down) over a `destructive` panel with square corners, full row height, from the row's end edge to the **screen edge** (it bleeds over the page margin; section cards don't clip), growing with the finger. "Delete"/"امسح" + trash (`controlLabel`, `onState`) sit at the screen-edge end of the panel and never truncate: text only when it fits at the current text scale, else the icon alone. Release > 25 % → rests open (open width fits the label at the current text scale, 64 px … 50 % of the row), spring `crisp`; > 60 % → delete (light haptic when crossing), otherwise spring back. One open row app-wide; a tap outside, a tap on the row, a scroll or starting to drag another row closes it. Delete = slide out (`exit` 200 ms) + height collapse (`exit`) before the DB write; long-press → set menu → "Delete set" does the same. A snackbar offers Undo for `undoWindow` (4 s); a new deletion replaces it instantly. PR sets show a 🏆 badge. **One component for every set table** (`core/widgets/set_row.dart`): the live workout uses all columns; a past workout has no ✓ column (every set there is done); the routine editor has neither previous nor ✓. Labels, type names and the type menu come from `core/l10n/set_labels.dart` + `core/widgets/set_type_sheet.dart`. |
| **WeightKeypad** | Custom bottom keypad replacing the system keyboard: 3×4 digits + decimal + backspace, `−2.5` / `+2.5`, next/done. Keys 52 high on `card`, radius `button`. The value preview uses `keypadValue`. Screens use `SetValueKeypad` + `SetKeypadBuffer` (`core/widgets/set_keypad.dart`): shared wording, limits (4 digits + 1 decimal for weight, 3 for reps) and a selection haptic on ±. |
| **RestTimerBar** | Bottom bar: remaining `mm:ss` (tabular), progress (`track`/`accent`), `−15`, `+15`, skip. Derived from an end timestamp. A **mini** variant (time only) appears inside the ActiveWorkoutBar. |
| **ActiveWorkoutBar** | Persistent bar above the tab bar when the workout is minimized: workout name, elapsed time, mini rest timer; tap to expand. |
| **ExerciseCard** | Thumbnail (or muscle-icon fallback) + primary name (`rowTitle`) + secondary name in the other language (`secondary`) + optional PR badge. |
| **Exercise quick preview** | Tap on any list thumbnail (`ExerciseThumbnail`, press scale like every tappable; semantics "Preview <name>" / "معاينة حركة <name>") → modal bottom sheet (theme sheet, drag handle): primary name (`cardTitle`, start-aligned), the looping GIF in an `exerciseMedia` square (fallback icon when there is no media), the credit "© Gym visual — https://gymvisual.com/" (`micro`, `textMicro`, centred) only when media is shown. Sized by content, scrolls on short screens. The rest of the row keeps its own tap. |
| **MuscleChips** | Horizontal scroll of single-select chips (radius pill, `fill` → `accent` when selected, `chipLabel`). Used by the exercise detail's chart metrics; the library uses the FilterBar. |
| **FilterBar** | Under the library/picker search: three equal-width pills (Place · Muscle group · Equipment), `fill` → `accent` when active, `chipLabel`, a ⌄ when idle and a count bubble (`filterCount` 18, `onAccent` with `accent` number) when active. |
| **Filter sheet** | Modal bottom sheet (theme sheet, ≤ 85 % height): title (`screenTitle`), optional section titles (`smallStrong`, `textSecondary`), a 3-column grid of **FilterCards** (only cards with at least one exercise; a section with none is hidden), and a footer (divider on top) with "Clear filters" / "امسح الفلاتر" (text button, `accent`; same words as the result bar's link) + "Show N results" (primary, disabled at 0). |
| **FilterCard** | `filterCard` (108) high, radius `input`, `fill`; selected = `accentSoft` + 1.5 px `accent` border + a ✓ badge (`filterCount` circle, `accent`/`onAccent`) at the top end; `FilterIcon` (`filterIcon` 44) over the name (`chipLabel`, 2 lines max, `accent` when selected). Press scale like every tappable. |
| **FilterIcon** | Azm's own two-tone vector icons (`brand/icons/*.svg` → `brand/generate.sh` → `core/widgets/filter_icon_paths.dart`): `base` = `textTertiary` (`textSecondary` on a selected card), `accent` = `accent`. Muscle groups = a front/back body silhouette with the group's segments in accent. Never copied or traced from another app, never made from the licensed exercise media. Not mirrored in RTL. |
| **Set deleted snackbar** | Floating snackbar (theme: `actionPrimary` plate, `onPrimary` text and action): "Set deleted · Undo", `undoWindow` (4 s), replaced by the next deletion (`core/widgets/set_undo.dart`). |
| **LiftedCounter** | Number + unit + optional comparison line, animating with `value`. Used in the workout header (small, `rowNumber`), summary (`summaryNumber`) and history (`liftedNumber`). `compact: true` (History's all-time total): exact below 100,000, then `450K` / `1.2M` / `2B` (Arabic `450 ألف` / `1.2 مليون` / `2 مليار`), Western digits, no LTR isolate. |

Inherited components (primary button, card, input, bottom sheet, dialog, chip, segmented control, progress bar, switch, checkbox, toast, error banner, app bar, **floating glass tab bar**) follow `theme.json` → `components`, with `wrong*` → `destructive*` and `right` → `setDone`.

## Removed Ather-specific pieces

- Study-only names: `lessonNumber`, `lockWordmark`, `today` (renamed above), `masteryRule`, "overdue" semantics.
- Ather's brand mark (the wobbled ring) and wordmark. Azm's mark lives in `brand/`.

## Iconography

Rounded, 2 px-ish stroke icons (Material Symbols Rounded or an equivalent built-in set), size 24 (tab bar 25). Muscle fallback icon for missing exercise media. Directional icons (back/forward chevrons, swipe hints) **must mirror in RTL**; non-directional ones (✓, 🏆, timer) must not.
