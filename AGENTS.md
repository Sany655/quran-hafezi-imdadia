# Agent SDLC Guide

This file defines the required software-development lifecycle for AI coding agents working in this repository.

## Project Purpose

Al-Quran Hafezi Imdadia is a non-commercial, offline-first Quran reader and an act of Sadaqah Jariyah. Protect the accuracy and dignity of Quranic text, translations, tafsir, and Mushaf page mapping above convenience or visual polish.

## Source of Truth

- Read [README.md](README.md) for project setup and public behavior.
- Check [FEATURE_BACKLOG.md](FEATURE_BACKLOG.md) for captured ideas when the user asks for backlog work.
- Read [DATASET_AUTHENTICITY_AND_LEGALITY.md](DATASET_AUTHENTICITY_AND_LEGALITY.md) before changing Quranic datasets, translations, tafsir, recitation, or scholarly content.
- Follow existing project patterns in `lib/`, `scripts/`, `test/`, and `.github/workflows/`.
- Treat `data/quran_imdadia.db`, `assets/pages/`, `assets/audio/`, and generated `docs/` or `landing/` data as sensitive content: never overwrite, truncate, regenerate, or normalize them casually.

## Before Starting Work

1. Restate the requested behavior and identify affected platforms: Flutter Android, PWA/web, or both.
2. Inspect current Git status. Do not revert or overwrite unrelated user changes.
3. Locate existing implementation, tests, workflows, and documentation before adding new code.
4. Check the scope of data dependencies, especially SQLite tables and page/ayah mappings.
5. Ask for clarification before making a decision that would alter:
   - Quranic Arabic text or Mushaf page boundaries
   - translation or tafsir meaning
   - app-wide navigation or release/version policy
   - storage format or user data migration
   - non-commercial, ad-free, or tracking-free requirements

## Feature and Idea Intake

- Use [FEATURE_BACKLOG.md](FEATURE_BACKLOG.md) to record ideas that are not yet approved for implementation.
- If asked only to capture an idea, add it as `Proposed`; do not start implementation.
- If asked to refine an idea, define user outcome, platform, dependencies, data implications, and testable acceptance criteria. Move it to `Ready` only when scope is clear and the user has approved it.
- If asked to implement a backlog item, implement only the requested ID and follow the SDLC below. Mark it `In Progress` before work and `Done` only after validation; record blockers explicitly.
- If asked to choose the next item, select the highest-priority `Ready` item. Ask if priority is tied or the requirements need a decision.
- Do not treat file changes as an execution trigger: agents do not watch the backlog or autonomously start queued work.

## SDLC Workflow

### 1. Requirements and Acceptance Criteria

- Define a concise outcome and measurable acceptance criteria.
- Separate explicit requirements from assumptions.
- Identify edge cases, offline behavior, RTL layout, missing database records, and low-memory devices.
- Record any scholarly or data-verification requirement before implementation.

### 2. Design and Review

- Prefer the smallest design that fits existing architecture.
- Keep UI state, database access, data transformation, and platform integration in their existing layers.
- Reuse existing models, services, utilities, and widgets before creating abstractions.
- Avoid broad refactors, unrelated formatting, and dependency changes.
- Document public behavior changes in [README.md](README.md) only when they affect setup or user-visible capabilities.

### 3. Implementation

- Use Dart/Flutter conventions and `flutter_lints`.
- Preserve null safety and type safety; do not use `as any`, dynamic escape hatches, or unverified casts.
- Keep user-facing strings accessible and RTL/LTR-safe.
- Preserve offline behavior and avoid network calls as hidden dependencies.
- Do not add analytics, ads, tracking, or monetization.
- Do not introduce credentials or secrets into source files.
- Never modify Quranic text to make a test pass. Correct the source/mapping pipeline first.

### 4. Testing and Verification

For a Dart or Flutter change, run the smallest relevant test first:

