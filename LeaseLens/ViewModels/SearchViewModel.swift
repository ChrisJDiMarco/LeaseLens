import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var candidates: [AddressCandidate] = []
    @Published var selectedAddress: AddressCandidate?
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let service: GeoSearchService
    private var suggestionTask: Task<Void, Never>?

    init(service: GeoSearchService = GeoSearchService()) {
        self.service = service
    }

    func queryChanged() {
        suggestionTask?.cancel()
        errorMessage = nil
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            candidates = []
            isSearching = false
            return
        }

        suggestionTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            isSearching = true
            do {
                let matches = try await service.autocomplete(trimmed)
                guard !Task.isCancelled else { return }
                candidates = matches
            } catch {
                guard !Task.isCancelled else { return }
                candidates = []
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }

    func choose(_ candidate: AddressCandidate) {
        query = candidate.displayAddress
        candidates = []
        selectedAddress = candidate
    }

    func submit() async {
        suggestionTask?.cancel()
        isSearching = true
        errorMessage = nil
        do {
            if let candidate = candidates.first {
                choose(candidate)
            } else {
                let candidate = try await service.resolve(query)
                choose(candidate)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSearching = false
    }

    func tryExample(_ address: String) async {
        query = address
        candidates = []
        await submit()
    }
}
