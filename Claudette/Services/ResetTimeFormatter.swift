import Foundation

enum ResetTimeFormatter {
    static func format(from resetsAt: Date) -> String {
        let diff = resetsAt.timeIntervalSince(Date())
        guard diff > 0 else { return "곧 재설정" }

        let totalMinutes = Int(diff) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let days = hours / 24
        let remainingHours = hours % 24

        if days >= 1 {
            return "\(days)일 \(remainingHours)시간 후 재설정"
        } else if hours >= 1 {
            return "\(hours)시간 \(minutes)분 후 재설정"
        } else if totalMinutes > 0 {
            return "\(totalMinutes)분 후 재설정"
        } else {
            return "곧 재설정"
        }
    }
}
