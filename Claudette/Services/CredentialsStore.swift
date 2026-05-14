import Foundation

struct Credentials {
    let sessionKey: String
    let orgId: String
}

final class CredentialsStore {
    static let shared = CredentialsStore()

    private var cached: Credentials?

    func loadAsync() async -> Credentials? {
        if let cached { return cached }

        guard let sessionKey = DesktopSessionReader.readSessionKey() else {
            return nil
        }

        guard let orgId = await fetchOrgId(sessionKey: sessionKey) else {
            return nil
        }

        let creds = Credentials(sessionKey: sessionKey, orgId: orgId)
        cached = creds
        return creds
    }

    func invalidateCache() {
        cached = nil
        DesktopSessionReader.invalidateCache()
    }

    private func fetchOrgId(sessionKey: String) async -> String? {
        guard let url = URL(string: "https://claude.ai/api/organizations") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh) AppleWebKit/605.1.15 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let orgs = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = orgs.first,
                  let uuid = first["uuid"] as? String else { return nil }
            return uuid
        } catch {
            return nil
        }
    }
}
