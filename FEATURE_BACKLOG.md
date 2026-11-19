# Feature and Idea Backlog

Use this file to capture proposed features, integrations, UX improvements, and technical work that is not yet approved for implementation.

## How agents should use this backlog

- Adding or editing an idea does not authorize implementation.
- When asked to implement a specific ID, work only on that item and follow `AGENTS.md` from requirements through verification and release readiness.
- When asked to start the next item, choose the highest-priority `Ready` item. If several have the same priority or important requirements are unclear, ask before choosing.
- Mark an item `In Progress` when implementation starts. Mark it `Done` only after relevant validation passes; include a short completion note. If blocked, record why and leave it `Blocked`.
- Do not silently change priorities, acceptance criteria, or scope. Update the entry when the user clarifies it.
- Consider Quranic text, translations, tafsir, page mapping, licensing, offline use, and privacy constraints before marking an item `Ready`.

**This is a manual backlog, not an automatic task queue.** An agent does not monitor file changes or start work just because an item is added. Ask the agent to refine an idea, implement an ID, or start the highest-priority ready item.

## Status and priority

- **Proposed**: captured, but not yet refined or approved.
- **Ready**: scope and acceptance criteria are clear enough to implement.
- **In Progress**: implementation is underway.
- **Blocked**: cannot proceed; the reason is recorded.
- **Done**: implementation and relevant verification are complete.

Priority: **P0** critical, **P1** high, **P2** normal, **P3** low.

## Platform-Fit Plan

This is the planning baseline for FEAT-001 through FEAT-018, based on the current repository. It is not approval to start implementation.

### Existing system constraints

- The Android app is Flutter. It currently opens the Wudu/adab gateway, then the Quran `IndexScreen`, whose tabs are Surah, Juz and bookmarks. There is no app-wide bottom-navigation shell.
- The PWA is a separate static HTML/JavaScript client. `scripts/generate_web_data.py` generates JSON consumed by the PWA, and its service worker supports offline use. Flutter widgets cannot be shared with it.
- The Quran text, translations and Tafsir already live in `data/quran_imdadia.db`. Guidance content should reference Quran records by Surah/Ayah and use existing read/display paths; it must not copy or edit Quran text.
- Flutter's `QuranDbHelper` currently replaces its local database with the bundled asset when the database version is behind. It also stores Quran bookmarks and last-read state there. Do not add persistent guidance data to that database until upgrades preserve existing user data.
- The app and PWA are Bengali-first today. Keep Arabic RTL rendering and the existing green/cream/gold visual language. Supporting English content can be staged; do not pretend both clients share a localization framework.

### Recommended architecture

- Keep editorial guidance as a versioned, offline JSON content source under a dedicated `data/life_guidance/` area. The precise file contract belongs to FEAT-002.
- Bundle the same validated content for Flutter and emit the PWA's static JSON from the existing web-data pipeline. Maintain separate UI implementations and platform-specific tests.
- Model categories, challenges, principles, reviewed explanations/actions, and Quran references as content records. Store references such as `surah_id` and `ayah_number`, never duplicated Arabic or translation text.
- Keep user-created state (saved guidance, history, journal) separate from the replaceable Quran content database. Android and PWA can use their existing local-only storage approaches; no account, cloud sync, analytics, or network dependency is in scope.
- Launch Life Guidance as a separate route reachable from the existing Quran index, rather than introducing a new bottom navigation shell or replacing the Wudu/adab gateway. Revisit global navigation only as a separate approved design decision.
- Treat the screenshot and modern-life examples as UI inspiration, not religious evidence. Clearly label Quran text, existing translation, Tafsir, scholar-reviewed explanation, and practical reflection as different content types.
- No guidance content is publishable until its sources and references are verified and it has the required scholarly review. Never invent Quranic quotations, Hadith, Tafsir, or rulings.

### Delivery phases

