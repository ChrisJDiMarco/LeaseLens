import Foundation

enum RiskLevel: String {
    case low
    case medium
    case high
    case notEnoughData

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .notEnoughData: return "Not enough data"
        }
    }
}

enum RecordScope: String {
    case exact
    case nearby

    var title: String {
        switch self {
        case .exact: return "Records for this building"
        case .nearby: return "Nearby records only"
        }
    }
}

enum SourceAvailability: String {
    case checked
    case unavailable

    var title: String {
        switch self {
        case .checked: return "Checked"
        case .unavailable: return "Unavailable"
        }
    }
}

enum PublicDataSource: String, Identifiable {
    case geoSearch
    case hpdComplaints
    case hpdViolations
    case nyc311

    var id: String { rawValue }

    var title: String {
        switch self {
        case .geoSearch: return "NYC Planning GeoSearch"
        case .hpdComplaints: return "HPD Complaints / Problems"
        case .hpdViolations: return "HPD Violations"
        case .nyc311: return "NYC311 Service Requests"
        }
    }

    var url: URL {
        switch self {
        case .geoSearch:
            return URL(string: "https://geosearch.planninglabs.nyc/")!
        case .hpdComplaints:
            return URL(string: "https://data.cityofnewyork.us/resource/ygpa-z7cr.json")!
        case .hpdViolations:
            return URL(string: "https://data.cityofnewyork.us/resource/wvxf-dwi5.json")!
        case .nyc311:
            return URL(string: "https://data.cityofnewyork.us/resource/erm2-nwe9.json")!
        }
    }
}

enum ActivityTrend: String {
    case increasing
    case decreasing
    case stable
    case insufficientData

    var title: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        case .insufficientData: return "Limited data"
        }
    }
}

enum IssueCategory: String, CaseIterable, Identifiable {
    case heatHotWater
    case pests
    case moldLeaks
    case plumbing
    case elevator
    case noise
    case trash
    case security
    case construction
    case safety
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .heatHotWater: return "Heat / Hot Water"
        case .pests: return "Pests / Rodents"
        case .moldLeaks: return "Mold / Leaks"
        case .plumbing: return "Plumbing"
        case .elevator: return "Elevator"
        case .noise: return "Noise"
        case .trash: return "Trash / Cleanliness"
        case .security: return "Doors / Security"
        case .construction: return "Construction"
        case .safety: return "Structural / Safety"
        case .other: return "Other Recorded Issues"
        }
    }

    var icon: String {
        switch self {
        case .heatHotWater: return "thermometer.sun.fill"
        case .pests: return "exclamationmark.shield.fill"
        case .moldLeaks: return "drop.triangle.fill"
        case .plumbing: return "wrench.and.screwdriver.fill"
        case .elevator: return "arrow.up.arrow.down.square.fill"
        case .noise: return "speaker.wave.2.fill"
        case .trash: return "trash.fill"
        case .security: return "lock.shield.fill"
        case .construction: return "hammer.fill"
        case .safety: return "exclamationmark.triangle.fill"
        case .other: return "doc.text.magnifyingglass"
        }
    }

    var brokerQuestion: String {
        switch self {
        case .heatHotWater:
            return "Have there been heating or hot-water outages in the last two winters, and what repairs were completed?"
        case .pests:
            return "Is there an active pest-control contract, and how frequently is treatment performed?"
        case .moldLeaks:
            return "Were leaks or moisture sources professionally repaired, and was any mold remediation documented?"
        case .plumbing:
            return "Have recurring plumbing issues in this building been repaired, and when was the last major fix?"
        case .elevator:
            return "What is the elevator service history and current maintenance schedule?"
        case .noise:
            return "Are noise complaints tied to building systems, construction, or nearby conditions?"
        case .trash:
            return "How are trash pickup and common-area cleaning handled each week?"
        case .security:
            return "Have entry-door, lock, or security issues been corrected?"
        case .construction:
            return "Is active construction expected during the lease term, and what hours are permitted?"
        case .safety:
            return "Can you provide documentation showing that recorded safety issues were corrected?"
        case .other:
            return "Are there unresolved building complaints or repairs a prospective tenant should know about?"
        }
    }
}

