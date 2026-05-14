import Foundation
import Security
import SQLite3
import CommonCrypto

struct DesktopSessionReader {

    private static var cachedPassword: String?
    private static var cachedSessionKey: String?
    private static let lock = NSLock()

    static func readSessionKey() -> String? {
        lock.lock()
        defer { lock.unlock() }

        if let cachedSessionKey { return cachedSessionKey }
        guard let encrypted = readEncryptedCookie() else { return nil }
        guard let password = readKeychainPassword() else { return nil }
        let key = decrypt(encrypted, password: password)
        cachedSessionKey = key
        return key
    }

    static func invalidateCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedPassword = nil
        cachedSessionKey = nil
    }

    private static func readEncryptedCookie() -> Data? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let path = "\(home)/Library/Application Support/Claude/Cookies"

        guard FileManager.default.fileExists(atPath: path) else { return nil }

        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let query = """
            SELECT encrypted_value FROM cookies
            WHERE host_key LIKE '%claude%' AND name = 'sessionKey'
            LIMIT 1
            """
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        guard let blob = sqlite3_column_blob(stmt, 0) else { return nil }
        let length = Int(sqlite3_column_bytes(stmt, 0))
        return Data(bytes: blob, count: length)
    }

    private static func readKeychainPassword() -> String? {
        if let cachedPassword { return cachedPassword }

        for service in ["Claude Safe Storage", "Electron Safe Storage"] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess,
               let data = result as? Data,
               let password = String(data: data, encoding: .utf8),
               !password.isEmpty {
                cachedPassword = password
                return password
            }
        }
        return nil
    }

    private static func decrypt(_ data: Data, password: String) -> String? {
        guard data.count > 3,
              String(data: data[0..<3], encoding: .utf8) == "v10" else { return nil }

        let ciphertext = data.subdata(in: 3..<data.count)

        guard let passBytes = password.data(using: .utf8),
              let saltBytes = "saltysalt".data(using: .utf8) else { return nil }

        var derivedKey = [UInt8](repeating: 0, count: kCCKeySizeAES128)
        let pbkdf = passBytes.withUnsafeBytes { passBuf in
            saltBytes.withUnsafeBytes { saltBuf in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passBuf.baseAddress?.assumingMemoryBound(to: Int8.self),
                    passBytes.count,
                    saltBuf.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    saltBytes.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
                    1003,
                    &derivedKey,
                    kCCKeySizeAES128
                )
            }
        }
        guard pbkdf == kCCSuccess else { return nil }

        let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)
        var output = [UInt8](repeating: 0, count: ciphertext.count + kCCBlockSizeAES128)
        var outputLen: size_t = 0

        let status = ciphertext.withUnsafeBytes { buf in
            CCCrypt(
                CCOperation(kCCDecrypt),
                CCAlgorithm(kCCAlgorithmAES),
                CCOptions(kCCOptionPKCS7Padding),
                derivedKey, kCCKeySizeAES128,
                iv,
                buf.baseAddress, ciphertext.count,
                &output, output.count,
                &outputLen
            )
        }
        guard status == kCCSuccess else { return nil }

        let raw = Data(output[0..<outputLen])

        if let fullString = String(data: raw, encoding: .utf8) {
            return fullString
        }

        // Chrome 146+ (Electron 41+): v10 format includes a nonce prefix
        // that corrupts the first 2 CBC blocks. Find the session key
        // by searching for the "sk-ant" byte pattern in decrypted output.
        let marker: [UInt8] = Array("sk-ant".utf8)
        if let startIdx = raw.firstRange(of: marker)?.lowerBound {
            let keyData = raw.subdata(in: startIdx..<raw.count)
            return String(data: keyData, encoding: .utf8)
                ?? String(bytes: keyData.filter { $0 >= 0x20 && $0 < 0x7f }, encoding: .utf8)
        }

        return nil
    }
}