| Phase | Goal | Backlog items | Exit gate |
|---|---|---|---|
| 0 — Foundation | Agree on the shared content format, review metadata, import/build path, offline policy and user-data boundary. | FEAT-002, FEAT-014, FEAT-016, FEAT-018 | Content schema and update tests pass; existing Quran bookmarks and last-read state are preserved; review process and approved sources are identified. |
| 1 — Read-only guidance MVP | Deliver a small, reviewed category/challenge experience with Quran links and practical reflections. | FEAT-001, FEAT-003, FEAT-004, FEAT-006, FEAT-017, with FEAT-015 accessibility/language requirements | Start with a limited curated set; Android and PWA are separately tested; every religious statement/reference is reviewed; app remains offline. |
| 2 — Discovery and saved use | Add reusable principle browsing, local discovery, saved topics, daily reflections and optional history. | FEAT-005, FEAT-007, FEAT-008, FEAT-010, FEAT-011, FEAT-013 | Local state is migration-safe, deletable, private, and does not imply spiritual scoring. |
| 3 — Optional personal features | Consider journal and reminders only after privacy, permission and platform-specific designs are approved. | FEAT-009, FEAT-012 | Explicit user opt-in, clear local-data controls, and independently reviewed content; no cloud sync by default. |

Phase 1 should be Bengali-first. English UI/content and additional languages need a separately scoped localization phase. "Both" means a shared content source with separate Android and PWA implementations, not one shared UI.

Phase 0 execution order: **FEAT-016 → FEAT-002 → FEAT-014 → FEAT-018**. Later steps depend on decisions and safeguards from earlier steps.

## Detailed Backlog Items

### FEAT-001 — Life Guidance Navigation & Main Dashboard
- Status: Proposed
- Priority: P1
- Type: UX
- Request/problem: Users need a dedicated place to explore Quranic guidance for everyday life situations.
- Expected outcome: Introduce a separate Life Guidance route from the existing Quran index, with a focused dashboard for reviewed featured topics and categories.
- Platforms: Both
- Phase: 1 — Read-only guidance MVP
- Acceptance criteria:
  - [ ] Add a clearly labeled Life Guidance action from the existing Quran index (for example, an AppBar action) without replacing the Wudu/adab gateway or Quran tabs.
  - [ ] Build a dedicated landing page.
  - [ ] Load categories and featured topics from the shared offline content source.
  - [ ] Do not promise saved topics, history or daily reflections until their later-phase features exist.
  - [ ] Follow the existing Material 3 and green/cream/gold design conventions.
  - [ ] Preserve existing navigation and functionality.
- Dependencies or constraints: FEAT-002, FEAT-003, FEAT-014 and FEAT-017. Android and PWA require separate screens/routes.
- Quranic/data implications: No new Quran content. Reuse existing database records where needed.
- Notes: Do not introduce the screenshot's bottom navigation as an app-wide redesign in this phase.

### FEAT-002 — Life Guidance Content Architecture & Data Integration
- Status: Ready
- Priority: P1
- Type: Data
- Request/problem: Life challenges, categories, Quranic principles and practical guidance need a structured, expandable offline content system for two different clients.
- Expected outcome: Define a shared, versioned JSON content source for Flutter and the static PWA, with Quran references resolved against the existing SQLite database.
- Platforms: Both
- Phase: 0 — Foundation
- Acceptance criteria:
  - [ ] Define localized category, challenge, principle, explanation, action and source/reference records.
  - [ ] Represent Quran references by existing Surah/Ayah identifiers and validate that each resolves.
  - [ ] Define review states and prevent draft/unreviewed content from entering production bundles.
  - [ ] Bundle one validated content source for Flutter and generate static PWA JSON from it.
  - [ ] Keep read-only editorial content outside `quran_imdadia.db`.
  - [ ] Specify how future content versions are added without changing Quran records or user data.
  - [ ] Add schema/fixture validation tests before importing real religious content.
- Dependencies or constraints: Existing SQLite schema and `scripts/generate_web_data.py`; FEAT-016. FEAT-014 defines the review process after the content format is agreed.
- Quranic/data implications: Preserve existing Arabic, translation and Tafsir records. Never duplicate Quranic source material.
- Notes: The original SQLite-table approach is not recommended because the PWA consumes generated static JSON and the Flutter database currently replaces older local copies.

