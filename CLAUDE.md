# Rules for every agent working in Azm

This repo's root **is** the project root (`env.sh`, `docs/`, `app/`, … all live here). Paths in `docs/ORIGINAL_BRIEF.md` that start with `azm/` map to the root (`azm/X` → `X`).

## Sandbox (highest priority)

- **Never read, write, install or download outside the project root.** That includes `~`, `/tmp`, `/usr/local`, `/opt`, Homebrew, global npm/pip/gem and global git config. `~/dev` holds an older, unrelated toolchain: never use it.
- **Every shell command starts with `source ./env.sh &&`** (run from the root). All SDKs, caches and temp files live in `.tooling/`. `env.sh` **fails fast** (so the `&&` stops the command) when `flutter` doesn't resolve inside `.tooling/` (e.g. `~/dev/flutter`), and every script in `tools/` (+ `brand/generate.sh`, `ios_env`, `gh_env`) sources it with `|| exit 1`. Never run `flutter`/`dart` without it. A Claude Code **PreToolUse hook** (`.claude/settings.json` → `tools/hooks/require_env_sh.sh`) enforces this on the Mac: a Bash command that runs `flutter`/`dart` without `source ./env.sh` (or `./ios_env` / `./gh_env`) in the same command is blocked. It never blocks on Linux (cloud).
- iOS code signing (physical iPhone, `flutter build ios/ipa`, signed `xcodebuild`) → use `./ios_env <command>` instead. Pass `-derivedDataPath .tooling/xcode-derived` to any direct `xcodebuild`.
- **Two allowed exceptions to the sandbox, both through a real-HOME wrapper:** (1) **Xcode** (code signing, DerivedData) → `./ios_env`; (2) **credentials in the macOS Keychain** (GitHub token) → `./gh_env gh …` / `./gh_env git push …`. `gh_env` keeps gh's non-secret config (`GH_CONFIG_DIR`) and git's global config (`GIT_CONFIG_GLOBAL`) inside `.tooling/`; only the token lives in the Keychain. Never store a token in a file (no `--insecure-storage`, no `.env` with tokens), never print one, never ask the owner for one.
- Anything that needs a global install (brew, sudo, global gem/npm) → **stop and ask the owner.**
- Never modify shell profiles, global git config or system settings. Never run `git config --global`.

## Waiting and polling (permanent)

- **Never use an unbounded wait loop** (`until …; do sleep; done`, `while true`, `tail -f` with no end). Every wait/poll has a **timeout** (default max 30 min) or a max iteration count.
- **On timeout: print the last 50 lines of the log and stop.** Don't retry blindly and don't leave the loop or its command running.
- The loop's exit test must match **failure states too** (`Some tests failed`, `Exception`, the process having exited), not only success.
- macOS has **no `timeout`/`gtimeout`**, and installing coreutils would break the sandbox rule. A bare `timeout …` fails with "command not found" and looks like silence. Use these instead:

```sh
LOG=.tooling/tmp/run.log
# Run a long command with a 30-min cap:
( <command> >"$LOG" 2>&1 ) & pid=$!
for i in $(seq 1 360); do kill -0 "$pid" 2>/dev/null || break; sleep 5; done
if kill -0 "$pid" 2>/dev/null; then kill "$pid"; echo "TIMEOUT (30 min)"; tail -50 "$LOG"; exit 1; fi

# Wait for a log condition, max 30 min:
for i in $(seq 1 360); do grep -qE 'All tests passed|Some tests failed|Exception' "$LOG" && break; sleep 5; done
grep -qE 'All tests passed|Some tests failed|Exception' "$LOG" || { echo "TIMEOUT (30 min)"; tail -50 "$LOG"; exit 1; }
```

- Before ending a session, stop any background loops and `flutter drive`/emulator helpers you started. Leave devices from the other window's set alone.

## PLATFORM PARITY RULE (permanent)

**Android and iOS are equal first-class targets.** The owner has no physical iPhone, so the **iOS Simulator is the iOS test device**.

