# LeaseLens for iPhone

LeaseLens is a native SwiftUI MVP for checking an NYC apartment building before signing a lease. It turns public complaint and violation records into a concise renter-facing risk summary, recurring issues, and practical broker questions.

## MVP

- Search and normalize NYC addresses through NYC Planning GeoSearch.
- Pull exact-building HPD complaints and open HPD violations.
- Pull NYC311 records at the address, with a clearly labeled nearby-record fallback.
- Explain an overall risk level with category breakdowns, timeline, and source links.
- Show partial-coverage warnings and retry controls if a public source is temporarily unavailable.
- Keep conclusions cautious: public records are signals, not proof of current conditions.

## Data Sources

- [NYC Planning GeoSearch](https://geosearch.planninglabs.nyc/)
- [HPD Housing Maintenance Code Complaints and Problems](https://data.cityofnewyork.us/Housing-Development/Housing-Maintenance-Code-Complaints-and-Problems/ygpa-z7cr/about_data)
- [HPD Housing Maintenance Code Violations](https://data.cityofnewyork.us/Housing-Development/Housing-Maintenance-Code-Violations/wvxf-dwi5/about_data)
- [NYC311 Service Requests](https://data.cityofnewyork.us/Social-Services/311-Service-Requests-from-2010-to-Present/erm2-nwe9/about_data)

## Run

Open `LeaseLens.xcodeproj` in Xcode and run the `LeaseLens` scheme on an iPhone simulator. The app makes read-only HTTPS requests directly to public NYC endpoints; no credentials or server are required for this prototype.

## Release Preparation

See [Docs/release-checklist.md](Docs/release-checklist.md), [Docs/app-store-metadata.md](Docs/app-store-metadata.md), and [Docs/privacy-policy-draft.md](Docs/privacy-policy-draft.md). A final App Store upload requires Xcode 26 or later under Apple's April 28, 2026 SDK requirement, a signing team, and published privacy/support URLs.
