import SwiftUI

struct LeaseLensMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LeaseLensTheme.teal, LeaseLensTheme.cyan],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 46, height: 46)
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(LeaseLensTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(LeaseLensTheme.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RiskBadge: View {
    let risk: RiskLevel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: risk.symbol)
            Text(risk.title)
        }
        .font(.footnote.weight(.bold))
        .foregroundStyle(risk.color)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(risk.color.opacity(0.13), in: Capsule())
    }
}

struct CountMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(LeaseLensTheme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(LeaseLensTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SourceChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(LeaseLensTheme.teal)
            Text(title)
                .lineLimit(1)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(LeaseLensTheme.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(LeaseLensTheme.canvas, in: Capsule())
    }
}
