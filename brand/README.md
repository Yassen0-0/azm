# Brand

## Files

| File | Status |
|---|---|
| `logo-concept-a.svg` | **Initial concept, to be refined.** A lifter drives a barbell up a rising diagonal line (the "effort"/عزم). The plate is the brand blue `#4D9BFF` (dark-theme accent) on a black rounded plate (`rx=22`). |

Colours come from the design system (`../design/theme.json`): black plate, white strokes, accent blue. Don't introduce new colours.

## Still to do (see `docs/PLAN.md` → `brand/**`)

- [ ] Refine the concept: optical balance at 16–29 px, stroke weights that survive small sizes, and a check that the figure reads in both LTR and RTL contexts (the mark is not mirrored).
- [ ] **Android adaptive icon:** foreground (108 dp canvas, safe zone 66 dp) + background layers, and **monochrome** layer (Android 13+ themed icons).
- [ ] **Android legacy** `mipmap-*` PNGs (mdpi → xxxhdpi) + Play Store 512×512.
- [ ] **iOS app icon:** 1024×1024 single-size asset, with **light, dark and tinted** variants (iOS 18+ appearances). No transparency on the light variant.
- [ ] Splash / launch screen mark (Android 12+ splash API icon + iOS LaunchScreen).
- [ ] Store listing assets (feature graphic 1024×500, screenshots) — later.

Exports go in `brand/exports/` (source SVGs stay here) and are wired into `app/android` / `app/ios` by the owning task.
