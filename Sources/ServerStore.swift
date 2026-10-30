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
    var connectionState: ConnectionState = .idle
    var role: String = "guest"
    var lastError: String?
    var isDiscovering = false
    var busyAction: String?

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
            } else {
                try await APIClient.shared.loginGuest(url)
                role = "guest"
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
            await refresh()
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func logoutAdmin() {
        Keychain.delete("adminPassword")
        role = "guest"
    }

    func forgetServer() {
        pollTask?.cancel()
        baseURL = nil
        overview = nil
        circuits = []
        connectionState = .idle
        persist()
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
            let overview = try await ov
            let circuits = try await pw
            self.overview = overview
            self.circuits = circuits
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
        defer { busyAction = nil }
        do {
            try await APIClient.shared.control(url, action: action)
            try? await Task.sleep(for: .seconds(2))
            await refresh()
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func simulation(mode: String, minutes: Int = 0) async {
        guard let url = baseURL else { return }
        busyAction = "sim"
        defer { busyAction = nil }
        do {
            try await APIClient.shared.simulation(url, mode: mode, minutes: minutes)
            await refresh()
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func runBackup() async {
        guard let url = baseURL else { return }
        busyAction = "backup"
        defer { busyAction = nil }
        do {
            try await APIClient.shared.runBackup(url)
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
