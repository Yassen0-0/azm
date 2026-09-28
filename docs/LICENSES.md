# Licenses — read before touching `media/` or anything that ships

> **azm contains unlicensed media (`media/`, © Gym visual). Never make this repo public and never add a collaborator until the Gym visual licence is bought.** (Owner's decision, 2026-09-28.)

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

1. `media/` is **committed to the azm repo** (owner's decision, 2026-09-28, see below) and nowhere else: never commit it to any other repo, never force it into a public place. **Because azm contains this unlicensed media, azm must NEVER be made public and must NEVER get a collaborator (besides the owner) until the Gym visual licence is bought.**
2. **Never upload** `media/` (or any file from it) to a public URL, CDN, R2 bucket, issue, gist, chat or artifact. *Only exception: the PRIVATE, owner-only azm repo itself and its releases (owner only).*
3. **Never ship** it: not in app assets, not in a build, not in screenshots for the stores or committed to azm. *Only exception: the owner-only `personal` Android flavor built by `tools/release_personal.sh` for the owner's own phone.* Tester and store builds never contain media (`tools/release_apk.sh` aborts if they do).
4. **Never use the media as input to AI image, animation or video generation** (explicitly forbidden by Gym visual's terms). This includes "reference", "style", tracing and upscaling.
5. Dev use (local screens, a local static server on your own machine) is fine while building.
6. Any media shown in the app must carry the attribution "© Gym visual — https://gymvisual.com/" (exercise detail screen, the exercise preview sheet + Licenses screen).
7. These rules may only be changed by the project owner. Agents must not edit this section. *(The owner changed rules 1–3 on 2026-09-27 to allow a private personal copy, and again on 2026-09-28 to move that copy into azm.)*

## Media in azm (owner's decision, 2026-09-28)

**Still no licence.** Keeping the media in a private repo and bundling it in a personal build doesn't license anything; it only keeps the unlicensed use private and personal. The owner decided to accept that for the owner's own phone, and on 2026-09-28 moved the media into azm so that Claude Code on the web (which only has access to azm) can work with it.

- **`media/`** (`images/` + `videos/`, 1,324 each) is committed in **`Yassen0-0/azm`**, which is **PRIVATE and owner-only**: **never make it public, never add collaborators, never share a link, file or clone, until the Gym visual licence is bought** (and even then only licensed files may ship).
- **Privacy guard:** every script that talks to GitHub (`tools/release_apk.sh`, `tools/release_personal.sh`, `./gh_env` for every `git push` and `gh release`) aborts unless azm reports PRIVATE, has no collaborator besides the owner and no pending invitation (`tools/lib/github_guard.sh`); `./gh_env` refuses visibility changes outright. Pushes also run the history audit (`tools/audit_history.sh`: media allowed; secrets, tokens, keystores, `.env` and `.tooling/` refused).
- **Personal flavor** (`tools/release_personal.sh`): Android `app.azm.gym.personal`, launcher "عزم تجريبي / Azm Dev", media bundled (works offline), "© Gym visual — https://gymvisual.com/" shown with it. Its APK is released as a prerelease `personal-b<N>` in the private azm repo only, never sent to anyone, never installed on anyone else's phone.
- **Public/tester/store builds show media only after a Gym visual licence is bought**, and then only the licensed files, from R2 (launch plan below). Screenshots that show media are never committed.
- Rule 4 still applies: never feed any of it to AI image/animation/video generation.

## Launch plan for media

1. Buy a commercial license from gymvisual.com (one-time purchase, app use allowed) for the **~150–200 most-used exercises**: the 50 drafted in `data/ar/` first, then the programs' exercises, then by expected usage.
2. Host **only the purchased files** on **Cloudflare R2** (`tools/upload_media_r2.dart`, PLAN.md). Respect the resolution and attribution terms of the purchased license.
3. `MediaResolver` returns a URL only for ids in the licensed set (an allow-list shipped with the catalog). Everything else gets `null` → fallback UI (muscle icon).
4. Record purchase details (date, invoice id, exercise ids, license terms) in this file when bought.

## Attribution texts

- Dataset (MIT): "Exercise data © 2026 Hasan Emir Yıldırım, MIT License" + full text from `data/raw/LICENSE`.
- Media (when licensed): "© Gym visual — https://gymvisual.com/".
- Font: "Readex Pro © The Readex Pro Project Authors, SIL OFL 1.1".
