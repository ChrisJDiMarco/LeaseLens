import SwiftUI

enum LeaseLensTheme {
    static let ink = Color(red: 0.05, green: 0.11, blue: 0.16)
    static let mutedInk = Color(red: 0.38, green: 0.44, blue: 0.49)
    static let navy = Color(red: 0.04, green: 0.13, blue: 0.20)
    static let navyRaised = Color(red: 0.08, green: 0.20, blue: 0.27)
    static let teal = Color(red: 0.08, green: 0.65, blue: 0.59)
    static let cyan = Color(red: 0.16, green: 0.61, blue: 0.87)
    static let amber = Color(red: 0.95, green: 0.61, blue: 0.20)
    static let coral = Color(red: 0.88, green: 0.30, blue: 0.28)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let line = Color.black.opacity(0.06)
}

extension RiskLevel {
    var color: Color {
        switch self {
        case .low: return LeaseLensTheme.teal
        case .medium: return LeaseLensTheme.amber
        case .high: return LeaseLensTheme.coral
        case .notEnoughData: return LeaseLensTheme.mutedInk
        }
    }

    var symbol: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .notEnoughData: return "questionmark.circle.fill"
        }
    }
}

extension ActivityTrend {
    var symbol: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .insufficientData: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .increasing: return LeaseLensTheme.coral
        case .decreasing: return LeaseLensTheme.teal
        case .stable: return LeaseLensTheme.cyan
        case .insufficientData: return LeaseLensTheme.mutedInk
        }
    }
}

extension SourceAvailability {
    var color: Color {
        switch self {
        case .checked: return LeaseLensTheme.teal
        case .unavailable: return LeaseLensTheme.amber
        }
    }

    var symbol: String {
        switch self {
        case .checked: return "checkmark.circle.fill"
        case .unavailable: return "exclamationmark.circle.fill"
        }
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LeaseLensTheme.line, lineWidth: 1)
            }
            .shadow(color: LeaseLensTheme.navy.opacity(0.04), radius: 14, y: 5)
    }
}

extension View {
    func leaseCard() -> some View {
        modifier(CardStyle())
    }
}
