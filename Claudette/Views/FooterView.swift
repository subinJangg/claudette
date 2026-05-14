import SwiftUI

struct FooterView: View {
    let lastUpdated: Date?
    let isRefreshing: Bool
    var snoozeUntil: Date?
    let onRefresh: () -> Void
    let onSettings: () -> Void
    let onQuit: () -> Void

    @State private var rotationDegrees: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            if let snoozeDate = snoozeUntil, Date() < snoozeDate {
                HStack(spacing: 4) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 11))
                    Text("알림 일시정지 중 (\(snoozeDate, style: .time) 까지)")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if let lastUpdated {
                    Text(lastUpdated, style: .time)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .rotationEffect(.degrees(rotationDegrees))
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
                .help("지금 새로고침")
                .accessibilityLabel("지금 새로고침")
                .accessibilityHint("사용량을 즉시 갱신합니다")
                .onChange(of: isRefreshing) { _, newValue in
                    if newValue {
                        withAnimation(.linear(duration: 0.8)) {
                            rotationDegrees += 360
                        }
                    }
                }

                Button(action: onSettings) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("설정 열기")
                .accessibilityLabel("설정 열기")

                Button(action: onQuit) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("종료")
                .accessibilityLabel("Claudette 종료")
            }
        }
    }
}
