# Rules for every agent working in Azm

This repo's root **is** the project root (`env.sh`, `docs/`, `app/`, … all live here). Paths in `docs/ORIGINAL_BRIEF.md` that start with `azm/` map to the root (`azm/X` → `X`).

## Sandbox (highest priority)

- **Never read, write, install or download outside the project root.** That includes `~`, `/tmp`, `/usr/local`, `/opt`, Homebrew, global npm/pip/gem and global git config. `~/dev` holds an older, unrelated toolchain: never use it.
- **Every shell command starts with `source ./env.sh &&`** (run from the root). All SDKs, caches and temp files live in `.tooling/`. Check `which flutter` points inside the root before Flutter commands.
- iOS code signing (physical iPhone, `flutter build ios/ipa`, signed `xcodebuild`) → use `./ios_env <command>` instead. Pass `-derivedDataPath .tooling/xcode-derived` to any direct `xcodebuild`.
- Anything that needs a global install (brew, sudo, global gem/npm) → **stop and ask the owner.**
- Never modify shell profiles, global git config or system settings. Never run `git config --global`.

## Before any task

Read `docs/SPEC.md`, `docs/DESIGN.md`, `docs/ARCHITECTURE.md` (and `docs/DATA.md` for data work). Then find your task in `docs/PLAN.md`.

## Scope

- Only touch files inside the paths **your task owns** (see `docs/PLAN.md`). Coordinate through the *Requests* section of `docs/PLAN.md`.
- Shared files (`app/pubspec.yaml`, `app/lib/app.dart`, router, ARB files) get minimal, prefixed, additive edits.

## Code rules

- **No hard-coded UI strings.** Everything goes through gen-l10n ARB (`app_ar.arb` + `app_en.arb`, always both).
- **No left/right.** Only `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`, `PositionedDirectional`, `BorderRadiusDirectional`. `tools/check_directionality.sh` must pass.
- **No new colours, sizes, radii, durations or text styles** outside `app/lib/core/theme/`. If you need one, add it to the theme and document it in `docs/DESIGN.md`.
- **Western digits (0–9)** in both languages; tabular figures.
- **Weights are kg internally**; convert only for display and input.
- **Every DB change for an active workout is persisted immediately.** No in-memory-only set state.
- User records use UUID v4 ids. Catalog tables are never written outside the catalog installer.

## Before finishing

- Run `flutter analyze`, `flutter test` and `tools/check_directionality.sh` (through `env.sh`). All must pass.
- Log every assumption in `docs/DECISIONS_LOG.md` (append, dated).
- Update your task's status in `docs/PLAN.md`.

## Git & licensing

- Commit locally with the repo-local identity. **Never push.** Never rewrite published history.
- **Never touch the media licensing rules** in `docs/LICENSES.md`. `media/` is dev-only and gitignored: never commit it, upload it, ship it, or feed it to AI image/animation generation.
