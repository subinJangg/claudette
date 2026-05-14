import SwiftUI

struct SetupGuideView: View {
    @ObservedObject var usageService: UsageService
    @State private var showNotFound = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gauge.high")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Claude Desktop 연결 필요")
                .font(.system(size: 18, weight: .semibold))

            Text("Claude Desktop이 설치되어 있고,\n로그인된 상태여야 해요.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("다시 확인하기") {
                usageService.checkToken()
                if case .notLoggedIn = usageService.state {
                    showNotFound = true
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if showNotFound {
                Text("세션을 찾을 수 없어요.\nClaude Desktop에서 로그인되어 있는지 확인해주세요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(width: 320)
    }
}
