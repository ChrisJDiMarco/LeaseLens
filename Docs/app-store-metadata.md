# LeaseLens App Store Metadata Draft

Prepared: 2026-05-26

## Product Page

**App name**: LeaseLens

**Subtitle**: NYC Apartment Red Flags

**Primary category**: Utilities

**Secondary category**: Lifestyle

**Age rating target**: 4+

**Keywords**: apartment,renter,lease,NYC,building,violations,complaints,HPD,housing,311

**Promotional text**:

Check an NYC building's public complaint and violation history before you sign a lease.

**Description**:

LeaseLens is a fast pre-lease check for New York City renters.

Enter an NYC apartment address to see public building-condition signals translated into plain English:

- Overall risk summary with an explainable score
- Recurring heat, hot water, pests, leaks, plumbing, security, and safety signals
- Open HPD violations
- Recent activity timeline
- Practical questions to ask a broker or landlord
- Visible links to the underlying public sources

LeaseLens uses NYC public data from HPD, NYC311, and NYC Planning GeoSearch. Complaints may be unconfirmed or no longer current, and a lack of records does not guarantee building conditions. LeaseLens is decision support for renters, not legal advice.

**What's New for 1.0**:

Introducing LeaseLens: search an NYC building and review public complaint signals, open violations, trends, and questions to ask before signing.

## App Review Notes

LeaseLens is fully functional without login or purchase.

Suggested review flow:

1. Launch the app.
2. Search `245 East 80 Street Manhattan` or choose an example address.
3. Select the address suggestion.
4. Review the live report, category cards, sources, and methodology/privacy screen.

The app reads public records directly over HTTPS from:

- `geosearch.planninglabs.nyc`
- `data.cityofnewyork.us` datasets `ygpa-z7cr`, `wvxf-dwi5`, and `erm2-nwe9`

No accounts, advertising, tracking, analytics SDKs, payments, or protected-device permissions are included in version 1.0. Public sources can occasionally be unavailable; the app explicitly labels incomplete coverage and permits retry.

## Privacy Nutrition Label Preparation

The app itself does not maintain accounts, analytics, advertising identifiers, or server-side search history. A searched address is transmitted from the device to NYC public-data services to service the user's request.

Before completing App Store Connect privacy answers, confirm the retention practices of the public endpoints. A conservative disclosure path is to declare address queries as user content used for app functionality, not linked to the user's identity and not used for tracking, if Apple determines the third-party processing constitutes collection.

## Required Screenshots

Capture after installing a release-candidate build:

1. Home search screen with value proposition.
2. Autocomplete suggestion for a typed address.
3. Report risk summary and top red flags.
4. Category/timeline or violations section.
5. Methodology and privacy screen.
