import SwiftUI

struct HeaderView: View {
    let utilization: Double?

    private var level: UsageLevel {
        UsageLevel(utilization: utilization)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CLAUDE.AI")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Text("Max plan")
                    .font(.system(size: 14, weight: .medium))
            }
            Spacer()
            Image(systemName: level.menuBarIcon)
                .font(.system(size: 14))
                .foregroundStyle(level.color)
                .frame(width: 28, height: 28)
                .background(level.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel("상태: \(accessibilityStatus)")
        }
    }

    private var accessibilityStatus: String {
        guard let u = utilization else { return "데이터 없음" }
        return "\(Int(u.rounded()))퍼센트 사용"
    }
}