- A feature is **done only when it is built, launched and checked on BOTH the Android emulator AND the iOS Simulator**: same behavior, same layout, in **RTL (Arabic) and LTR (English)**.
- **Proof:** a screenshot of **every screen** of the feature on both platforms, in both languages, in `docs/screenshots/<feature>/{android,ios}/`. Generate them with `tools/screenshots.sh <feature>`, which runs `app/integration_test/<feature>_screens_test.dart` (copy `shell_screens_test.dart`). Look at the images: the layout must match across platforms and mirror correctly between languages.
- Anything that can only be verified on a **real iPhone** (haptics, real notification delivery and sound, background/lock-screen behavior, performance, camera, etc.) goes into `docs/DEVICE_TEST_CHECKLIST.md` for a tester with a real device. Do the same for anything that can't be verified on the Android emulator.
- Devices: set **A** = AVD `azm_api37` (port 5554) + simulator "Azm iPhone A"; set **B** = AVD `azm_api37_b` (port 5556) + "Azm iPhone B". Each parallel window uses its own set (`AZM_DEVICE_SET=A|B`). Never create, erase or change the owner's other simulators.

## Cloud / no devices (Claude Code on the web, CI)

- **Sandbox exception for the cloud:** the sandbox rule protects the owner's Mac. A cloud container is ephemeral and not macOS, so **installing system packages there is allowed** (`apt-get`, e.g. `libsqlite3-dev`). `tools/cloud_setup.sh` installs what it needs itself and says so; on the Mac it never installs anything (it stops and asks instead). Still keep the Flutter SDK, pub cache and temp files in `.tooling/` so the Mac and cloud layouts match.
- **Setup:** `tools/cloud_setup.sh` (installs the pinned Flutter into `.tooling/flutter`, pub get, regenerates l10n + Drift + catalog and fails if the committed copies are stale, then analyze + tests). After it, commands use `source ./env.sh && …` as on the Mac.
- **Do only:** code, `flutter analyze`, `dart analyze` (tools), unit/widget tests (`flutter test`), `tools/check_directionality.sh`, `tools/build_catalog.sh --check`, `tools/gen_l10n.sh`. No emulators, simulators, `flutter drive`, `tools/screenshots.sh`, `brand/generate.sh` (macOS AppKit) or `./ios_env`.
- **Never skip the Platform Parity Rule — defer it.** A feature done in the cloud is **not done**: mark it in `docs/PLAN.md` as `[~] code done (cloud, <date>) — device verification pending (Mac)` and list exactly what the Mac session must run (`tools/screenshots.sh <feature>`, E2E, checklist items). Only a Mac session with both platforms may flip it to `[x]`.
- Don't commit screenshots from the cloud (there are none to take) and don't delete existing ones.
- **Cloud git workflow (owner's rule, 2026-09-29):** pull/rebase onto `origin/main` before starting (`git pull --rebase origin main`), then **push to `main` directly**, not to a session branch. **Never force-push.** Small commits, **one feature per commit**.
- **After each feature:** `flutter analyze` + **all** tests (`flutter test`, `tools/check_directionality.sh`). Then add an entry to `docs/PLAN.md` → *Pending on Mac* naming the commit, the screenshot suites (`tools/screenshots.sh <suite>`) and the device checks it needs.
- **Phone build from the cloud:** push a `personal-b<N>` tag (N = last personal build + 1) → `.github/workflows/android-release.yml` (committed as `docs/ci/android-release.yml` until a Mac session moves it there: the cloud token can't push workflow files) builds the personal APK and publishes it as a prerelease in azm (only the newest 3 personal releases are kept). A `v<ver>-b<build>` tag matching `app/pubspec.yaml` builds the tester APK the same way (notes: `docs/release_notes/<tag>.md`). Both can also be started from Actions → *Android release* → Run workflow.
- **iOS stays Mac-only** (Xcode signing, `./ios_env`): the workflow builds Android only.

## Before any task

Read `docs/SPEC.md`, `docs/DESIGN.md`, `docs/ARCHITECTURE.md` (and `docs/DATA.md` for data work). Then find your task in `docs/PLAN.md`.

## Scope

- Only touch files inside the paths **your task owns** (see `docs/PLAN.md`). Everything else is read-only for you. Need a change elsewhere (new route, DB column, dependency, core widget)? Add it to *Requests* in `docs/PLAN.md` and work around it.
- **Frozen shared files** (owner or bootstrap agent only): `app/pubspec.yaml`, `app/lib/app.dart`, `app/lib/main.dart`, `app/lib/bootstrap.dart`, `app/lib/core/{router,db,theme,utils,media}/**`, `app/lib/core/l10n/*.dart`, `app/integration_test/screenshot_harness.dart`, `tools/**`, `env.sh`.
- **Generated files** (`app/lib/core/l10n/arb/*`, `app/lib/core/l10n/gen/*`, `*.g.dart`, `app/assets/catalog/*`): never hand-edit. Regenerate them with the tools (`tools/gen_l10n.sh`, `dart run build_runner build`, `tools/build_catalog.sh`), including after a merge conflict.
- **Parallel windows** work in separate git worktrees (`ROOT/.worktrees/<name>`, see `docs/PLAN.md` → *Parallel windows*). Never run builds for two windows in the same checkout.

## Code rules

- **No hard-coded UI strings.** Add strings ONLY to your owner's fragment `app/lib/core/l10n/arb_src/<owner>/{ar,en}.arb` (keys prefixed with the owner name, e.g. `workoutStart`; Arabic carries the `@key` description), then run `tools/gen_l10n.sh`. **Never edit** `app/lib/core/l10n/arb/*.arb` or `gen/`: they are generated. Read strings with `context.l10n`.
- Exercise names: use `context.namesOf(exercise)` (`core/l10n/exercise_names.dart`) for the primary/secondary names.
- **No left/right.** Only `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`, `PositionedDirectional`, `BorderRadiusDirectional`. `tools/check_directionality.sh` must pass.
- **No new colours, sizes, radii, durations or text styles** outside `app/lib/core/theme/`. If you need one, add it to the theme and document it in `docs/DESIGN.md`.
- **Western digits (0–9)** in both languages; tabular figures.
- **Weights are kg internally**; convert only for display and input.
- **Every DB change for an active workout is persisted immediately.** No in-memory-only set state.
- User records use UUID v4 ids. Catalog tables are never written outside the catalog installer.
- **Drift watch queries read real tables.** Every `.watch()` / `watchSingle…()` / watched `customSelect` must select from the real tables it depends on, with a `readsFrom` listing exactly the tables in its SQL. **No dummy "tick" SQL** (`SELECT 1`, `SELECT 1 AS x`): Drift shares streams with identical SQL whatever their `readsFrom`, so one dummy query can silently stop another screen from updating. `test/core/db/watch_queries_audit_test.dart` enforces it.

## Before finishing

- Run `flutter analyze`, `flutter test` and `tools/check_directionality.sh` (through `env.sh`). All must pass.
- Run `tools/screenshots.sh <feature>` (both platforms), look at every image, and fix any difference between platforms or any RTL/LTR mirroring problem. Commit the screenshots.
- Add real-device-only checks to `docs/DEVICE_TEST_CHECKLIST.md`.
- Log every assumption in `docs/DECISIONS_LOG.md` (append, dated).
- Update your task's status in `docs/PLAN.md`.

## Git & licensing

- Commit locally with the repo-local identity. **Mac sessions: never push** unless the owner asks; **cloud sessions push to `main`** (see *Cloud / no devices*). Never rewrite published history.
- **Never touch the media licensing rules** in `docs/LICENSES.md`. **azm contains the unlicensed Gym visual media (`media/`, committed on 2026-09-28 by the owner's decision): never make azm public and never add a collaborator until the Gym visual licence is bought.** Every GitHub-touching script checks this and aborts (`tools/lib/github_guard.sh`); never work around it. Never copy `media/` to any other repo or upload it anywhere, never ship it except in the owner-only `personal` flavor (`tools/release_personal.sh`, released in azm only; tester/store builds never contain media), never feed it to AI image/animation generation, never commit screenshots that show media.
- **When the owner asks for a push:** go through `./gh_env git push …` (it runs the privacy guard + `tools/audit_history.sh`). History must never contain secrets, tokens, keystores, `.env` or `.tooling/`; media is allowed.
