import Combine
import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    @Published var report: BuildingReport?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let address: AddressCandidate
    private let service: NYCOpenDataService
    private let reportBuilder: RiskReportBuilder

    init(
        address: AddressCandidate,
        service: NYCOpenDataService = NYCOpenDataService(),
        reportBuilder: RiskReportBuilder = RiskReportBuilder()
    ) {
        self.address = address
        self.service = service
        self.reportBuilder = reportBuilder
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let rawData = try await service.fetchBuildingData(for: address)
            report = reportBuilder.build(address: address, from: rawData)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
