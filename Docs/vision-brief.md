# Vision Brief: LeaseLens

**Tagline**: Check the building before you sign the lease.

**Problem**: NYC renters make fast apartment decisions while useful building-condition records are scattered across public systems.

**Target user**: A renter evaluating a specific NYC apartment listing before applying or signing.

**Core loop**: Enter an address, scan renter-facing red flags, and leave with questions to ask the broker.

**Platform target**: Native iOS (SwiftUI).

## MVP Features

1. NYC address search with normalized address and building identifiers when available.
2. Live HPD complaint and open-violation lookup plus NYC311 address records.
3. Explainable Low, Medium, High, or Not enough data risk summary.
4. Category trends, recent timeline, and broker/landlord questions.
5. Visible sources, raw-record links, and a plain-language data disclaimer.

## Explicitly Deferred

- Accounts, payments, saved reports, alerts, comparison, map UI, landlord profiles, legal guidance, and nationwide data.

## Technical Decision

This build intentionally diverges from a web-first stack because the operator requested an iPhone-native working prototype. SwiftUI calls read-only public APIs directly for a fast, no-infrastructure MVP. A server-side cache/proxy can follow if usage, throttling, or stored searches justify it.

## Validation Note

The useful wedge is sharp: paste an address and understand public warning signals in under a minute. This build validates the product interaction and data interpretation; distribution and willingness to pay remain separate tests.
