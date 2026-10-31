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

    func players(_ base: URL) async throws -> [Player] {
        let data = try await request(base, "api/frm/getPlayer")
        return (try? JSONDecoder().decode([Player].self, from: data)) ?? []
    }

    // MARK: - Spielstände & Backups

    func saves(_ base: URL) async throws -> SavesResponse {
        try JSONDecoder().decode(SavesResponse.self, from: try await request(base, "api/saves"))
    }

    func loadSave(_ base: URL, name: String) async throws {
        try await request(base, "api/saves/\(name)/load", method: "POST", timeout: 120)
    }

    func deleteSave(_ base: URL, name: String) async throws {
        try await request(base, "api/saves/\(name)", method: "DELETE")
    }

    func backups(_ base: URL) async throws -> BackupsResponse {
        try JSONDecoder().decode(BackupsResponse.self, from: try await request(base, "api/backups"))
    }

    func restoreBackup(_ base: URL, name: String) async throws {
        try await request(base, "api/backups/\(name)/restore", method: "POST", timeout: 180)
    }

    // MARK: - Weitere Monitoring-/Steuer-Endpunkte

    private func frmArray<T: Decodable>(_ base: URL, _ endpoint: String, _ type: T.Type) async throws -> [T] {
        let data = try await request(base, "api/frm/\(endpoint)")
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }

    func prodStats(_ base: URL) async throws -> [ProdItem] { try await frmArray(base, "getProdStats", ProdItem.self) }
    func trains(_ base: URL) async throws -> [TrainInfo] { try await frmArray(base, "getTrains", TrainInfo.self) }
    func vehicles(_ base: URL) async throws -> [VehicleInfo] { try await frmArray(base, "getVehicles", VehicleInfo.self) }
    func drones(_ base: URL) async throws -> [DroneInfo] { try await frmArray(base, "getDrone", DroneInfo.self) }

    func sessionInfo(_ base: URL) async throws -> SessionInfo? {
        let data = try await request(base, "api/frm/getSessionInfo")
        return try? JSONDecoder().decode(SessionInfo.self, from: data)
    }

    func mods(_ base: URL) async throws -> ModsResponse {
        try JSONDecoder().decode(ModsResponse.self, from: try await request(base, "api/mods"))
    }

    func settings(_ base: URL) async throws -> ServerSettings {
        try JSONDecoder().decode(ServerSettings.self, from: try await request(base, "api/settings"))
    }

    func saveSettings(_ base: URL, _ s: ServerSettings) async throws {
        try await request(base, "api/settings", method: "POST",
                          body: ["autoPause": s.autoPause,
                                 "autoSaveOnDisconnect": s.autoSaveOnDisconnect,
                                 "autosaveInterval": s.autosaveInterval])
    }

    // MARK: - Host / Alarme / Zeitplan

    func host(_ base: URL) async throws -> HostInfo {
        try JSONDecoder().decode(HostInfo.self, from: try await request(base, "api/host"))
    }

    func alertConfig(_ base: URL) async throws -> AlertConfig {
        try JSONDecoder().decode(AlertConfig.self, from: try await request(base, "api/alerts/config"))
    }
    func saveAlertConfig(_ base: URL, _ c: AlertConfig) async throws {
        try await request(base, "api/alerts/config", method: "POST",
                          body: ["power": c.power, "derail": c.derail, "playerJoin": c.playerJoin,
                                 "playerLeave": c.playerLeave, "serverDown": c.serverDown,
                                 "lowDisk": c.lowDisk, "lowDiskGB": c.lowDiskGB])
    }
    func alertHistory(_ base: URL) async throws -> [AlertHistoryItem] {
        try JSONDecoder().decode(AlertHistoryResponse.self, from: try await request(base, "api/alerts/history")).history
    }

    func schedule(_ base: URL) async throws -> RestartSchedule {
        try JSONDecoder().decode(RestartSchedule.self, from: try await request(base, "api/schedule"))
    }
    func saveSchedule(_ base: URL, _ s: RestartSchedule) async throws {
        try await request(base, "api/schedule", method: "POST",
                          body: ["enabled": s.enabled, "time": s.time,
                                 "skipIfPlayers": s.skipIfPlayers, "warnMinutes": s.warnMinutes])
    }
    func restartTimer(_ base: URL) async throws -> RestartTimerState {
        try JSONDecoder().decode(RestartTimerState.self, from: try await request(base, "api/restart-timer"))
    }
    func setRestartTimer(_ base: URL, minutes: Int) async throws {
        try await request(base, "api/restart-timer", method: "POST", body: ["minutes": minutes])
    }
    func cancelRestartTimer(_ base: URL) async throws {
        try await request(base, "api/restart-timer", method: "POST", body: ["cancel": true])
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
