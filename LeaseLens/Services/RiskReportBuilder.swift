import Foundation

enum IssueCategorizer {
    static func category(for sourceText: String) -> IssueCategory {
        let text = sourceText.lowercased()
        let mappings: [(IssueCategory, [String])] = [
            (.heatHotWater, ["heat", "hot water", "boiler"]),
            (.pests, ["pest", "rodent", "rat", "mouse", "mice", "roach", "vermin"]),
            (.moldLeaks, ["mold", "mildew", "leak", "water damage", "damp", "moisture"]),
            (.plumbing, ["plumb", "sewer", "toilet", "sink", "drain"]),
            (.elevator, ["elevator"]),
            (.noise, ["noise", "loud", "music"]),
            (.trash, ["trash", "garbage", "dirty", "sanitation", "rubbish"]),
            (.security, ["door", "lock", "security", "window guard"]),
            (.construction, ["construction", "permit", "scaffold", "demolition"]),
            (.safety, ["structural", "facade", "collapse", "electric", "fire", "smoke", "carbon monoxide"])
        ]
        return mappings.first { _, words in words.contains { text.contains($0) } }?.0 ?? .other
    }

    static func plainLanguageViolation(category: IssueCategory, className: String?) -> String {
        let severity: String
        switch className?.uppercased() {
        case "C": severity = "HPD lists this as an immediately hazardous violation"
        case "B": severity = "HPD lists this as a hazardous violation"
        case "A": severity = "HPD lists this as a non-hazardous violation"
        default: severity = "HPD lists an open violation"
        }
        return "\(severity) related to \(category.title.lowercased())."
    }
}

struct RiskReportBuilder {
    private let calendar = Calendar(identifier: .gregorian)

    func build(address: AddressCandidate, from raw: RawBuildingData, asOf now: Date = .now) -> BuildingReport {
        let cutoff24 = calendar.date(byAdding: .month, value: -24, to: now) ?? now
        let cutoff6 = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        let cutoff12 = calendar.date(byAdding: .month, value: -12, to: now) ?? now
        let complaints = raw.complaints.filter { $0.date >= cutoff24 && $0.date <= now }

        let categories = IssueCategory.allCases.compactMap { category -> CategorySummary? in
            let categoryComplaints = complaints.filter { $0.category == category }
            let violations = raw.violations.filter { $0.category == category }
            guard !categoryComplaints.isEmpty || !violations.isEmpty else { return nil }

            let recentCount = categoryComplaints.filter { $0.date >= cutoff6 }.count
            let previousCount = categoryComplaints.filter { $0.date >= cutoff12 && $0.date < cutoff6 }.count
            let clustered = containsNinetyDayCluster(categoryComplaints)
            let spansYears = Set(categoryComplaints.map { calendar.component(.year, from: $0.date) }).count > 1
            let recurring = categoryComplaints.count >= 3 || clustered || spansYears || !violations.isEmpty
            var score = categoryComplaints.count + recentCount * 2 + violations.count * 5
            if clustered { score += 3 }
            if spansYears { score += 4 }
            score += violations.filter(\.isSevere).count * 3

            var reasons: [String] = []
            if categoryComplaints.count > 0 {
                reasons.append("\(categoryComplaints.count) complaint\(categoryComplaints.count == 1 ? "" : "s") in 24 months")
            }
            if recentCount > 0 {
                reasons.append("\(recentCount) in the last 6 months")
            }
            if clustered {
                reasons.append("Repeated reports occurred within 90 days")
            }
            if spansYears {
                reasons.append("Reports appear across multiple years")
            }
            if !violations.isEmpty {
                reasons.append("\(violations.count) open HPD violation\(violations.count == 1 ? "" : "s")")
            }

            return CategorySummary(
                category: category,
                score: score,
                risk: riskLevel(for: score, hasData: true),
                complaintCount24Months: categoryComplaints.count,
                complaintCount6Months: recentCount,
                openViolationCount: violations.count,
                trend: trend(recent: recentCount, previous: previousCount, total: categoryComplaints.count),
                isRecurring: recurring,
                reasons: reasons,
                exampleTypes: Array(Set(categoryComplaints.map(\.detail))).sorted().prefix(2).map { $0 }
            )
        }
        .sorted { $0.score > $1.score }

        let totalScore = categories.reduce(0) { $0 + $1.score }
        let hasData = !complaints.isEmpty || !raw.violations.isEmpty
        let risk = riskLevel(for: totalScore, hasData: hasData)
        let rankedHeadlineCategories = categories.filter { $0.category != .other } + categories.filter { $0.category == .other }
        let headlineReasons = rankedHeadlineCategories.prefix(3).map { summary in
            var point = "\(summary.category.title): \(summary.complaintCount24Months) complaints"
            if summary.openViolationCount > 0 {
                point += ", \(summary.openViolationCount) open violations"
            }
            return point
        }

        let questions = buildQuestions(from: categories, hasViolations: !raw.violations.isEmpty)
        let timeline = buildTimeline(complaints: complaints, violations: raw.violations)
        var reportSummary = summary(risk: risk, scope: raw.scope, categories: categories)
        if raw.sourceChecks.contains(where: { $0.availability == .unavailable }) {
            reportSummary += " Some sources were unavailable, so this rating may be incomplete."
        }

        return BuildingReport(
            address: address,
            scope: raw.scope,
            riskLevel: risk,
            score: totalScore,
            summary: reportSummary,
            reasons: headlineReasons,
            categories: categories,
            violations: raw.violations,
            timeline: timeline,
            questions: questions,
            sources: dataSources(from: raw),
            checkedAt: now
        )
    }

