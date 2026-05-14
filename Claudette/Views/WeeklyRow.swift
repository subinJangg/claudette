import SwiftUI

struct WeeklyRow: View {
    let model: WeeklyModelUsage

    private var level: UsageLevel {
        UsageLevel(utilization: model.bucket.utilization)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(model.displayName)
                    .font(.system(size: 12))
                Spacer()
                Text("\(Int(model.bucket.utilization.rounded()))%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }
            ProgressBar(value: model.bucket.utilization, height: 4, color: level.color)
        }
    }
}
