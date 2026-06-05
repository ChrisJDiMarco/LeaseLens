import Foundation

actor NYCOpenDataService {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let calendar = Calendar(identifier: .gregorian)
    private let hpdProblemsDataset = "ygpa-z7cr"
    private let hpdViolationsDataset = "wvxf-dwi5"
    private let serviceRequestsDataset = "erm2-nwe9"

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15
            configuration.requestCachePolicy = .reloadRevalidatingCacheData
            configuration.urlCache = URLCache(
                memoryCapacity: 8 * 1024 * 1024,
                diskCapacity: 30 * 1024 * 1024
            )
            self.session = URLSession(configuration: configuration)
        }
    }

    func fetchBuildingData(for address: AddressCandidate, asOf date: Date = .now) async throws -> RawBuildingData {
        async let problemsResult = optionalResult { try await self.fetchHPDProblems(for: address, asOf: date) }
        async let violationsResult = optionalResult { try await self.fetchOpenHPDViolations(for: address) }
        async let serviceRequestsResult = optionalResult { try await self.fetchExact311Requests(for: address, asOf: date) }

        let (problems, violations, serviceRequests) = await (problemsResult, violationsResult, serviceRequestsResult)
        guard problems != nil || violations != nil || serviceRequests != nil else {
            throw LeaseLensError.allDataSourcesUnavailable
        }

        var checks = [
            sourceCheck(.hpdComplaints, records: problems, detail: "Building complaint records"),
            sourceCheck(.hpdViolations, records: violations, detail: "Open building violations"),
            sourceCheck(.nyc311, records: serviceRequests, detail: "Exact-address service requests")
        ]

        let exactComplaints = (problems ?? []) + (serviceRequests ?? [])
        let exactViolations = violations ?? []

        if !exactComplaints.isEmpty || !exactViolations.isEmpty {
            return RawBuildingData(
                complaints: exactComplaints.sorted { $0.date > $1.date },
                violations: exactViolations.sorted { $0.date > $1.date },
                scope: .exact,
                sourceChecks: checks
            )
        }

        let nearbyComplaints = await optionalResult { try await self.fetchNearby311Requests(for: address, asOf: date) }
        if let nearbyComplaints {
            checks[2] = SourceCheck(
                source: .nyc311,
                availability: .checked,
                recordCount: nearbyComplaints.count,
                detail: nearbyComplaints.isEmpty ? "No exact or nearby requests returned" : "Nearby requests within 75 meters"
            )
        } else if serviceRequests != nil {
            checks[2] = SourceCheck(
                source: .nyc311,
                availability: .checked,
                recordCount: 0,
                detail: "Exact-address requests checked; nearby fallback unavailable"
            )
        }

        return RawBuildingData(
            complaints: (nearbyComplaints ?? []).sorted { $0.date > $1.date },
            violations: [],
            scope: (nearbyComplaints ?? []).isEmpty ? .exact : .nearby,
            sourceChecks: checks
        )
    }

    private func optionalResult<T>(_ request: () async throws -> [T]) async -> [T]? {
        do {
            return try await request()
        } catch {
            return nil
        }
    }

    private func sourceCheck<T>(_ source: PublicDataSource, records: [T]?, detail: String) -> SourceCheck {
        if let records {
            return SourceCheck(source: source, availability: .checked, recordCount: records.count, detail: detail)
        }
        return SourceCheck(source: source, availability: .unavailable, recordCount: nil, detail: "Could not be reached during this check")
    }

    private func fetchHPDProblems(for address: AddressCandidate, asOf date: Date) async throws -> [ComplaintRecord] {
        let dateFloor = formatSocrataDate(calendar.date(byAdding: .month, value: -24, to: date) ?? date)
        let locationFilter: String
        if let bin = address.bin {
            locationFilter = "bin = '\(escape(bin))'"
        } else {
            locationFilter = exactAddressFilter(
                houseColumn: "house_number",
                streetColumn: "street_name",
                boroughColumn: "borough",
                address: address
            )
        }
        let whereClause = "\(locationFilter) AND received_date >= '\(dateFloor)'"
        let rows: [HPDProblemRow] = try await query(
            dataset: hpdProblemsDataset,
            select: "received_date,unique_key,major_category,minor_category,problem_code,problem_status",
            whereClause: whereClause,
            orderBy: "received_date DESC",
            limit: 400
        )

        return rows.compactMap { row in
            guard let date = parseSocrataDate(row.receivedDate) else { return nil }
            let text = [row.majorCategory, row.minorCategory, row.problemCode].compactMap { $0 }.joined(separator: " - ")
            return ComplaintRecord(
                id: "HPD-\(row.uniqueKey ?? UUID().uuidString)",
                agency: "HPD",
                date: date,
                category: IssueCategorizer.category(for: text),
                type: row.majorCategory ?? "Housing complaint",
                detail: row.problemCode ?? row.minorCategory ?? "Housing maintenance complaint",
                status: row.problemStatus,
                scope: .exact,
                sourceURL: sourceRecordURL(dataset: hpdProblemsDataset, key: "unique_key", value: row.uniqueKey)
            )
        }
    }

    private func fetchOpenHPDViolations(for address: AddressCandidate) async throws -> [ViolationRecord] {
        let whereClause = "\(exactAddressFilter(houseColumn: "housenumber", streetColumn: "streetname", boroughColumn: "boro", address: address)) AND violationstatus = 'Open'"
        let rows: [HPDViolationRow] = try await query(
            dataset: hpdViolationsDataset,
            select: "violationid,class,novdescription,novissueddate,currentstatus,violationstatus",
            whereClause: whereClause,
            orderBy: "novissueddate DESC",
            limit: 100
        )

        return rows.compactMap { row in
            guard let date = parseSocrataDate(row.issuedDate) else { return nil }
            let category = IssueCategorizer.category(for: row.description ?? "")
            return ViolationRecord(
                id: "HPDV-\(row.id ?? UUID().uuidString)",
                agency: "HPD",
                date: date,
                category: category,
                violationClass: row.violationClass,
                status: row.currentStatus ?? row.violationStatus ?? "Open",
                explanation: IssueCategorizer.plainLanguageViolation(category: category, className: row.violationClass),
                sourceURL: sourceRecordURL(dataset: hpdViolationsDataset, key: "violationid", value: row.id)
            )
        }
    }

    private func fetchExact311Requests(for address: AddressCandidate, asOf date: Date) async throws -> [ComplaintRecord] {
        let dateFloor = formatSocrataDate(calendar.date(byAdding: .month, value: -24, to: date) ?? date)
        let whereClause = "incident_address = '\(escape(address.streetLine))' AND borough = '\(escape(address.borough))' AND created_date >= '\(dateFloor)' AND agency != 'HPD'"
        return try await fetch311(whereClause: whereClause, scope: .exact)
    }

    private func fetchNearby311Requests(for address: AddressCandidate, asOf date: Date) async throws -> [ComplaintRecord] {
        let dateFloor = formatSocrataDate(calendar.date(byAdding: .month, value: -24, to: date) ?? date)
        let whereClause = "created_date >= '\(dateFloor)' AND within_circle(location, \(address.latitude), \(address.longitude), 75) AND agency != 'HPD'"
        return try await fetch311(whereClause: whereClause, scope: .nearby)
    }

    private func fetch311(whereClause: String, scope: RecordScope) async throws -> [ComplaintRecord] {
        let rows: [ServiceRequestRow] = try await query(
            dataset: serviceRequestsDataset,
            select: "unique_key,created_date,agency,complaint_type,descriptor,status",
            whereClause: whereClause,
            orderBy: "created_date DESC",
            limit: 250
        )
        return rows.compactMap { row in
            guard let date = parseSocrataDate(row.createdDate) else { return nil }
            let text = [row.complaintType, row.descriptor].compactMap { $0 }.joined(separator: " - ")
            return ComplaintRecord(
                id: "311-\(row.uniqueKey ?? UUID().uuidString)",
                agency: row.agency ?? "NYC311",
                date: date,
                category: IssueCategorizer.category(for: text),
                type: row.complaintType ?? "Service request",
                detail: row.descriptor ?? "Public service request",
                status: row.status,
                scope: scope,
                sourceURL: sourceRecordURL(dataset: serviceRequestsDataset, key: "unique_key", value: row.uniqueKey)
            )
        }
    }

    private func query<T: Decodable>(
        dataset: String,
        select: String,
        whereClause: String,
        orderBy: String,
        limit: Int
    ) async throws -> [T] {
        var components = URLComponents(string: "https://data.cityofnewyork.us/resource/\(dataset).json")
        components?.queryItems = [
            URLQueryItem(name: "$select", value: select),
            URLQueryItem(name: "$where", value: whereClause),
            URLQueryItem(name: "$order", value: orderBy),
            URLQueryItem(name: "$limit", value: String(limit))
        ]
        guard let url = components?.url else { throw LeaseLensError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw LeaseLensError.networkUnavailable
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw LeaseLensError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        return try decoder.decode([T].self, from: data)
    }

    private func exactAddressFilter(
        houseColumn: String,
        streetColumn: String,
        boroughColumn: String,
        address: AddressCandidate
    ) -> String {
        let lineParts = address.streetLine.split(separator: " ", maxSplits: 1).map(String.init)
        guard lineParts.count == 2 else { return "\(boroughColumn) = '\(escape(address.borough))'" }
        return "\(houseColumn) = '\(escape(lineParts[0]))' AND \(streetColumn) = '\(escape(lineParts[1]))' AND \(boroughColumn) = '\(escape(address.borough))'"
    }

    private func sourceRecordURL(dataset: String, key: String, value: String?) -> URL? {
        guard let value else { return nil }
        var components = URLComponents(string: "https://data.cityofnewyork.us/resource/\(dataset).json")
        components?.queryItems = [URLQueryItem(name: key, value: value)]
        return components?.url
    }

    private func escape(_ input: String) -> String {
        input.replacingOccurrences(of: "'", with: "''")
    }

    private func formatSocrataDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: date)
    }

    private func parseSocrataDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter.date(from: string)
    }
}

private struct HPDProblemRow: Decodable {
    let receivedDate: String?
    let uniqueKey: String?
    let majorCategory: String?
    let minorCategory: String?
    let problemCode: String?
    let problemStatus: String?

    enum CodingKeys: String, CodingKey {
        case receivedDate = "received_date"
        case uniqueKey = "unique_key"
        case majorCategory = "major_category"
        case minorCategory = "minor_category"
        case problemCode = "problem_code"
        case problemStatus = "problem_status"
    }
}

private struct HPDViolationRow: Decodable {
    let id: String?
    let violationClass: String?
    let description: String?
    let issuedDate: String?
    let currentStatus: String?
    let violationStatus: String?

    enum CodingKeys: String, CodingKey {
        case id = "violationid"
        case violationClass = "class"
        case description = "novdescription"
        case issuedDate = "novissueddate"
        case currentStatus = "currentstatus"
        case violationStatus = "violationstatus"
    }
}

private struct ServiceRequestRow: Decodable {
    let uniqueKey: String?
    let createdDate: String?
    let agency: String?
    let complaintType: String?
    let descriptor: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case uniqueKey = "unique_key"
        case createdDate = "created_date"
        case agency
        case complaintType = "complaint_type"
        case descriptor
        case status
    }
}
