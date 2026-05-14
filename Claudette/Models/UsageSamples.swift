import Foundation

struct UsageSample {
    let timestamp: Date
    let utilization: Double
}

@MainActor
final class UsageSamples: ObservableObject {
    @Published private(set) var samples: [UsageSample] = []
    private let maxDuration: TimeInterval = 3600

    func record(_ utilization: Double) {
        let sample = UsageSample(timestamp: Date(), utilization: utilization)
        samples.append(sample)
        let cutoff = Date().addingTimeInterval(-maxDuration)
        samples.removeAll { $0.timestamp < cutoff }
    }

    func predictMinutesToLimit() -> Int? {
        guard samples.count >= 3 else { return nil }

        let thirtyMinAgo = Date().addingTimeInterval(-1800)
        let recent = samples.filter { $0.timestamp >= thirtyMinAgo }
        guard recent.count >= 3,
              let first = recent.first, let last = recent.last else { return nil }
        let timeSpan = last.timestamp.timeIntervalSince(first.timestamp)
        guard timeSpan >= 300 else { return nil }
        guard last.utilization - first.utilization >= 0.5 else { return nil }

        let baseTime = samples.first!.timestamp.timeIntervalSince1970
        let xs = samples.map { $0.timestamp.timeIntervalSince1970 - baseTime }
        let ys = samples.map { $0.utilization }
        let n = Double(samples.count)

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)

        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denom
        guard slope > 0 else { return nil }

        let intercept = (sumY - slope * sumX) / n
        let currentX = Date().timeIntervalSince1970 - baseTime
        let targetX = (100.0 - intercept) / slope
        let secondsToLimit = targetX - currentX

        guard secondsToLimit > 0 else { return nil }
        let minutes = Int(secondsToLimit / 60)
        return minutes > 0 ? minutes : nil
    }
}
