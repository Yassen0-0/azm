# Brand

**One source, one command.** Every app icon and splash asset on both platforms is generated from `logo-concept-a.svg`:

```sh
source ./env.sh && brand/generate.sh           # regenerate everything (≈3 s)
source ./env.sh && brand/generate.sh --check   # fail if committed assets ≠ a fresh run
```

To change the logo: edit or replace `logo-concept-a.svg`, run `brand/generate.sh`, look at `exports/review_sheet.png` and `exports/legibility_16-64px.png`, run `brand/generate.sh --check` (must say OK), commit the SVG **and** every regenerated file together. Never hand-edit a generated file; the next run overwrites it.

## Files

| File | What |
|---|---|
| `logo-concept-a.svg` | **The only source.** A lifter pushes a barbell plate up a rising line (the effort, عزم). Black rounded plate (`rx=22`), white strokes, plate in the brand blue `#4D9BFF` (dark-theme accent). Not mirrored in RTL. |
| `generate.sh` | The command. Compiles `pipeline/azm_brand.swift` (cached in `.tooling/tmp`), wipes the outputs it owns, regenerates them. `--check` renders into `.tooling/tmp/brand-check` and compares byte for byte (missing, extra or changed file → exit 1). Every step is capped (`AZM_BRAND_TIMEOUT`, default 300 s). |
| `pipeline/azm_brand.swift` | The renderer. macOS only, nothing installed: AppKit renders the SVG, ImageIO writes PNGs. Deterministic output. |
| `exports/play_store_512.png` | Play Store icon, 512 × 512, full-bleed square (Play applies its own mask). |
| `exports/review_sheet.png` | Review only: legacy · adaptive (circle mask) · Android 13 themed · notification · iOS light · dark · tinted · splash. |
| `exports/legibility_16-64px.png` | Review only: the launcher icon at 16, 20, 29, 40, 48, 64 px, real pixels, on the light and dark page backgrounds, plus 48 px magnified 4×. |

## Source contract

The pipeline derives every variant from the SVG, so the SVG must follow three rules (`generate.sh` fails with a message otherwise):

1. **Square `viewBox`.**
2. **The first element is the plate:** a self-closing `<rect>` covering the whole viewBox with a `fill="#RRGGBB"` (optionally `rx`). Everything after it is **the mark**.
3. **Only design-system colours** (any hex in `design/theme.json` → `colors`). No new colours (docs/DESIGN.md).

Derived variants:

| Variant | How | Used for |
|---|---|---|
| full | the SVG as-is (rounded plate, transparent corners) | Android legacy launcher, legibility sheet |
| square | plate without `rx` | iOS light (flattened, no transparency), Play Store |
| mark | plate removed, transparent | Android adaptive foreground, iOS dark, splash |
| monochrome | mark → white; pixels painted in the plate colour (the sleeve hole) → transparent | Android themed icon, notification icon |
| grayscale | luminance of the square variant | iOS tinted |

Placement is measured, not hard-coded: the mark is rendered once at 1024 px, and its farthest painted pixel from the centre decides the scale for circle-safe placements (adaptive 66 dp of 108 dp, splash 192 dp of 288 dp). The notification icon fits the monochrome mark's bounding box into 22 of 24 dp.

## Outputs (all generated)

| Platform | Path | Content |
|---|---|---|
| Android | `res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` | legacy icon (API < 26), 48 dp, 2 dp margin |
| | `res/mipmap-*/ic_launcher_foreground.png`, `ic_launcher_monochrome.png` | adaptive layers, 108 dp, mark inside the 66 dp safe zone |
| | `res/mipmap-anydpi-v26/ic_launcher.xml` | adaptive icon: background `@color/azm_icon_background` + foreground + **monochrome** (Android 13+ themed icons) |
| | `res/drawable-*dpi/ic_stat_azm.png` | rest-timer notification icon, 24 dp, white on transparent (name `ic_stat_azm` is the contract with `rest_notifications.dart`; `raw/keep.xml` keeps it) |
| | `res/drawable-*dpi/splash_icon.png` | splash mark, 288 dp, inside the 192 dp circle |
| | `res/drawable{,-v21}/launch_background.xml` | pre-Android-12 launch window: dark background + `splash_icon` |
| | `res/values{,-night}/styles.xml`, `res/values{,-night}-v31/styles.xml` | `LaunchTheme` / `NormalTheme`; v31 adds the Android 12 splash API (`windowSplashScreenBackground` / `AnimatedIcon`) |
| | `res/values/colors.xml` | `azm_icon_background` = plate fill, `azm_splash_background` = dark `pageBackground` |
| iOS | `Assets.xcassets/AppIcon.appiconset/` | single-size 1024 icon: `AppIcon-light` (opaque), `AppIcon-dark` (transparent, iOS draws the dark backdrop), `AppIcon-tinted` (grayscale); `Contents.json` appearances |
| | `Assets.xcassets/LaunchImage.imageset/` | splash mark at 288 pt @1x/2x/3x (same geometry as Android's `splash_icon`) |
| | `Base.lproj/LaunchScreen.storyboard` | launch screen: dark `pageBackground` + centred `LaunchImage` |
| Store | `brand/exports/play_store_512.png` | Play Store icon |

Not generated (kept by hand, never touched by the pipeline): `res/values{,-ar}/strings.xml` (launcher name `عزم` / `Azm`), `res/raw/keep.xml`, iOS `InfoPlist.strings`.

## Still to do

- [ ] Store listing assets (feature graphic 1024 × 500, screenshots): later.
- [ ] Real-device checks (Pixel, Samsung, iPhone launchers; small sizes; splash): `docs/DEVICE_TEST_CHECKLIST.md` → *Brand*.
