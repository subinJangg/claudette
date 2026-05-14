import SwiftUI

struct SegmentButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var notificationService: NotificationService
    let onDismiss: () -> Void

    private let displayModes: [(String, String)] = [
        ("퍼센트", "percent"),
        ("카운트다운", "countdown"),
    ]

    private let iconStyles: [(String, String)] = [
        ("도넛", "donut"),
        ("배터리", "battery"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)

                Text("설정")
                    .font(.system(size: 14, weight: .medium))
            }

            refreshIntervalSection

            Divider()

            menuBarSection

        }
        .padding(16)
        .frame(width: 320)
    }

    private var refreshIntervalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("새로고침 주기")
                .font(.system(size: 13, weight: .medium))

            HStack(spacing: 1) {
                ForEach(AppSettings.refreshIntervalOptions, id: \.seconds) { option in
                    SegmentButton(
                        label: option.label,
                        isSelected: settings.refreshInterval == option.seconds
                    ) {
                        settings.refreshInterval = option.seconds
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
        }
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메뉴바")
                .font(.system(size: 13, weight: .medium))

            VStack(alignment: .leading, spacing: 4) {
                Text("아이콘 스타일")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                HStack(spacing: 1) {
                    ForEach(iconStyles, id: \.1) { option in
                        SegmentButton(
                            label: option.0,
                            isSelected: settings.menuBarIconStyle == option.1
                        ) {
                            settings.menuBarIconStyle = option.1
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("표시 모드")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                HStack(spacing: 1) {
                    ForEach(displayModes, id: \.1) { option in
                        SegmentButton(
                            label: option.0,
                            isSelected: settings.menuBarDisplayMode == option.1
                        ) {
                            settings.menuBarDisplayMode = option.1
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )

                Text(displayModeDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(NSColor.tertiaryLabelColor))
            }
        }
    }

    private var displayModeDescription: String {
        switch settings.menuBarDisplayMode {
        case "countdown": return "재설정까지 남은 시간 표시"
        default: return "현재 세션 사용률 표시"
        }
    }

}