### FEAT-003 — Life Guidance Categories & Challenge Library
- Status: Proposed
- Priority: P1
- Type: Feature
- Request/problem: Users need to discover Quranic guidance according to the challenges and circumstances they experience.
- Expected outcome: Provide a searchable, categorized library of real-life challenges.
- Platforms: Both
- Phase: 1 — Read-only guidance MVP
- Acceptance criteria:
  - [ ] Load categories from the shared validated content source.
  - [ ] Support multiple challenges under each category.
  - [ ] Implement challenge listing pages.
  - [ ] Provide Bengali titles/descriptions for the first release and keep the schema ready for later English localization.
  - [ ] Support featured challenges and display ordering.
  - [ ] Include category descriptions and icons.
  - [ ] Expand categories/challenges through content updates without UI changes.
- Dependencies or constraints: FEAT-002, FEAT-014, FEAT-017 and FEAT-018.
- Quranic/data implications: Challenge descriptions must distinguish modern examples from direct Quranic statements.
- Notes: Initial categories are candidates, not fixed scope; begin with a small reviewed set. Candidates:
  - Hardships & Trials.
  - Emotional & Psychological Wellbeing.
  - Family & Relationships.
  - Work, Education & Success.
  - Wealth & Financial Life.
  - Society & Modern World.
  - Spiritual Growth & Personal Character.
  - Tests Through Blessings.

### FEAT-004 — Individual Challenge Detail & Quranic Perspective
- Status: Proposed
- Priority: P1
- Type: Feature
- Request/problem: Simply listing related verses does not adequately explain how Quranic teachings apply to real-life situations.
- Expected outcome: Provide a comprehensive detail page for each challenge, connecting the user's situation with Quranic guidance.
- Platforms: Both
- Phase: 1 — Read-only guidance MVP
- Acceptance criteria:
  - [ ] Display challenge title and introduction.
  - [ ] Explain common real-life circumstances using reviewed, attributed content.
  - [ ] Display related Quranic verses by loading text from the existing Quran data source.
  - [ ] Display the project's existing Bengali translation and Surah/Ayah reference.
  - [ ] Provide Surah and Ayah references.
  - [ ] Link to the existing Tafsir UI and Quran reader at the referenced verse/page.
  - [ ] Provide navigation to the original Quran reader.
  - [ ] Display contextual explanations only when review status and sources are present.
  - [ ] Support multiple related verses per challenge.
  - [ ] Include related challenges.
- Dependencies or constraints: FEAT-002, FEAT-003, FEAT-014 and FEAT-017.
- Quranic/data implications: All Quranic references must point to verified existing Ayah records. Do not hardcode Quranic text.
- Notes: Keep Quran, translation, Tafsir, scholar-reviewed explanation and modern practical reflection visibly distinct.

### FEAT-005 — Quranic Principles & Reusable Guidance Framework
- Status: Proposed
- Priority: P1
- Type: Data
- Request/problem: Many different life challenges are addressed through recurring Quranic principles, and these should not be independently duplicated for every topic.
- Expected outcome: Create a reusable collection of Quranic principles that can be connected to multiple challenges.
- Platforms: Both
- Phase: 2 — Discovery and saved use
- Acceptance criteria:
  - [ ] Create a structured principle library.
  - [ ] Support source-backed Bengali names initially; retain fields for Arabic/English terms only where verified and useful.
  - [ ] Provide reviewed descriptions and explanations with references.
  - [ ] Associate principles with multiple challenges.
  - [ ] Link principles to relevant Quranic verses.
  - [ ] Support practical applications.
  - [ ] Provide dedicated principle detail pages.
- Dependencies or constraints: FEAT-002, FEAT-004 and FEAT-014.
- Quranic/data implications: Verify every Quranic reference and distinguish established teachings from modern applications.
- Notes: Add principles only when supported by reviewed content. Candidates:
  - Sabr (Patience).
  - Shukr (Gratitude).
  - Tawakkul (Reliance upon Allah).
  - Dua (Supplication).
  - Salah (Prayer).
  - Tawbah (Repentance).
  - Taqwa (Consciousness of Allah).
  - Ihsan (Excellence).
  - Adl (Justice).
  - Rahmah (Mercy).
  - Sincerity.
  - Self-accountability.
  - Forgiveness.
  - Perseverance.
  - Charity.

