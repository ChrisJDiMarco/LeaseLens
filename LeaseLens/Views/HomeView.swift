import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showsAbout = false

    private let examples = [
        "1726 Amsterdam Avenue, Manhattan, NY",
        "22 Stagg Street, Brooklyn, NY",
        "4646 Park Avenue, Bronx, NY"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LeaseLensTheme.canvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroHeader
                        searchPanel
                        trustPanel
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $viewModel.selectedAddress) { address in
                ReportView(address: address)
            }
            .sheet(isPresented: $showsAbout) {
                InfoView()
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                LeaseLensMark()
                VStack(alignment: .leading, spacing: 2) {
                    Text("LeaseLens")
                        .font(.headline.weight(.bold))
                    Text("NYC renter intelligence")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                Text("NYC ONLY")
                    .font(.caption2.weight(.black))
                    .tracking(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Check the building\nbefore you sign.")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                Text("A 60-second read on complaints, open violations, and recurring livability issues.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.76))
                    .lineSpacing(4)
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(
            LinearGradient(
                colors: [LeaseLensTheme.navy, LeaseLensTheme.navyRaised],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(LeaseLensTheme.teal.opacity(0.25))
                .frame(width: 150)
                .blur(radius: 30)
                .offset(x: 36, y: 45)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(
                title: "Search an address",
                subtitle: "NYC buildings only. Select an exact match for best results."
            )

            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LeaseLensTheme.mutedInk)
                TextField("Enter NYC apartment address", text: $viewModel.query)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.submit() }
                    }
                    .onChange(of: viewModel.query) {
                        viewModel.queryChanged()
                    }
                if viewModel.isSearching {
                    ProgressView()
                        .tint(LeaseLensTheme.teal)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(LeaseLensTheme.canvas, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if !viewModel.candidates.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.candidates) { candidate in
                        Button {
                            viewModel.choose(candidate)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "building.2")
                                    .foregroundStyle(LeaseLensTheme.teal)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(candidate.streetLine.nycDisplayCase)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(candidate.borough.nycDisplayCase), NY \(candidate.zip ?? "")")
                                        .font(.caption)
                                        .foregroundStyle(LeaseLensTheme.mutedInk)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(LeaseLensTheme.mutedInk)
                            }
                            .foregroundStyle(LeaseLensTheme.ink)
                            .padding(.vertical, 12)
                        }
                        if candidate.id != viewModel.candidates.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LeaseLensTheme.line, lineWidth: 1)
                }
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(LeaseLensTheme.coral)
            }

            Button {
                Task { await viewModel.submit() }
            } label: {
                Text("Check this building")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [LeaseLensTheme.teal, LeaseLensTheme.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .disabled(viewModel.query.trimmingCharacters(in: .whitespaces).count < 3)
            .opacity(viewModel.query.trimmingCharacters(in: .whitespaces).count < 3 ? 0.55 : 1)

            Text("Try an example")
                .font(.caption.weight(.semibold))
                .foregroundStyle(LeaseLensTheme.mutedInk)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(examples, id: \.self) { example in
                        Button {
                            Task { await viewModel.tryExample(example) }
                        } label: {
                            Text(example.components(separatedBy: ",").first ?? example)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(LeaseLensTheme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(LeaseLensTheme.canvas, in: Capsule())
                        }
                    }
                }
            }
        }
        .leaseCard()
    }

    private var trustPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Transparent by design")
                .font(.headline.weight(.bold))
                .foregroundStyle(LeaseLensTheme.ink)
            Text("LeaseLens reads NYC public records and translates patterns for renters. Complaints do not prove current conditions, and a quiet history is not a guarantee.")
                .font(.footnote)
                .foregroundStyle(LeaseLensTheme.mutedInk)
                .lineSpacing(3)
            HStack(spacing: 8) {
                SourceChip(title: "HPD")
                SourceChip(title: "NYC311")
                SourceChip(title: "Open Data")
            }
            Button {
                showsAbout = true
            } label: {
                Label("Methodology and privacy", systemImage: "info.circle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(LeaseLensTheme.cyan)
            }
            .accessibilityHint("Opens details about scoring, public sources, and privacy.")
        }
        .leaseCard()
    }
}

#Preview {
    HomeView()
}
