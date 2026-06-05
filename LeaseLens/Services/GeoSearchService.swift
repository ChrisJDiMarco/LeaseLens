import Foundation

actor GeoSearchService {
    private let session: URLSession
    private let baseURL = URL(string: "https://geosearch.planninglabs.nyc/v2")!

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 12
            configuration.requestCachePolicy = .reloadRevalidatingCacheData
            configuration.urlCache = URLCache(
                memoryCapacity: 4 * 1024 * 1024,
                diskCapacity: 12 * 1024 * 1024
            )
            self.session = URLSession(configuration: configuration)
        }
    }

    func autocomplete(_ query: String) async throws -> [AddressCandidate] {
        try await fetch(path: "autocomplete", query: query)
    }

    func resolve(_ query: String) async throws -> AddressCandidate {
        guard let result = try await fetch(path: "search", query: query).first else {
            throw LeaseLensError.noAddressMatch
        }
        return result
    }

    private func fetch(path: String, query: String) async throws -> [AddressCandidate] {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
            return []
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "text", value: query),
            URLQueryItem(name: "size", value: "6")
        ]

        guard let url = components?.url else { throw LeaseLensError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw LeaseLensError.networkUnavailable
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw LeaseLensError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }

        let responseBody = try JSONDecoder().decode(GeoSearchResponse.self, from: data)
        return responseBody.features.compactMap(\.addressCandidate)
    }
}

private struct GeoSearchResponse: Decodable {
    let features: [GeoFeature]
}

private struct GeoFeature: Decodable {
    let geometry: GeoGeometry
    let properties: GeoProperties

    var addressCandidate: AddressCandidate? {
        guard let number = properties.housenumber,
              let street = properties.street,
              let borough = properties.borough,
              geometry.coordinates.count >= 2 else {
            return nil
        }

        let line = properties.name ?? "\(number) \(street)"
        return AddressCandidate(
            id: properties.gid ?? properties.id ?? "\(line)-\(borough)",
            streetLine: line,
            borough: borough.uppercased(),
            zip: properties.postalcode,
            latitude: geometry.coordinates[1],
            longitude: geometry.coordinates[0],
            bbl: properties.addendum?.pad?.bbl,
            bin: properties.addendum?.pad?.bin
        )
    }
}

private struct GeoGeometry: Decodable {
    let coordinates: [Double]
}

private struct GeoProperties: Decodable {
    let id: String?
    let gid: String?
    let name: String?
    let housenumber: String?
    let street: String?
    let borough: String?
    let postalcode: String?
    let addendum: GeoAddendum?
}

private struct GeoAddendum: Decodable {
    let pad: GeoPAD?
}

private struct GeoPAD: Decodable {
    let bbl: String?
    let bin: String?
}
