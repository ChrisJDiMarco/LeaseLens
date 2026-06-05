# LeaseLens Native MVP Architecture

## Flow

1. `GeoSearchService` searches NYC Planning GeoSearch and returns standardized address candidates with BBL/BIN where available.
2. `NYCOpenDataService` performs cached, read-only HTTPS queries against HPD complaints, open HPD violations, and NYC311 records for the selected building.
3. Each record source reports its own availability so one public API outage can produce a clearly labeled partial report instead of a blank failure.
4. If no exact records return, a small-radius NYC311 fallback is requested and the report is labeled as nearby-only.
5. `RiskReportBuilder` categorizes records, scores explainable risk, detects recurrence/trends, and generates renter questions.
6. SwiftUI screens render loading, error, empty, report, methodology, and privacy states.

## Source Tree

```text
LeaseLens/
  LeaseLensApp.swift                 App entry point
  Models/LeaseLensModels.swift       Domain and report models
  Services/GeoSearchService.swift    NYC address resolution
  Services/NYCOpenDataService.swift  Public-record network layer
  Services/RiskReportBuilder.swift   Categorization and scoring rules
  ViewModels/SearchViewModel.swift   Address search state
  ViewModels/ReportViewModel.swift   Report loading state
  Views/AppTheme.swift               Visual tokens and formatting
  Views/Components.swift             Reusable native views
  Views/HomeView.swift               Search-first landing screen
  Views/ReportView.swift             Full renter report
  Views/InfoView.swift               Methodology and privacy explanation
  Resources/PrivacyInfo.xcprivacy    App privacy manifest
LeaseLensTests/
  RiskReportBuilderTests.swift       Explainable scoring tests
```

## Trust Rules

- Exact building records and nearby fallback records are never presented as the same thing.
- A failed public source is identified and any resulting risk rating is explicitly marked incomplete.
- Complaints are described as reports, not confirmed current conditions.
- Every risk label is accompanied by reasons and public source links.
- User-entered values used in Socrata filters are escaped and URL encoded.