```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

For Android-specific or release-impacting changes, also consider:

```powershell
flutter build apk --debug
flutter build apk --release
```

For PWA/web changes, verify generated data and the local web bundle:

```powershell
python scripts/generate_web_data.py
```

Then verify the relevant files and behavior locally. Database or page-mapping changes require targeted integrity checks rather than only unit tests.

Minimum test expectations:

- Add or update a focused test for behavior that was introduced or fixed.
- Test failure, empty, missing, malformed, and boundary conditions where relevant.
- Add Quranic data tests for verse counts, page/ayah boundaries, surah/juz/page consistency, or text fidelity when the data pipeline changes.
- Do not weaken or remove existing tests to make a change pass.

### 5. Review

Before completion, inspect the diff and confirm:

- No unrelated files or generated artifacts changed.
- No secrets, keystores, personal data, or signing files remain.
- Existing behavior is preserved unless the request requires a change.
- Database assets and LFS pointers are intact.
- Web output and Android output are consistent with the source changes.
- A clear verification report is included in the final response.

For a Quranic content or data change, the final summary must identify exactly what source was changed and what independent verification was performed.

## Beta and Release Cycle

### Branch and Pull Request

- Use a focused feature or fix branch.
- Open a pull request to `main` or `master`.
- PRs must pass `flutter analyze --no-fatal-infos`, `flutter test`, and relevant builds.
- Keep generated web and Android artifacts out of source changes unless the repository workflow explicitly requires it.

### Beta Candidate

Every beta candidate must be:

1. Merged or cherry-picked into a dedicated release candidate commit.
2. Verified with `flutter analyze --no-fatal-infos` and `flutter test`.
3. Built as a release or test APK.
4. Assigned a prerelease version/tag using `vMAJOR.MINOR.PATCH-beta.N`, for example `v3.4.0-beta.1`.
5. Published as a GitHub prerelease, not as a stable or latest release.
6. Limited to a defined tester group until Quranic data, navigation, storage migrations, and offline use pass testing.

For Android, beta APKs must preserve checksums and release metadata. Beta signing secrets are scoped to the `android-beta` GitHub environment; configure that environment with required reviewers and its signing secrets before using the workflow. Signing with the stable key allows upgrade testing, so release access must be tightly controlled.

Beta acceptance requires at least:

- No change to Quranic text, Mushaf page boundaries, translation meaning, or tafsir meaning unless independently reviewed and approved.
- APK install, startup, offline use, search, navigation, bookmarking, and page-turn behavior verified.
- A clean upgrade test from the previous stable version, or a documented migration limitation.
- No ads, trackers, exposed credentials, or unintended data collection.
- Updated release notes describing features, fixes, known issues, and data changes.

### Stable Release

Stable release is allowed only after beta acceptance and all CI gates pass.

- Release versions use `vMAJOR.MINOR.PATCH`.
- Update `version` in [pubspec.yaml](pubspec.yaml) consistently.
- Create the Git tag and stable GitHub Release.
- Configure the `android-production` GitHub environment with required reviewers and Android signing secrets.
- Mark the release as stable (`prerelease: false`) and do not publish beta artifacts as stable.
- Verify the downloaded APK checksum and basic install/startup behavior.
- Update public documentation for setup or user-visible behavior changes.

For web/PWA changes, beta behavior should use a separate test deployment or documented testing build; do not expose an unverified beta as the public `main`/stable GitHub Pages deployment. Existing public deployments remain on `main`/`master`.

## CI/CD Gates

- Refer to [CI_CD_SETUP.md](CI_CD_SETUP.md) for GitHub Actions secret, environment, and branch-protection setup.
- `.github/workflows/android_test_build.yml` is the Android pull-request/push test gate: LFS database verification, analysis, tests, and test APK build.
- `.github/workflows/web_validation.yml` validates PWA and web bundles without publishing: required files, JSON parsing, database LFS state, and 612 Mushaf assets.
- `.github/workflows/beta_android.yml` builds and publishes Android beta tags as GitHub prereleases. Beta tags must match `vMAJOR.MINOR.PATCH-beta.N`.
- `.github/workflows/deploy_web.yml` validates the generated bundle before deploying to GitHub Pages.
- `.github/workflows/release_android.yml` is reserved for stable Android releases. Beta tags are excluded and must not set `prerelease: false`.
- `.github/workflows/ocr_tafsir_pipeline.yml` must open a review PR for generated data; never bypass human review by pushing OCR output directly to `main`.
- Configure the `android-beta` and `android-production` GitHub environments with required reviewers and environment-scoped signing secrets.
- Configure a fine-grained `TAFSIR_PR_TOKEN` secret with repository contents and pull-request write access so OCR PRs trigger normal CI checks.
- Branch protection must require relevant CI checks before merge or release. Do not mark a failing check as successful manually.
- Configure required status checks in repository settings; YAML cannot enable these repository-level protections.

## Data and Asset Pipeline

- Verify Git LFS assets before and after data work.
- Never commit a placeholder, pointer, partial database, or zero-byte asset.
- Preserve page image dimensions and page sequence.
- Preserve 612-page Mushaf numbering and Ayah-ended page conventions.
- Verify all 6,236 Ayahs and all active mapping tables after bulk import or OCR changes.
- Prefer adding a verification script or test alongside data-pipeline changes.
- Never delete source PDFs, scans, or reference files merely to reduce repository size.

## Git and Commits

- Do not commit unless the user explicitly asks for a commit.
- Do not use destructive commands such as `git reset --hard` or `git checkout --`.
- Keep commits atomic and do not mix unrelated fixes.
- Include concise commit subjects such as `fix: preserve offline bookmark data`.
- When a commit is requested, add the required Copilot co-author trailer.
- Do not amend existing commits unless the user explicitly requests it.

## Completion Standard

A task is complete only when:

1. The implementation matches the acceptance criteria.
2. Relevant tests and builds pass, or failures are explicit and investigated.
3. The diff is scoped and persistent.
4. The final response identifies changed files, validation commands, beta/release impact, and remaining risks.
