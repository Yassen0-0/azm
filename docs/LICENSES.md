# Licenses — read before touching `media/` or anything that ships

## Summary

| Asset | License | May ship in the app? |
|---|---|---|
| Exercise **text/data** (names, body parts, muscles, equipment, instructions) from `data/raw/exercises.json` | **MIT** © 2026 Hasan Emir Yıldırım (`data/raw/LICENSE`) | **Yes**, keeping the MIT notice (in-app "Licenses" screen via `showLicensePage` + `LicenseRegistry`) |
| Exercise **images and GIFs** (`media/images`, `media/videos`) | **© Gym visual** (https://gymvisual.com/). **Not MIT.** | **No.** Only media **we have bought a license for**, served from our own R2, may appear in a release. |
| Readex Pro font (`design/ReadexPro.ttf`) | SIL Open Font License 1.1 (Google Fonts) | Yes (bundle the OFL text with the app's licenses) |
| Our Arabic names, programs, code, design adaptations | Ours | Yes |
| Flutter / pub packages | Their own licenses (mostly BSD/MIT/Apache) | Yes; Flutter's license page aggregates them |

## Media: status and rules (critical)

**Status on 2026-09-26: we own NO media license.** The dataset repo includes the media under the rights holder's *separate written permission to that repo*, at **180×180 only**, with mandatory attribution **"© Gym visual — https://gymvisual.com/"** (`data/raw/NOTICE.md`). The repo states explicitly that **cloning it grants no license to the media**. That permission does **not** transfer to us.

Rules for every agent and human:

1. `media/` is **dev-only** and **gitignored**. Never commit it to any repo, never force-add it.
2. **Never upload** `media/` (or any file from it) to a public URL, CDN, R2 bucket, issue, gist, chat or artifact.
3. **Never ship** it: not in app assets, not in a build, not in screenshots for the stores.
4. **Never use the media as input to AI image, animation or video generation** (explicitly forbidden by Gym visual's terms). This includes "reference", "style", tracing and upscaling.
5. Dev use (local screens, a local static server on your own machine) is fine while building.
6. Any media shown in the app must carry the attribution "© Gym visual — https://gymvisual.com/" (exercise detail screen + Licenses screen).
7. These rules may only be changed by the project owner. Agents must not edit this section.

## Launch plan for media

1. Buy a commercial license from gymvisual.com (one-time purchase, app use allowed) for the **~150–200 most-used exercises**: the 50 drafted in `data/ar/` first, then the programs' exercises, then by expected usage.
2. Host **only the purchased files** on **Cloudflare R2** (`tools/upload_media_r2.dart`, PLAN.md). Respect the resolution and attribution terms of the purchased license.
3. `MediaResolver` returns a URL only for ids in the licensed set (an allow-list shipped with the catalog). Everything else gets `null` → fallback UI (muscle icon).
4. Record purchase details (date, invoice id, exercise ids, license terms) in this file when bought.

## Attribution texts

- Dataset (MIT): "Exercise data © 2026 Hasan Emir Yıldırım, MIT License" + full text from `data/raw/LICENSE`.
- Media (when licensed): "© Gym visual — https://gymvisual.com/".
- Font: "Readex Pro © The Readex Pro Project Authors, SIL OFL 1.1".
