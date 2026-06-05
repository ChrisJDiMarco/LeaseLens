import SwiftUI

struct ReportView: View {
    @StateObject private var viewModel: ReportViewModel

    init(address: AddressCandidate) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(address: address))
    }

    var body: some View {
        ZStack {
            LeaseLensTheme.canvas.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let report = viewModel.report {
                reportContent(report)
            } else if let error = viewModel.errorMessage {
                errorView(error)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Building Report")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(LeaseLensTheme.ink)
            }
            if viewModel.report != nil && !viewModel.isLoading {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh report")
                    .accessibilityHint("Checks the public data sources again.")
                }
            }
        }
        .task {
            guard viewModel.report == nil else { return }
            await viewModel.load()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView()
                .scaleEffect(1.25)
                .tint(LeaseLensTheme.teal)
            Text("Checking public records")
                .font(.headline.weight(.semibold))
                .foregroundStyle(LeaseLensTheme.ink)
            Text("Looking at HPD and NYC311 activity for this address.")
                .font(.footnote)
                .foregroundStyle(LeaseLensTheme.mutedInk)
        }
        .padding(26)
        .leaseCard()
        .padding(24)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34))
                .foregroundStyle(LeaseLensTheme.coral)
            Text("Report unavailable")
                .font(.title3.weight(.bold))
                .foregroundStyle(LeaseLensTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(LeaseLensTheme.mutedInk)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await viewModel.load() }
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(height: 46)
            .background(LeaseLensTheme.teal, in: Capsule())
        }
        .padding(24)
        .leaseCard()
        .padding(20)
    }

    private func reportContent(_ report: BuildingReport) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                addressHeader(report)
                if let refreshError = viewModel.errorMessage {
                    refreshFailureNotice(refreshError)
                }
                if report.hasUnavailableSources {
                    coverageNotice
                }
                riskHero(report)

                if !report.reasons.isEmpty {
                    topFlags(report)
                }

                categories(report)

                if !report.violations.isEmpty {
                    violations(report)
                }

                timeline(report)
                questions(report)
                sources(report)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
    }

    private func addressHeader(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(report.address.displayAddress)
                .font(.title3.weight(.bold))
                .foregroundStyle(LeaseLensTheme.ink)
            HStack(spacing: 8) {
                Label(report.scope.title, systemImage: report.scope == .exact ? "checkmark.seal.fill" : "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(report.scope == .exact ? LeaseLensTheme.teal : LeaseLensTheme.amber)
                if let bbl = report.address.bbl {
                    Text("BBL \(bbl)")
                        .font(.caption)
                        .foregroundStyle(LeaseLensTheme.mutedInk)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func riskHero(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Overall risk")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(report.riskLevel.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.16), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: min(Double(report.score) / 24, 1))
                        .stroke(report.riskLevel.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(scoreLabel(for: report))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 62, height: 62)
            }
            Text(report.summary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.84))
                .lineSpacing(4)
            Text("Why this rating? Complaint recency, repetition, and open violations are scored visibly below.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
            Text("Checked \(report.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [LeaseLensTheme.navy, LeaseLensTheme.navyRaised],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
    }

    private var coverageNotice: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(LeaseLensTheme.amber)
            VStack(alignment: .leading, spacing: 4) {
                Text("Partial public-data coverage")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(LeaseLensTheme.ink)
                Text("At least one source could not be reached. Use this report cautiously and retry before making a lease decision.")
                    .font(.caption)
                    .foregroundStyle(LeaseLensTheme.mutedInk)
                    .lineSpacing(3)
            }
        }
        .leaseCard()
    }

    private func refreshFailureNotice(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundStyle(LeaseLensTheme.amber)
            VStack(alignment: .leading, spacing: 4) {
                Text("Refresh unavailable")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(LeaseLensTheme.ink)
                Text("Showing the last loaded report. \(message)")
                    .font(.caption)
                    .foregroundStyle(LeaseLensTheme.mutedInk)
                    .lineSpacing(3)
            }
        }
        .leaseCard()
    }

    private func topFlags(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Top red flags", subtitle: "The clearest reasons behind the rating")
            ForEach(Array(report.reasons.enumerated()), id: \.offset) { index, reason in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(LeaseLensTheme.coral)
                        .frame(width: 24, height: 24)
                        .background(LeaseLensTheme.coral.opacity(0.12), in: Circle())
                    Text(reason)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LeaseLensTheme.ink)
                    Spacer()
                }
            }
        }
        .leaseCard()
    }

    private func scoreLabel(for report: BuildingReport) -> String {
        guard report.riskLevel != .notEnoughData else { return "--" }
        return report.score > 99 ? "99+" : "\(report.score)"
    }

    private func categories(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionTitle(
                title: "Complaint categories",
                subtitle: "Counts cover the last 24 months; recent means 6 months."
            )
            if report.categories.isEmpty {
                Text("No complaint categories or open violations were returned for this building.")
                    .font(.subheadline)
                    .foregroundStyle(LeaseLensTheme.mutedInk)
                    .padding(.vertical, 8)
            } else {
                ForEach(report.categories) { category in
                    CategoryCard(summary: category)
                }
            }
        }
    }

    private func violations(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(
                title: "Open violations",
                subtitle: "Recorded by HPD and listed as open in public data."
            )
            ForEach(report.violations) { violation in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        RiskBadge(risk: violation.isSevere ? .high : .medium)
                        Text("Class \(violation.violationClass ?? "N/A")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LeaseLensTheme.mutedInk)
                        Spacer()
                        Text(violation.date.formatted(.dateTime.month(.abbreviated).year()))
                            .font(.caption)
                            .foregroundStyle(LeaseLensTheme.mutedInk)
                    }
                    Text(violation.explanation)
                        .font(.subheadline)
                        .foregroundStyle(LeaseLensTheme.ink)
                    if let url = violation.sourceURL {
                        Link("View source record", destination: url)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LeaseLensTheme.cyan)
                    }
                }
                .leaseCard()
            }
        }
    }

    private func timeline(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Recent records", subtitle: "Most recent activity first")
            VStack(spacing: 0) {
                if report.timeline.isEmpty {
                    Text("No timeline records to show.")
                        .font(.subheadline)
                        .foregroundStyle(LeaseLensTheme.mutedInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(report.timeline.enumerated()), id: \.element.id) { index, item in
                        TimelineRow(item: item, drawsLine: index < report.timeline.count - 1)
                    }
                }
            }
            .leaseCard()
        }
    }

    private func questions(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Questions to ask", subtitle: "Bring these to the broker or landlord")
            ForEach(report.questions, id: \.self) { question in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(LeaseLensTheme.teal)
                        .padding(.top, 2)
                    Text(question)
                        .font(.subheadline)
                        .foregroundStyle(LeaseLensTheme.ink)
                    Spacer()
                }
                .leaseCard()
            }
        }
    }

    private func sources(_ report: BuildingReport) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionTitle(title: "Sources checked")
            ForEach(report.sources) { source in
                Link(destination: source.url) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(LeaseLensTheme.ink)
                            Text(sourceDetail(source))
                                .font(.caption)
                                .foregroundStyle(LeaseLensTheme.mutedInk)
                        }
                        Spacer()
                        Label(source.availability.title, systemImage: source.availability.symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(source.availability.color)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LeaseLensTheme.cyan)
                    }
                    .padding(.vertical, 4)
                }
            }
            Divider()
            Text("LeaseLens uses public records. Complaint counts do not always mean a problem is confirmed, and missing complaints do not guarantee a problem-free building. This is decision support, not legal or housing advice.")
                .font(.caption)
                .foregroundStyle(LeaseLensTheme.mutedInk)
                .lineSpacing(3)
        }
        .leaseCard()
    }

    private func sourceDetail(_ source: DataSourceLink) -> String {
        if let detail = source.detail {
            if let count = source.recordCount {
                return "\(detail) - \(count) record\(count == 1 ? "" : "s")"
            }
            return detail
        }
        return source.availability.title
    }
}