### FEAT-006 — Practical Actions & Daily Application
- Status: Proposed
- Priority: P1
- Type: Feature
- Request/problem: Users need to translate their understanding of Quranic guidance into practical everyday behaviour.
- Expected outcome: Provide actionable recommendations associated with each life challenge.
- Platforms: Both
- Phase: 1 — Read-only guidance MVP
- Acceptance criteria:
  - [ ] Support multiple practical actions per challenge.
  - [ ] Display relevant actions in challenge detail pages.
  - [ ] Provide realistic, non-prescriptive recommendations with review/source metadata.
  - [ ] Provide Bengali content initially and allow English localization later.
  - [ ] Avoid presenting recommendations as guaranteed outcomes.
- Dependencies or constraints: FEAT-004, FEAT-014 and FEAT-017. Completion tracking is deferred to FEAT-013.
- Quranic/data implications: Recommendations must be consistent with verified Islamic teachings and should not be presented as direct Quranic quotations unless they are.
- Notes: Phase 1 actions are read-only. Candidates include dua, seeking knowledge, maintaining family ties, helping others and responsible practical steps.

### FEAT-007 — Daily Quranic Reflection
- Status: Proposed
- Priority: P2
- Type: Feature
- Request/problem: Users need a simple way to engage with Quranic guidance regularly, even when they do not actively search for a particular challenge.
- Expected outcome: Provide a daily reflection containing a Quranic verse, explanation and practical action.
- Platforms: Both
- Phase: 2 — Discovery and saved use
- Acceptance criteria:
  - [ ] Display a daily Quranic reflection.
  - [ ] Include an existing Quranic Ayah reference.
  - [ ] Display the existing Arabic text and translation.
  - [ ] Include a short contextual explanation.
  - [ ] Include one practical daily action.
  - [ ] Link the reflection to its associated challenge.
  - [ ] Work completely offline.
  - [ ] Maintain a consistent daily selection.
- Dependencies or constraints: FEAT-002, FEAT-004, FEAT-014 and FEAT-017.
- Quranic/data implications: All referenced verses and explanations require verification.
- Notes: Use a deterministic local rotation. No remote daily content service or notification is required.

### FEAT-008 — Bookmarking & Saved Guidance
- Status: Proposed
- Priority: P2
- Type: Feature
- Request/problem: Users need to preserve useful guidance and revisit it later.
- Expected outcome: Provide bookmarking for challenges, principles, Quranic references and reflections.
- Platforms: Both
- Phase: 2 — Discovery and saved use
- Acceptance criteria:
  - [ ] Bookmark and unbookmark challenges.
  - [ ] Bookmark principles.
  - [ ] Bookmark relevant Quranic references where supported.
  - [ ] Bookmark daily reflections.
  - [ ] Display saved items in one dedicated section.
  - [ ] Persist bookmarks locally.
  - [ ] Prevent duplicate bookmarks.
- Dependencies or constraints: FEAT-002 and FEAT-016. Android and PWA persistence are separate implementations.
- Quranic/data implications: Do not alter the existing page-based Quran bookmarks. Saved guidance should have its own local records and may link to Quran Ayah IDs.
- Notes: Do not overload the page-number-only Quran bookmark table. Keep new saved guidance local and migration-safe.

### FEAT-009 — Personal Reflection Journal
- Status: Proposed
- Priority: P2
- Type: Feature
- Request/problem: Users need a private place to record personal reflections and lessons learned from Quranic guidance.
- Expected outcome: Introduce an offline personal reflection journal connected to challenges and Quranic references.
- Platforms: Both
- Phase: 3 — Optional personal features
- Acceptance criteria:
  - [ ] Create personal reflection entries.
  - [ ] Associate entries with challenges.
  - [ ] Optionally associate entries with Quranic verses.
  - [ ] Edit and delete entries.
  - [ ] Display reflection history.
  - [ ] Store entries locally.
  - [ ] Include appropriate privacy considerations.
- Dependencies or constraints: FEAT-002, FEAT-004 and FEAT-016. Requires an explicit privacy/storage design before implementation.
- Quranic/data implications: User-generated reflections must remain distinguishable from Quranic text and scholarly Tafsir.
- Notes: Journals are private user content, not published religious interpretations.

