import XCTest
@testable import LeaseLens

final class RiskReportBuilderTests: XCTestCase {
    private let address = AddressCandidate(
        id: "test",
        streetLine: "245 EAST 80 STREET",
        borough: "MANHATTAN",
        zip: "10075",
        latitude: 40.774,
        longitude: -73.954,
        bbl: "1015260021",
        bin: "1048532"
    )

    func testRecurringHeatAndSevereViolationProducesHighRiskReport() {
        let now = date("2026-05-26")
        let complaints = [
            complaint(id: "1", date: date("2026-01-08")),
            complaint(id: "2", date: date("2026-02-02")),
            complaint(id: "3", date: date("2026-02-15"))
        ]
        let violation = ViolationRecord(
            id: "v1",
            agency: "HPD",
            date: date("2026-01-15"),
            category: .heatHotWater,
            violationClass: "C",
            status: "Open",
            explanation: "Immediately hazardous heat violation.",
            sourceURL: nil
        )

        let report = RiskReportBuilder().build(
            address: address,
            from: rawData(complaints: complaints, violations: [violation]),
            asOf: now
        )

        XCTAssertEqual(report.riskLevel, .high)
        XCTAssertEqual(report.categories.first?.category, .heatHotWater)
        XCTAssertEqual(report.categories.first?.isRecurring, true)
        XCTAssertTrue(report.questions.contains { $0.contains("heating") })
    }

    func testEmptyReportUsesNotEnoughDataLanguage() {
        let report = RiskReportBuilder().build(
            address: address,
            from: rawData(complaints: [], violations: []),
            asOf: date("2026-05-26")
        )

        XCTAssertEqual(report.riskLevel, .notEnoughData)
        XCTAssertEqual(report.score, 0)
        XCTAssertTrue(report.summary.contains("No matching recent public records"))
    }

    func testHeadlinePrefersSpecificConcernOverGenericRecordsBucket() {
        let genericViolations = (1...4).map { index in
            ViolationRecord(
                id: "generic-\(index)",
                agency: "HPD",
                date: date("2026-01-15"),
                category: .other,
                violationClass: "B",
                status: "Open",
                explanation: "Administrative posting issue.",
                sourceURL: nil
            )
        }
        let report = RiskReportBuilder().build(
            address: address,
            from: rawData(complaints: [complaint(id: "heat", date: date("2026-02-01"))], violations: genericViolations),
            asOf: date("2026-05-26")
        )

        XCTAssertTrue(report.summary.contains("heat / hot water"))
        XCTAssertFalse(report.summary.contains("other recorded"))
    }

    func testPartialSourceAvailabilityIsDisclosedInReport() {
        let data = RawBuildingData(
            complaints: [complaint(id: "heat", date: date("2026-02-01"))],
            violations: [],
            scope: .exact,
            sourceChecks: [
                SourceCheck(source: .hpdComplaints, availability: .checked, recordCount: 1, detail: nil),
                SourceCheck(source: .hpdViolations, availability: .unavailable, recordCount: nil, detail: nil),
                SourceCheck(source: .nyc311, availability: .checked, recordCount: 0, detail: nil)
            ]
        )

        let report = RiskReportBuilder().build(address: address, from: data, asOf: date("2026-05-26"))

        XCTAssertTrue(report.hasUnavailableSources)
        XCTAssertTrue(report.summary.contains("may be incomplete"))
    }

    private func complaint(id: String, date: Date) -> ComplaintRecord {
        ComplaintRecord(
            id: id,
            agency: "HPD",
            date: date,
            category: .heatHotWater,
            type: "HEAT/HOT WATER",
            detail: "NO HEAT",
            status: "OPEN",
            scope: .exact,
            sourceURL: nil
        )
    }

    private func rawData(complaints: [ComplaintRecord], violations: [ViolationRecord]) -> RawBuildingData {
        RawBuildingData(
            complaints: complaints,
            violations: violations,
            scope: .exact,
            sourceChecks: [
                SourceCheck(source: .hpdComplaints, availability: .checked, recordCount: complaints.count, detail: nil),
                SourceCheck(source: .hpdViolations, availability: .checked, recordCount: violations.count, detail: nil),
                SourceCheck(source: .nyc311, availability: .checked, recordCount: 0, detail: nil)
            ]
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
