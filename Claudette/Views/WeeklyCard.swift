import SwiftUI

struct WeeklyCard: View {
    let models: [WeeklyModelUsage]

    private var resetDate: Date? {
        models.compactMap { $0.bucket.resetsAtDate }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("주간 한도")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                if let date = resetDate {
                    Text(ResetTimeFormatter.format(from: date))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(models) { model in
                WeeklyRow(model: model)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