private struct CategoryCard: View {
    let summary: CategorySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Image(systemName: summary.category.icon)
                    .font(.headline)
                    .foregroundStyle(summary.risk.color)
                    .frame(width: 37, height: 37)
                    .background(summary.risk.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.category.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(LeaseLensTheme.ink)
                    if summary.isRecurring {
                        Text("Recurring issue signal")
                            .font(.caption)
                            .foregroundStyle(LeaseLensTheme.coral)
                    }
                }
                Spacer()
                RiskBadge(risk: summary.risk)
            }

            HStack(spacing: 8) {
                CountMetric(value: "\(summary.complaintCount24Months)", label: "24 months")
                CountMetric(value: "\(summary.complaintCount6Months)", label: "Recent")
                CountMetric(value: "\(summary.openViolationCount)", label: "Open")
                VStack(alignment: .leading, spacing: 3) {
                    Label(summary.trend.title, systemImage: summary.trend.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(summary.trend.color)
                    Text("Trend")
                        .font(.caption)
                        .foregroundStyle(LeaseLensTheme.mutedInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let reason = summary.reasons.first {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(LeaseLensTheme.mutedInk)
            }
        }
        .leaseCard()
    }
}

private struct TimelineRow: View {
    let item: TimelineItem
    let drawsLine: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(LeaseLensTheme.teal)
                    .frame(width: 9, height: 9)
                    .padding(.top, 5)
                if drawsLine {
                    Rectangle()
                        .fill(LeaseLensTheme.line)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.label.nycDisplayCase)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LeaseLensTheme.ink)
                    Spacer()
                    Text(item.date.formatted(.dateTime.month(.abbreviated).year()))
                        .font(.caption)
                        .foregroundStyle(LeaseLensTheme.mutedInk)
                }
                HStack {
                    Text("\(item.agency) - \(item.category.title)")
                        .font(.caption)
                        .foregroundStyle(LeaseLensTheme.mutedInk)
                    if let url = item.sourceURL {
                        Link("Source", destination: url)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LeaseLensTheme.cyan)
                    }
                }
            }
            .padding(.bottom, drawsLine ? 17 : 0)
        }
    }
}
