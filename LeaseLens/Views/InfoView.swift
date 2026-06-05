import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    introCard
                    methodologyCard
                    privacyCard
                    disclaimerCard
                }
                .padding(18)
            }
            .background(LeaseLensTheme.canvas.ignoresSafeArea())
            .navigationTitle("About LeaseLens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LeaseLensTheme.teal)
                }
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                LeaseLensMark()
                VStack(alignment: .leading, spacing: 3) {
                    Text("LeaseLens")
                        .font(.headline.weight(.bold))
                    Text("Public records, translated for renters")
                        .font(.caption)
                        .foregroundStyle(LeaseLensTheme.mutedInk)
                }
            }
            Text("LeaseLens helps a renter ask better questions before signing. It does not rate landlords, confirm current conditions, or provide legal advice.")
                .font(.subheadline)
                .foregroundStyle(LeaseLensTheme.ink)
                .lineSpacing(3)
        }
        .leaseCard()
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "How scoring works")
            InfoRow(title: "Recent complaints", detail: "Records from the last 24 months count toward the score; the last 6 months receive additional weight.")
            InfoRow(title: "Recurring signals", detail: "Repeated complaints within 90 days or across multiple years increase the score.")
            InfoRow(title: "Open violations", detail: "Open HPD violations carry more weight, with Class C violations treated as especially significant.")
            Text("Risk thresholds: 0-5 Low, 6-15 Medium, 16+ High. A score is an explainable signal, not a finding of fact.")
                .font(.caption)
                .foregroundStyle(LeaseLensTheme.mutedInk)
                .lineSpacing(3)
        }
        .leaseCard()
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Privacy")
            Text("LeaseLens has no accounts, advertising, analytics, tracking, or stored search history in this release.")
            Text("When you search, the address is sent directly from your device to NYC Planning GeoSearch and NYC Open Data services only to retrieve the requested public records. Those public services may process requests under their own policies.")
            Link("NYC Open Data terms and privacy", destination: URL(string: "https://opendata.cityofnewyork.us/overview/")!)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(LeaseLensTheme.cyan)
        }
        .font(.subheadline)
        .foregroundStyle(LeaseLensTheme.ink)
        .lineSpacing(3)
        .leaseCard()
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(title: "Use with care")
            Text("Complaint records may be incomplete, duplicated, unconfirmed, or no longer reflect building conditions. Absence of a record does not guarantee a problem-free property. Verify important concerns with the landlord, broker, city sources, and appropriate professionals.")
                .font(.footnote)
                .foregroundStyle(LeaseLensTheme.mutedInk)
                .lineSpacing(3)
        }
        .leaseCard()
    }
}

private struct InfoRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LeaseLensTheme.ink)
            Text(detail)
                .font(.caption)
                .foregroundStyle(LeaseLensTheme.mutedInk)
                .lineSpacing(3)
        }
    }
}