    private func riskLevel(for score: Int, hasData: Bool) -> RiskLevel {
        guard hasData else { return .notEnoughData }
        switch score {
        case ...5: return .low
        case 6...15: return .medium
        default: return .high
        }
    }

    private func containsNinetyDayCluster(_ records: [ComplaintRecord]) -> Bool {
        let dates = records.map(\.date).sorted()
        guard dates.count > 1 else { return false }
        return zip(dates, dates.dropFirst()).contains { first, second in
            let days = calendar.dateComponents([.day], from: first, to: second).day ?? 999
            return days <= 90
        }
    }

    private func trend(recent: Int, previous: Int, total: Int) -> ActivityTrend {
        guard total >= 2 else { return .insufficientData }
        if recent >= previous + 2 { return .increasing }
        if previous >= recent + 2 { return .decreasing }
        return .stable
    }

    private func summary(risk: RiskLevel, scope: RecordScope, categories: [CategorySummary]) -> String {
        if risk == .notEnoughData {
            return "No matching recent public records were returned. Missing complaints do not guarantee a problem-free building."
        }
        let specificCategories = categories.filter { $0.category != .other }
        let featured = specificCategories.isEmpty ? Array(categories.prefix(2)) : Array(specificCategories.prefix(2))
        let concerns = featured.map { $0.category.title.lowercased() }.joined(separator: " and ")
        if scope == .nearby {
            return "Public records near this address show activity related to \(concerns). These are nearby signals, not confirmed records for the building."
        }
        let base: String
        switch risk {
        case .low:
            base = "Public records show limited recent activity for this building. Ask about any repairs before signing."
        case .medium:
            base = "Public records suggest recurring \(concerns) concerns. Ask what repairs or corrective work were completed."
        case .high:
            base = "Public records show substantial \(concerns) activity or open violations. Review these issues closely before signing."
        case .notEnoughData:
            return ""
        }
        return base
    }

    private func buildQuestions(from categories: [CategorySummary], hasViolations: Bool) -> [String] {
        var questions = categories.filter(\.isRecurring).prefix(4).map { $0.category.brokerQuestion }
        if questions.isEmpty {
            questions.append("Have there been building-wide repairs or open complaints in the last two years?")
        }
        if hasViolations {
            questions.append("Have the open violations been corrected, and can you provide proof of correction?")
        }
        return Array(Set(questions)).sorted()
    }

    private func buildTimeline(complaints: [ComplaintRecord], violations: [ViolationRecord]) -> [TimelineItem] {
        let complaintItems = complaints.map {
            TimelineItem(
                id: $0.id,
                date: $0.date,
                category: $0.category,
                label: $0.type,
                agency: $0.agency,
                sourceURL: $0.sourceURL
            )
        }
        let violationItems = violations.map {
            TimelineItem(
                id: $0.id,
                date: $0.date,
                category: $0.category,
                label: "Open HPD violation",
                agency: $0.agency,
                sourceURL: $0.sourceURL
            )
        }
        return (complaintItems + violationItems).sorted { $0.date > $1.date }.prefix(12).map { $0 }
    }

    private func dataSources(from raw: RawBuildingData) -> [DataSourceLink] {
        let geosearch = SourceCheck(
            source: .geoSearch,
            availability: .checked,
            recordCount: 1,
            detail: "Address normalized"
        )
        return ([geosearch] + raw.sourceChecks).map {
            DataSourceLink(
                source: $0.source,
                availability: $0.availability,
                recordCount: $0.recordCount,
                detail: $0.detail
            )
        }
    }
}
