# Build Log: LeaseLens Native MVP

Started: 2026-05-26
Target: Native iPhone app in SwiftUI
Workspace: `~/jarvis/projects/LeaseLens/`

## Completed

- Created a standalone Xcode project with a SwiftUI mobile-first design system.
- Integrated NYC Planning GeoSearch for autocomplete and normalized addresses with BBL/BIN.
- Integrated live HPD complaints/problems, HPD open violations, and non-HPD NYC311 requests.
- Added exact-building versus nearby-only result labeling and public-record disclaimers.
- Implemented explainable risk scoring, category recurrence/trends, timeline, questions, and source record links.
- Added focused unit tests for empty results, high-risk recurrence, and generic-category headline handling.

## QA

- `xcodebuild -project LeaseLens.xcodeproj -scheme LeaseLens -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.5' -derivedDataPath DerivedData test -quiet` passed on 2026-05-26.
- Live typed-address flow verified in Simulator with `245 East 80 Street Manhattan`.
- Live report visually verified with real HPD and NYC311 records.

## Implementation Notes

- HPD complaint matching prefers BIN because live validation showed it responds much faster than an equivalent BBL filter on this dataset.
- The app is intentionally read-only and credential-free for MVP; a caching proxy is deferred until API limits or saved reports justify infrastructure.
- No commit or deployment was performed because this session was focused on a local runnable prototype.

## 2026-05-26 Production Hardening Pass

- Added an opaque, original App Store icon and bundled privacy manifest.
- Removed beta-facing UI language and changed the category to Utilities.
- Added an in-app methodology/privacy screen and explicit incomplete-data disclosure.
- Made HPD/NYC311 retrieval tolerant of individual source outages with cached HTTPS sessions, report refresh, and stale-report disclosure if a refresh fails.
- Added App Store metadata, privacy policy draft, and release checklist documents.
- Confirmed a future upload blocker: Apple requires the iOS 26 SDK for uploads beginning April 28, 2026, while the local installed toolchain is Xcode 16.4/iOS 18.5.
