import SwiftUI

struct ErrorCard: View {
    let error: UsageError
    let onRetry: () -> Void

    private var message: String {
        switch error {
        case .sessionExpired: "세션이 만료됐어요. Claude Desktop에서 다시 로그인해주세요."
        case .serverError: "claude.ai 응답이 없어요. 잠시 후 자동 재시도합니다."
        case .networkError: "인터넷 연결을 확인할 수 없어요. 잠시 후 재시도합니다."
        case .parseError: "응답 형식이 변경됐어요. 앱 업데이트가 필요할 수 있어요."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("문제 발생")
                    .font(.system(size: 12, weight: .medium))
            }

            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if error == .sessionExpired {
                Button("다시 확인", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
