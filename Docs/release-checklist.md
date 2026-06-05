# LeaseLens iOS Release Checklist

Last updated: 2026-05-26

## Completed in Code

- Native SwiftUI app with no login, payments, analytics, ads, or protected-device permissions.
- Original 1024x1024 opaque App Store icon in the asset catalog.
- `PrivacyInfo.xcprivacy` bundled with no declared tracking, collection, or required-reason API use in the current app code.
- In-app methodology, privacy explanation, sources, disclaimers, and incomplete-source warning.
- Public-data lookup fails gracefully per source rather than discarding a partially useful report, and a failed refresh labels retained prior data.
- Unit tests cover scoring, no-data language, category prioritization, and incomplete-source disclosure.
- Version `1.0` / build `1` and iPhone-only device family configured.

## Blocking Before Upload

- Install Xcode 26 or newer. Apple states that, starting April 28, 2026, iOS apps uploaded to App Store Connect must be built with the iOS 26 SDK or later. This Mac currently has Xcode 16.4 with the iOS 18.5 SDK.
- Join or use an active Apple Developer Program team and set the app's signing team, distribution certificate, and provisioning profile.
- Register/finalize the bundle identifier. Current development identifier: `com.chrisdimarco.LeaseLens`.
- Publish the final privacy policy at a public HTTPS URL and add the URL in App Store Connect and in the app.
- Publish a support URL and provide a monitored support email.

## Release Candidate Pass

- Build and archive with the current required Xcode/iOS SDK.
- Run on at least one physical iPhone and on current small and large simulator sizes.
- Test VoiceOver and larger accessibility text through the full search/report flow.
- Test loss of connectivity and partial public-source availability.
- Confirm all sources still return expected fields and report wording remains accurate.
- Capture App Store screenshots from the release candidate.
- Complete the privacy label based on final public-service processing and any newly introduced SDKs.
- Supply review notes using `Docs/app-store-metadata.md`.
- Upload to TestFlight and conduct an external beta before App Review submission.

## Current Product Boundary

Version 1.0 reads NYC Planning GeoSearch, HPD complaints/problems, HPD open violations, and NYC311 data. DOB records, saved searches, alerts, account data, and payments are intentionally out of scope and must not be claimed in metadata.