### FEAT-010 — Life Guidance Search & Discovery
- Status: Proposed
- Priority: P2
- Type: Feature
- Request/problem: Users need to find relevant guidance without manually browsing every category.
- Expected outcome: Implement search and filtering across the Life Guidance library.
- Platforms: Both
- Phase: 2 — Discovery and saved use
- Acceptance criteria:
  - [ ] Search challenge titles and descriptions.
  - [ ] Search category names.
  - [ ] Search Quranic principles.
  - [ ] Support Bengali search initially; add English search with the later localization phase.
  - [ ] Support relevant tags and alternative keywords.
  - [ ] Provide category filters.
  - [ ] Display useful empty states.
  - [ ] Work offline.
- Dependencies or constraints: FEAT-002, FEAT-003 and FEAT-018.
- Quranic/data implications: Search results must link to verified content and existing Quran records.
- Notes: Start with simple local search for the small initial collection. Add FTS only if measured scale/performance requires it.

### FEAT-011 — Related Guidance & Topic Recommendations
- Status: Proposed
- Priority: P3
- Type: Feature
- Request/problem: Individual challenges are interconnected, but users currently have no structured way to discover related Quranic guidance.
- Expected outcome: Provide content-driven relationships between challenges, principles and Quranic references.
- Platforms: Both
- Phase: 2 — Discovery and saved use
- Acceptance criteria:
  - [ ] Associate related challenges.
  - [ ] Associate related principles.
  - [ ] Display related guidance on detail pages.
  - [ ] Support manually curated relationships.
  - [ ] Prevent circular or irrelevant recommendation loops.
  - [ ] Allow future expansion of the relationship system.
- Dependencies or constraints: FEAT-002, FEAT-003, FEAT-005 and FEAT-014.
- Quranic/data implications: Relationships are navigational recommendations, not claims that the Quran explicitly establishes every suggested connection.
- Notes: Example: Financial hardship → Patience → Tawakkul → Gratitude → Charity.

### FEAT-012 — Local Notifications & Guidance Reminders
- Status: Proposed
- Priority: P3
- Type: Integration
- Request/problem: Users may want to receive reminders to revisit saved guidance and daily reflections.
- Expected outcome: Integrate optional Life Guidance reminders into the existing local notification system.
- Platforms: Both
- Phase: 3 — Optional personal features
- Acceptance criteria:
  - [ ] Allow users to enable or disable reminders.
  - [ ] Support configurable reminder times.
  - [ ] Support daily reflection reminders.
  - [ ] Support selected topic reminders.
  - [ ] Respect notification permissions.
  - [ ] Persist reminder preferences locally.
  - [ ] Avoid duplicate scheduled notifications.
- Dependencies or constraints: FEAT-007. The current Flutter dependencies do not include a notification package, and PWA notifications are a separate browser capability.
- Quranic/data implications: Reminder content must use verified references.
- Notes: The current Flutter app has no notification package or scheduler. Treat notifications as a new, optional Android integration and evaluate browser/PWA support and permission limits separately.

### FEAT-013 — Life Guidance Reading & Activity Progress
- Status: Proposed
- Priority: P3
- Type: Feature
- Request/problem: Users need a way to revisit recently explored guidance and optionally track their learning activity.
- Expected outcome: Maintain local browsing history and optional topic completion tracking.
- Platforms: Both
- Phase: 2 — Discovery and saved use
- Acceptance criteria:
  - [ ] Track recently viewed challenges.
  - [ ] Display recently viewed topics.
  - [ ] Allow users to mark topics as completed.
  - [ ] Allow users to revisit previous topics.
  - [ ] Provide a clear history management option.
  - [ ] Persist activity locally.
- Dependencies or constraints: FEAT-002, FEAT-004 and FEAT-016.
- Quranic/data implications: Reading progress must not be interpreted as a measure of faith, piety or spiritual success.
- Notes: Keep progress tracking optional.

### FEAT-014 — Islamic Content Verification & Reference Management
- Status: Ready
- Priority: P1
- Type: Data
- Request/problem: Incorrect Quranic references, unsupported interpretations and fabricated Hadith could undermine the reliability of the entire feature.
- Expected outcome: Establish a verifiable content schema and release gate for all Life Guidance material.
- Platforms: Tooling
- Phase: 0 — Foundation
- Acceptance criteria:
  - [ ] Verify all Quranic Ayah references against the existing database.
  - [ ] Resolve Quran Arabic/translation from the existing source; do not copy it into guidance records.
  - [ ] Identify the translation source.
  - [ ] Record Tafsir source and scholar attribution.
  - [ ] Record Hadith references and authenticity grading where relevant.
  - [ ] Distinguish Quranic text, Tafsir, scholarly explanations and modern applications.
  - [ ] Maintain content verification status.
  - [ ] Document unresolved scholarly or interpretive questions.
  - [ ] Prevent unverified content from being presented as established Islamic teaching.
