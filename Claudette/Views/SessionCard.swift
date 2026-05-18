import SwiftUI

struct SessionCard: View {
    let bucket: UsageBucket
    var predictedMinutes: Int?

    private var level: UsageLevel {
        UsageLevel(utilization: bucket.utilization)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("현재 세션")
                .font(.system(size: 13, weight: .medium))

            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(bucket.utilization.rounded()))%")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                Spacer()

                if let date = bucket.resetsAtDate {
                    Text(ResetTimeFormatter.format(from: date))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            ProgressBar(value: bucket.utilization, height: 6, color: level.color)

            if let minutes = predictedMinutes {
                let remainingMinutes = bucket.resetsAtDate.map { Int($0.timeIntervalSinceNow / 60) }
                let isComfortable = remainingMinutes != nil && minutes > remainingMinutes!
                HStack(spacing: 4) {
                    Image(systemName: isComfortable ? "checkmark.circle" : "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11))
                    if isComfortable {
                        Text("이번 세션 한도 여유로움")
                            .font(.system(size: 11))
                    } else {
                        Text("약 \(formatPrediction(minutes))후 한도 도달 예상")
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(isComfortable ? Color.secondary : Color.orange)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("현재 세션, \(Int(bucket.utilization.rounded()))퍼센트 사용됨")
    }

    private func formatPrediction(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)시간 \(m)분 " : "\(h)시간 "
        }
        return "\(minutes)분 "
    }
}
