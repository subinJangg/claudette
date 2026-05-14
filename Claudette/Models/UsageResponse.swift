import Foundation

struct UsageBucket: Codable {
    let utilization: Double
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    var resetsAtDate: Date? {
        guard let resetsAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: resetsAt) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: resetsAt)
    }
}

struct WeeklyModelUsage: Identifiable {
    let id: String
    let displayName: String
    let bucket: UsageBucket
}

struct UsageData {
    let fiveHour: UsageBucket?
    let weeklyModels: [WeeklyModelUsage]

    private static let knownDisplayNames: [String: String] = [
        "seven_day": "모든 모델",
        "seven_day_sonnet": "Sonnet만",
        "seven_day_opus": "Opus만",
        "seven_day_haiku": "Haiku만",
        "seven_day_omelette": "Claude Design",
        "seven_day_cowork": "Cowork",
    ]

    private static let displayOrder: [String] = [
        "seven_day",
        "seven_day_sonnet",
        "seven_day_opus",
        "seven_day_haiku",
        "seven_day_omelette",
        "seven_day_cowork",
    ]

    static func displayName(for key: String) -> String {
        if let known = knownDisplayNames[key] { return known }
        let suffix = key.replacingOccurrences(of: "seven_day_", with: "")
        return suffix.split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    init(from jsonData: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "UsageData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }

        if let dict = json["five_hour"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: dict),
           let bucket = try? JSONDecoder().decode(UsageBucket.self, from: data)
        {
            self.fiveHour = bucket
        } else {
            self.fiveHour = nil
        }

        var models: [WeeklyModelUsage] = []
        let decoder = JSONDecoder()

        for (key, value) in json {
            guard key.hasPrefix("seven_day") else { continue }
            guard let dict = value as? [String: Any] else { continue }
            guard let data = try? JSONSerialization.data(withJSONObject: dict),
                  let bucket = try? decoder.decode(UsageBucket.self, from: data) else { continue }

            models.append(WeeklyModelUsage(
                id: key,
                displayName: Self.displayName(for: key),
                bucket: bucket
            ))
        }

        let order = Self.displayOrder
        models.sort { a, b in
            let aIdx = order.firstIndex(of: a.id) ?? Int.max
            let bIdx = order.firstIndex(of: b.id) ?? Int.max
            if aIdx != bIdx { return aIdx < bIdx }
            return a.id < b.id
        }

        self.weeklyModels = models
    }
}
