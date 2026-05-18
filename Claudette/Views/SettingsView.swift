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

            Divider()

            weeklyModelSection

            Divider()

            notificationSection

            Spacer().frame(height: 4)
        }
        .padding(16)
        .frame(width: 320)
    }

    // MARK: - 새로고침 주기

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

    // MARK: - 메뉴바

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메뉴바")
                .font(.system(size: 13, weight: .medium))

            VStack(alignment: .leading, spacing: 6) {
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

            VStack(alignment: .leading, spacing: 6) {
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
                    .font(.system(size: 11))
                    .foregroundStyle(Color(NSColor.tertiaryLabelColor))
            }
        }
    }

    // MARK: - 주간 한도 표시

    private var weeklyModelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("주간 한도 표시")
                .font(.system(size: 13, weight: .medium))

            Text("표시할 모델을 선택하고 순서를 변경할 수 있어요")
                .font(.system(size: 11))
                .foregroundStyle(Color(NSColor.tertiaryLabelColor))

            VStack(spacing: 4) {
                ForEach(Array(settings.weeklyModelOrder.enumerated()), id: \.element) { index, modelId in
                    let label = settings.availableWeeklyModels.first(where: { $0.id == modelId })?.label ?? modelId
                    HStack(spacing: 8) {
                        Text(label)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: { moveModel(at: index, direction: -1) }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .disabled(index == 0)

                        Button(action: { moveModel(at: index, direction: 1) }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .disabled(index == settings.weeklyModelOrder.count - 1)

                        Button(action: { removeModel(at: index) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            let hidden = settings.availableWeeklyModels.filter { model in
                !settings.weeklyModelOrder.contains(model.id)
            }
            if !hidden.isEmpty {
                HStack(spacing: 6) {
                    ForEach(hidden, id: \.id) { model in
                        Button(action: { addModel(model.id) }) {
                            Text("+ \(model.label)")
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func moveModel(at index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0, newIndex < settings.weeklyModelOrder.count else { return }
        settings.weeklyModelOrder.swapAt(index, newIndex)
    }

    private func removeModel(at index: Int) {
        let id = settings.weeklyModelOrder[index]
        settings.weeklyModelOrder.remove(at: index)
        settings.hiddenWeeklyModels.insert(id)
    }

    private func addModel(_ id: String) {
        settings.weeklyModelOrder.append(id)
        settings.hiddenWeeklyModels.remove(id)
    }

    private var displayModeDescription: String {
        switch settings.menuBarDisplayMode {
        case "countdown": return "재설정까지 남은 시간 표시"
        default: return "현재 세션 사용률 표시"
        }
    }

    // MARK: - 알림

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $settings.notificationsEnabled) {
                Text("알림")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: settings.notificationsEnabled) { _, enabled in
                if enabled {
                    notificationService.clearSnooze()
                    notificationService.requestPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        notificationService.refreshAuthStatus()
                    }
                }
            }

            if settings.notificationsEnabled {
                if notificationService.systemAuthStatus == .denied {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("시스템에서 알림이 꺼져있어요")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("알림 설정") {
                                notificationService.openSystemNotificationSettings()
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.link)
                        }
                        Text("시스템 설정 → 알림 → Claudette 에서 허용해주세요")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(NSColor.tertiaryLabelColor))
                    }
                } else if notificationService.systemAuthStatus == .notDetermined {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        Text("팝오버를 닫으면 권한 요청이 보여요")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("몇 % 쓰면 알려드릴까요? (중복 선택 가능)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 1) {
                        ForEach(AppSettings.availableThresholds, id: \.self) { value in
                            SegmentButton(
                                label: "\(value)%",
                                isSelected: settings.notificationThresholds.contains(value)
                            ) {
                                toggleThreshold(value)
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

                if notificationService.isSnoozed, let until = notificationService.snoozeUntil {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            if let type = notificationService.snoozeDurationType {
                                Text(type.label)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("알림 일시정지 중")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("해제") {
                                notificationService.clearSnooze()
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.link)
                        }
                        Text("\(until, style: .date) \(until, style: .time) 까지")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(NSColor.tertiaryLabelColor))
                    }
                }
            }
        }
        .onAppear {
            notificationService.refreshAuthStatus()
        }
    }

    private func toggleThreshold(_ value: Int) {
        if settings.notificationThresholds.contains(value) {
            settings.notificationThresholds.removeAll { $0 == value }
        } else {
            settings.notificationThresholds.append(value)
            settings.notificationThresholds.sort()
        }
    }

}
