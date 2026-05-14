import SwiftUI

struct ProgressBar: View {
    let value: Double
    let height: CGFloat
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.primary.opacity(0.08))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(value / 100, 0), 1.0))
                    .animation(.easeOut(duration: 0.4), value: value)
            }
        }
        .frame(height: height)
        .accessibilityValue("\(Int(value.rounded()))퍼센트 사용됨")
    }
}