- Dependencies or constraints: FEAT-002. A qualified reviewer and approved source list must be identified before publishing actual guidance content.
- Quranic/data implications: High priority. All religious content requires appropriate verification before publication.
- Notes: Use draft, reviewed and published states in the shared content source. Technical review-state support is ready to design; content publication remains gated on a named reviewer.

### FEAT-015 — Life Guidance Localization & Accessibility
- Status: Proposed
- Priority: P2
- Type: UX
- Request/problem: Users need to understand Quranic guidance comfortably in their preferred language and across supported devices.
- Expected outcome: Ensure consistent Bengali and English localization, readable Arabic content and accessible navigation.
- Platforms: Both
- Phase: 1 — Cross-cutting MVP requirements
- Acceptance criteria:
  - [ ] Make Bengali the initial UI/content language, matching the existing app and PWA.
  - [ ] Keep content fields extensible for a later English localization phase.
  - [ ] Ensure correct Arabic text rendering.
  - [ ] Support RTL Arabic text presentation.
  - [ ] Maintain appropriate typography and text hierarchy.
  - [ ] Support different screen sizes.
  - [ ] Support screen readers, scalable text, contrast and semantic controls.
  - [ ] Preserve consistency with existing app themes.
- Dependencies or constraints: Reuse the existing themes/fonts; neither client currently has a shared localization framework.
- Quranic/data implications: Arabic Quranic text must remain unchanged across language and layout configurations.
- Notes: Flutter and the static HTML/JavaScript PWA have separate UI/localization implementations. Avoid relying exclusively on images to present Quranic text.

### FEAT-016 — Life Guidance Offline Reliability & Data Integrity
- Status: Ready
- Priority: P0
- Type: Maintenance
- Request/problem: The feature must remain reliable in a completely offline Quran application and must not affect existing Quran functionality.
- Expected outcome: Ensure shared-content integrity, safe local user-data persistence and compatibility with existing Quran features.
- Platforms: Both
- Phase: 0 — Foundation
- Acceptance criteria:
  - [ ] Verify all features work without internet connectivity.
  - [ ] Define a user-data migration strategy before adding persistent guidance state.
  - [ ] Verify app upgrades preserve existing Quran bookmarks and last-read state.
  - [ ] Test foreign-key relationships.
  - [ ] Test missing or invalid content references.
  - [ ] Test bookmark and journal persistence.
  - [ ] Test search performance.
  - [ ] Test larger content datasets.
  - [ ] Verify existing Quran reading, search, Tafsir, bookmark and last-read behavior.
  - [ ] Document local-only storage, data deletion and backup/restore behavior for new user data.
- Dependencies or constraints: Existing `QuranDbHelper` database replacement/version behavior; this is a prerequisite for adding persistent guidance state.
- Quranic/data implications: Prevent orphaned or mismatched Quranic references. Existing Quran data must not be modified by Life Guidance operations.
- Notes: `QuranDbHelper` replaces an older local database with the bundled asset instead of migrating its user tables. A future database-version bump can therefore erase Quran bookmarks/last-read state. Fix or isolate user state and add upgrade tests before enabling persistent guidance features.

### FEAT-017 — Initial Life Guidance Content Collection
- Status: Blocked
- Priority: P1
- Type: Data
- Request/problem: The application needs a verified initial content collection before the Life Guidance interface becomes useful.
- Expected outcome: Publish a small, carefully researched Bengali-first content pilot only after source and scholarly review.
- Platforms: Tooling
- Phase: 1 — Read-only guidance MVP
- Acceptance criteria:
  - [ ] Identify approved source materials and a qualified reviewer before drafting publishable content.
  - [ ] Prepare a small pilot collection and expand only after the review process is proven.
  - [ ] Cover multiple categories of human experiences.
  - [ ] Include relevant Quranic references for each challenge.
  - [ ] Resolve Quran text, translations and Tafsir from existing Quran records.
  - [ ] Provide attributed contextual explanations, principles and practical actions.
  - [ ] Include related guidance where appropriate.
  - [ ] Verify every reference and approve every explanatory/action statement before publication.
  - [ ] Provide Bengali content; add English after localization is scoped.
