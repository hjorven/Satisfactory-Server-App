import SwiftUI
import Observation

@Observable
@MainActor
final class ServerStore {
    // Persistierte Konfiguration
    var baseURL: URL?
    var manualAddress: String = ""
    var remoteAddress: String = ""        // z. B. Tailscale-Adresse (Fallback)

    // Laufzeit-Zustand
    var overview: Overview?
    var circuits: [PowerCircuit] = []
    var players: [Player] = []
    var saves: [SaveGame] = []
    var backups: [BackupItem] = []
    var backupStatus: BackupStatus?
    var powerHistory: [PowerSample] = []   // rollender Verlauf für das Diagramm
    private let maxHistory = 180           // 180 × 5 s ≈ 15 min

    var onlineCount: Int { players.filter(\.Online).count }
    var connectionState: ConnectionState = .idle
    var role: String = "guest"
    var lastError: String?
    var isDiscovering = false
    var busyAction: String?
    var gameAuthed = false          // Satisfactory-Spiel-Admin aktiv (für Speichern/Simulation)
    var actionStatus: String?       // sachliches Feedback zur letzten Aktion
    private var statusToken = UUID()

    enum ConnectionState: Equatable {
        case idle, connecting, connected, failed
    }

    var isAdmin: Bool { role == "admin" }
    private var pollTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard

    init() {
        if let s = defaults.string(forKey: "baseURL") { baseURL = URL(string: s) }
        manualAddress = defaults.string(forKey: "manualAddress") ?? ""
        remoteAddress = defaults.string(forKey: "remoteAddress") ?? ""
    }

    private func persist() {
        defaults.set(baseURL?.absoluteString, forKey: "baseURL")
        defaults.set(manualAddress, forKey: "manualAddress")
        defaults.set(remoteAddress, forKey: "remoteAddress")
    }

    // MARK: - Verbindung

    func startup() async {
        if let url = baseURL {
            await connect(to: url)
        } else {
            await autoDiscover()
        }
    }

    func autoDiscover() async {
        isDiscovering = true
        defer { isDiscovering = false }
        let discovery = Discovery()
        if let url = await discovery.findServer() {
            await connect(to: url)
        } else if !remoteAddress.isEmpty, let url = normalizedURL(remoteAddress) {
            await connect(to: url)
        } else {
            connectionState = .failed
            lastError = "Kein Server im WLAN gefunden. Adresse manuell eintragen oder Tailscale-Adresse hinterlegen."
        }
    }

    func connectManual() async {
        guard let url = normalizedURL(manualAddress) else {
            lastError = "Ungültige Adresse."
            return
        }
        await connect(to: url)
    }

