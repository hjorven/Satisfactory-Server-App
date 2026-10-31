import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case unauthorized
    case http(Int)
    case message(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Kein Server konfiguriert."
        case .unauthorized: return "Nicht angemeldet."
        case .http(let code): return "HTTP \(code)"
        case .message(let m): return m
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = HTTPCookieStorage.shared
        cfg.httpShouldSetCookies = true
        cfg.httpCookieAcceptPolicy = .always
        cfg.timeoutIntervalForRequest = 12
        cfg.waitsForConnectivity = false
        session = URLSession(configuration: cfg)
    }

    private func makeURL(_ base: URL, _ path: String) -> URL? {
        guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return nil }
        comps.path = "/" + path
        return comps.url
    }

    @discardableResult
    private func request(_ base: URL, _ path: String, method: String = "GET", body: [String: Any]? = nil, timeout: TimeInterval? = nil) async throws -> Data {
        guard let url = makeURL(base, path) else { throw APIError.notConfigured }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let timeout { req.timeoutInterval = timeout }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        } else if method != "GET" {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = Data("{}".utf8)
        }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.message("Keine Antwort vom Server.") }
        if http.statusCode == 401 {
            // Echte Server-Meldung erhalten (z. B. fehlender Spiel-Login); nur die
            // reine Sitzungs-Meldung als .unauthorized behandeln (löst Re-Login aus).
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let e = obj["error"] as? String, e != "Bitte zuerst anmelden." {
                throw APIError.message(e)
            }
            throw APIError.unauthorized
        }
        if !(200...299).contains(http.statusCode) {
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let e = obj["error"] as? String {
                throw APIError.message(e)
            }
            throw APIError.http(http.statusCode)
        }
        return data
    }

    func health(_ base: URL) async throws -> HealthResponse {
        try JSONDecoder().decode(HealthResponse.self, from: try await request(base, "api/health"))
    }

    func loginGuest(_ base: URL) async throws {
        try await request(base, "api/login/guest", method: "POST")
    }

    func login(_ base: URL, password: String) async throws -> LoginResponse {
        try JSONDecoder().decode(LoginResponse.self, from: try await request(base, "api/login", method: "POST", body: ["password": password]))
    }

    func overview(_ base: URL) async throws -> Overview {
        try JSONDecoder().decode(Overview.self, from: try await request(base, "api/overview"))
    }

    func power(_ base: URL) async throws -> [PowerCircuit] {
        let data = try await request(base, "api/frm/getPower")
        return (try? JSONDecoder().decode([PowerCircuit].self, from: data)) ?? []
    }

    @discardableResult
    func control(_ base: URL, action: String) async throws -> String? {
        // Docker-Aktionen (stop/restart) können dauern → großzügiges Timeout
        let data = try await request(base, "api/control/\(action)", method: "POST", timeout: 120)
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj?["message"] as? String
    }

    func simulation(_ base: URL, mode: String, minutes: Int = 0) async throws {
        try await request(base, "api/simulation", method: "POST", body: ["mode": mode, "minutes": minutes])
    }

    // MARK: - Satisfactory-Spiel-Admin (Game-API-Token)

    func gameAuth(_ base: URL, password: String) async throws {
        try await request(base, "api/game-auth", method: "POST", body: ["password": password])
    }

    func gameAuthLogout(_ base: URL) async throws {
        try await request(base, "api/game-auth/logout", method: "POST")
    }

    func gameAuthStatus(_ base: URL) async throws -> Bool {
        let data = try await request(base, "api/game-auth")
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["authenticated"] as? Bool) ?? false
    }

    func runBackup(_ base: URL) async throws {
        try await request(base, "api/backups/run", method: "POST")
    }
}