struct AddressCandidate: Identifiable, Hashable {
    let id: String
    let streetLine: String
    let borough: String
    let zip: String?
    let latitude: Double
    let longitude: Double
    let bbl: String?
    let bin: String?

    var displayAddress: String {
        let place = "\(streetLine.nycDisplayCase), \(borough.nycDisplayCase), NY"
        guard let zip, !zip.isEmpty else { return place }
        return "\(place) \(zip)"
    }
}

struct ComplaintRecord: Identifiable {
    let id: String
    let agency: String
    let date: Date
    let category: IssueCategory
    let type: String
    let detail: String
    let status: String?
    let scope: RecordScope
    let sourceURL: URL?
}

struct ViolationRecord: Identifiable {
    let id: String
    let agency: String
    let date: Date
    let category: IssueCategory
    let violationClass: String?
    let status: String
    let explanation: String
    let sourceURL: URL?

    var isSevere: Bool { violationClass?.uppercased() == "C" }
}

struct CategorySummary: Identifiable {
    var id: String { category.id }
    let category: IssueCategory
    let score: Int
    let risk: RiskLevel
    let complaintCount24Months: Int
    let complaintCount6Months: Int
    let openViolationCount: Int
    let trend: ActivityTrend
    let isRecurring: Bool
    let reasons: [String]
    let exampleTypes: [String]
}

struct TimelineItem: Identifiable {
    let id: String
    let date: Date
    let category: IssueCategory
    let label: String
    let agency: String
    let sourceURL: URL?
}

struct SourceCheck {
    let source: PublicDataSource
    let availability: SourceAvailability
    let recordCount: Int?
    let detail: String?
}

struct DataSourceLink: Identifiable {
    var id: String { source.id }
    let source: PublicDataSource
    let availability: SourceAvailability
    let recordCount: Int?
    let detail: String?

    var title: String { source.title }
    var url: URL { source.url }
}

struct BuildingReport {
    let address: AddressCandidate
    let scope: RecordScope
    let riskLevel: RiskLevel
    let score: Int
    let summary: String
    let reasons: [String]
    let categories: [CategorySummary]
    let violations: [ViolationRecord]
    let timeline: [TimelineItem]
    let questions: [String]
    let sources: [DataSourceLink]
    let checkedAt: Date

    var hasUnavailableSources: Bool {
        sources.contains { $0.availability == .unavailable }
    }
}

struct RawBuildingData {
    let complaints: [ComplaintRecord]
    let violations: [ViolationRecord]
    let scope: RecordScope
    let sourceChecks: [SourceCheck]
}

enum LeaseLensError: LocalizedError {
    case invalidURL
    case invalidAddress
    case serverError(Int)
    case noAddressMatch
    case allDataSourcesUnavailable
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "LeaseLens could not prepare this data request."
        case .invalidAddress:
            return "Choose a complete NYC street address to continue."
        case .serverError(let statusCode):
            return "NYC public records returned an error (HTTP \(statusCode)). Try again shortly."
        case .noAddressMatch:
            return "No NYC building matched that search. Try including a borough or ZIP code."
        case .allDataSourcesUnavailable:
            return "NYC public data sources could not be reached right now. Check your connection and try again."
        case .networkUnavailable:
            return "No internet connection is available. Reconnect and try again."
        }
    }
}

extension String {
    var nycDisplayCase: String {
        lowercased().capitalized
            .replacingOccurrences(of: " Ny ", with: " NY ")
            .replacingOccurrences(of: " Nw ", with: " NW ")
            .replacingOccurrences(of: " Ne ", with: " NE ")
            .replacingOccurrences(of: " Sw ", with: " SW ")
            .replacingOccurrences(of: " Se ", with: " SE ")
    }
}