    func connect(to url: URL) async {
        connectionState = .connecting
        lastError = nil
        do {
            _ = try await APIClient.shared.health(url)
            // Admin-Login falls Passwort gespeichert, sonst Gast
            if let pw = Keychain.get("adminPassword"), !pw.isEmpty {
                let r = try await APIClient.shared.login(url, password: pw)
                role = r.role ?? "admin"
                await refreshGameAuth(url)
            } else {
                try await APIClient.shared.loginGuest(url)
                role = "guest"
                gameAuthed = false
            }
            baseURL = url
            persist()
            connectionState = .connected
            startPolling()
        } catch {
            connectionState = .failed
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func loginAdmin(password: String) async {
        guard let url = baseURL else { return }
        do {
            let r = try await APIClient.shared.login(url, password: password)
            role = r.role ?? "admin"
            Keychain.set(password, for: "adminPassword")
            lastError = nil
            await refreshGameAuth(url)
            await refresh()
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func logoutAdmin() {
        Keychain.delete("adminPassword")
        role = "guest"
        gameAuthed = false
    }

    // MARK: - Satisfactory-Spiel-Admin

    /// Meldet den Spiel-Admin an (nötig für Speichern/Simulation) und merkt sich das Passwort.
    func loginGame(password: String) async {
        guard let url = baseURL else { return }
        do {
            try await APIClient.shared.gameAuth(url, password: password)
            Keychain.set(password, for: "gamePassword")
            gameAuthed = true
            lastError = nil
            setStatus("Satisfactory-Spiel-Admin verbunden.")
        } catch {
            gameAuthed = false
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Trennt den Spiel-Admin und vergisst das gespeicherte Passwort.
    func logoutGame() {
        Keychain.delete("gamePassword")
        gameAuthed = false
        Task { if let url = baseURL { try? await APIClient.shared.gameAuthLogout(url) } }
    }

    /// Stellt den Spiel-Token (falls Passwort gespeichert) wieder her und prüft den Status.
    private func refreshGameAuth(_ url: URL) async {
        if let authed = try? await APIClient.shared.gameAuthStatus(url), authed {
            gameAuthed = true
            return
        }
        if let gpw = Keychain.get("gamePassword"), !gpw.isEmpty {
            do {
                try await APIClient.shared.gameAuth(url, password: gpw)
                gameAuthed = true
                return
            } catch { /* Passwort evtl. veraltet – Nutzer meldet sich neu an */ }
        }
        gameAuthed = false
    }

    func forgetServer() {
        pollTask?.cancel()
        baseURL = nil
        overview = nil
        circuits = []
        players = []
        saves = []
        backups = []
        backupStatus = nil
        powerHistory = []
        gameAuthed = false
        actionStatus = nil
        connectionState = .idle
        persist()
    }

    /// Setzt eine kurze, sachliche Statusmeldung, die sich nach einigen Sekunden löscht.
    private func setStatus(_ text: String?) {
        actionStatus = text
        guard text != nil else { return }
        let token = UUID()
        statusToken = token
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard let self, self.statusToken == token else { return }
            self.actionStatus = nil
        }
    }

    private func normalizedURL(_ raw: String) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespaces)
        if s.isEmpty { return nil }
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") { s = "http://" + s }
        if URL(string: s)?.port == nil, !s.hasPrefix("https://") {
            s += ":3000"
        }
        return URL(string: s)
    }

    // MARK: - Polling

    func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func refresh() async {
        guard let url = baseURL else { return }
        do {
            async let ov = APIClient.shared.overview(url)
            async let pw = APIClient.shared.power(url)
            async let pl = APIClient.shared.players(url)
            let overview = try await ov
            let circuits = try await pw
            self.overview = overview
            self.circuits = circuits
            self.players = (try? await pl) ?? []
            // Verlauf für das Diagramm fortschreiben
            powerHistory.append(PowerSample(time: Date(),
                                            production: Double(overview.power.production),
                                            consumption: Double(overview.power.consumption)))
            if powerHistory.count > maxHistory {
                powerHistory.removeFirst(powerHistory.count - maxHistory)
            }
            if let r = overview.role { self.role = r }
            if connectionState != .connected { connectionState = .connected }
        } catch APIError.unauthorized {
            // Sitzung abgelaufen – neu anmelden
            await connect(to: url)
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Aktionen

    func control(_ action: String) async {
        guard let url = baseURL else { return }
        busyAction = action
        lastError = nil
        actionStatus = pendingText(for: action)
        defer { busyAction = nil }
        do {
            let msg = try await APIClient.shared.control(url, action: action)
            setStatus(msg ?? doneText(for: action))
            try? await Task.sleep(for: .seconds(1))
            await refresh()
        } catch {
            actionStatus = nil
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func simulation(mode: String, minutes: Int = 0) async {
        guard let url = baseURL else { return }
        busyAction = "sim"
        lastError = nil
        actionStatus = mode == "pause" ? "Fabrik wird pausiert …" : "Simulation wird aktiviert …"
        defer { busyAction = nil }
        do {
            try await APIClient.shared.simulation(url, mode: mode, minutes: minutes)
            if mode == "pause" {
                setStatus("Fabrik pausiert.")
            } else if minutes > 0 {
                setStatus("Simulation läuft für \(minutes) min.")
            } else {
                setStatus("Simulation dauerhaft aktiv.")
            }
            await refresh()
        } catch {
            actionStatus = nil
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func runBackup() async {
        guard let url = baseURL else { return }
        busyAction = "backup"
        lastError = nil
        actionStatus = "Backup wird gestartet …"
        defer { busyAction = nil }
        do {
            try await APIClient.shared.runBackup(url)
            setStatus("Backup gestartet.")
            try? await Task.sleep(for: .seconds(3))
            await fetchBackups()
        } catch {
            actionStatus = nil
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Spielstände

    func fetchSaves() async {
        guard let url = baseURL else { return }
        do { saves = try await APIClient.shared.saves(url).saves }
        catch { lastError = errorText(error) }
    }

    func loadSave(_ name: String) async {
        guard let url = baseURL else { return }
        busyAction = "save-load"
        lastError = nil
        actionStatus = "Spielstand „\(name)" wird geladen …"
        defer { busyAction = nil }
        do {
            try await APIClient.shared.loadSave(url, name: name)
            setStatus("Spielstand „\(name)" geladen.")
            await refresh()
        } catch { actionStatus = nil; lastError = errorText(error) }
    }

    func deleteSave(_ name: String) async {
        guard let url = baseURL else { return }
        busyAction = "save-del"
        lastError = nil
        defer { busyAction = nil }
        do {
            try await APIClient.shared.deleteSave(url, name: name)
            setStatus("Spielstand „\(name)" gelöscht.")
            await fetchSaves()
        } catch { lastError = errorText(error) }
    }

    // MARK: - Backups

    func fetchBackups() async {
        guard let url = baseURL else { return }
        do {
            let r = try await APIClient.shared.backups(url)
            backups = r.backups
            backupStatus = r.status
        } catch { lastError = errorText(error) }
    }

    func restoreBackup(_ name: String) async {
        guard let url = baseURL else { return }
        busyAction = "restore"
        lastError = nil
        actionStatus = "Backup wird wiederhergestellt – Server stoppt …"
        defer { busyAction = nil }
        do {
            try await APIClient.shared.restoreBackup(url, name: name)
            setStatus("Backup wiederhergestellt – Server neu gestartet.")
            await refresh()
        } catch { actionStatus = nil; lastError = errorText(error) }
    }

    private func errorText(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private func pendingText(for action: String) -> String {
        switch action {
        case "start":   return "Server wird gestartet …"
        case "stop":    return "Server wird gestoppt …"
        case "restart": return "Server wird neu gestartet …"
        case "save":    return "Spielstand wird gespeichert …"
        default:        return "Aktion läuft …"
        }
    }

    private func doneText(for action: String) -> String {
        switch action {
        case "start":   return "Server gestartet."
        case "stop":    return "Server gestoppt."
        case "restart": return "Server neu gestartet."
        case "save":    return "Spielstand gespeichert."
        default:        return "Fertig."
        }
    }
}
