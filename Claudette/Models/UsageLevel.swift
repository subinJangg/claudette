import SwiftUI

enum UsageLevel: Equatable {
    case normal
    case warning
    case danger
    case neutral

    init(utilization: Double?, warning: Int = 50, danger: Int = 80) {
        guard let u = utilization else { self = .neutral; return }
        if u >= Double(danger) { self = .danger }
        else if u >= Double(warning) { self = .warning }
        else { self = .normal }
    }

    var color: Color {
        switch self {
        case .normal: .green
        case .warning: .orange
        case .danger: .red
        case .neutral: .secondary
        }
    }

    var menuBarIcon: String {
        switch self {
        case .normal: "circle.fill"
        case .warning: "circle.lefthalf.filled"
        case .danger: "exclamationmark.circle.fill"
        case .neutral: "gauge.medium"
        }
    }
}