- Dependencies or constraints: Blocked until a qualified reviewer and approved sources are identified. Also depends on FEAT-002, FEAT-014 and FEAT-018.
- Quranic/data implications: Content must be researched using Quranic Arabic, contextual verse analysis, classical Tafsir and authentic Hadith where relevant.
- Notes: Surah Al-Baqarah 2:155–157 is a candidate research topic, not approved feature copy or a binding interpretation.

### FEAT-018 — Life Guidance Content Import, Update & Maintenance
- Status: Ready
- Priority: P2
- Type: Data
- Request/problem: Future content expansion should not require manual database editing or application code modifications.
- Expected outcome: Establish a deterministic validation/build pipeline from the shared editorial content source to Flutter assets and PWA JSON.
- Platforms: Tooling
- Phase: 0 — Foundation
- Acceptance criteria:
  - [ ] Define a structured content import format.
  - [ ] Validate required fields before importing.
  - [ ] Validate Quranic reference identifiers.
  - [ ] Detect duplicate records.
  - [ ] Reject draft or unreviewed content from production output.
  - [ ] Build repeatable Flutter/PWA content outputs without modifying `quran_imdadia.db`.
  - [ ] Preserve user data when content updates are installed.
  - [ ] Support content versioning and stable identifiers.
  - [ ] Document the content publishing workflow.
- Dependencies or constraints: FEAT-002, FEAT-014 and FEAT-016.
- Quranic/data implications: Imported Quranic references must resolve to existing verified Ayah records.
- Notes: Prefer structured JSON aligned with the PWA's existing static JSON generation. Keep the Quran database as the source for Quran text/translation/Tafsir.

## Proposed

- FEAT-001 — Life Guidance Navigation & Main Dashboard (Phase 1)
- FEAT-003 — Life Guidance Categories & Challenge Library (Phase 1)
- FEAT-004 — Individual Challenge Detail & Quranic Perspective (Phase 1)
- FEAT-005 — Quranic Principles & Reusable Guidance Framework (Phase 2)
- FEAT-006 — Practical Actions & Daily Application (Phase 1; reviewed content only)
- FEAT-007 — Daily Quranic Reflection (Phase 2)
- FEAT-008 — Bookmarking & Saved Guidance (Phase 2)
- FEAT-009 — Personal Reflection Journal (Phase 3)
- FEAT-010 — Life Guidance Search & Discovery (Phase 2)
- FEAT-011 — Related Guidance & Topic Recommendations (Phase 2)
- FEAT-012 — Local Notifications & Guidance Reminders (Phase 3)
- FEAT-013 — Life Guidance Reading & Activity Progress (Phase 2)
- FEAT-015 — Life Guidance Localization & Accessibility (cross-cutting)

## Ready

- FEAT-016 — Life Guidance Offline Reliability & Data Integrity (Phase 0, first)
- FEAT-002 — Life Guidance Content Architecture (Phase 0, after FEAT-016)
- FEAT-014 — Islamic Content Verification & Reference Management (Phase 0, after FEAT-002; technical workflow only)
- FEAT-018 — Life Guidance Content Import, Update & Maintenance (Phase 0, after FEAT-002 and FEAT-014)

## In Progress

- FEAT-016 — Life Guidance Offline Reliability & Data Integrity
  - Preserving Flutter Android bookmarks and last-read state across bundled Quran database upgrades.

## Blocked

- FEAT-017 — Initial Life Guidance Content Collection: needs an identified qualified reviewer and approved source materials before religious content can be drafted for publication.

## Done

None.

## Entry template

```markdown
### FEAT-XXX — Short descriptive title
- Status: Proposed
- Priority: P2
- Type: Feature | Integration | UX | Data | Maintenance
- Request/problem:
- Expected outcome:
- Platforms: Android | Web/PWA | Both | Tooling
- Phase: Phase number and goal
- Acceptance criteria:
  - [ ]
- Dependencies or constraints:
- Quranic/data implications: None | Describe review or verification needed
- Notes:
```
