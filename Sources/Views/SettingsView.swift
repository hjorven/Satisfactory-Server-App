import SwiftUI

struct SettingsView: View {
    @Environment(ServerStore.self) private var store
    @State private var adminPassword: String = ""
    @State private var gamePassword: String = ""

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section("Server") {
                    LabeledContent("Status") {
                        Text(statusText).foregroundStyle(statusColor)
                    }
                    LabeledContent("Adresse", value: store.baseURL?.absoluteString ?? "–")
                    Button("Neu im WLAN suchen") { Task { await store.autoDiscover() } }
                    Button("Server wechseln / vergessen", role: .destructive) { store.forgetServer() }
                }

                Section("Manuelle Adresse") {
                    TextField("192.168.178.99", text: $store.manualAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Verbinden") { Task { await store.connectManual() } }
                }

                Section("Remote (Tailscale)") {
                    TextField("z. B. satisfactory.<tailnet>.ts.net", text: $store.remoteAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Wird genutzt, wenn der Server nicht im WLAN gefunden wird.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Admin-Zugang") {
                    if store.isAdmin {
                        LabeledContent("Rolle", value: "Admin")
                        Button("Abmelden (nur Ansicht)", role: .destructive) { store.logoutAdmin() }
                    } else {
                        SecureField("Admin-Passwort", text: $adminPassword)
                        Button("Als Admin anmelden") {
                            Task {
                                await store.loginAdmin(password: adminPassword)
                                adminPassword = ""
                            }
                        }
                        .disabled(adminPassword.isEmpty)
                        Text("Nötig für Steuerung, Simulation und Backups. Wird sicher im Schlüsselbund gespeichert.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                if store.isAdmin {
                    Section("Satisfactory-Spiel-Admin") {
                        if store.gameAuthed {
                            LabeledContent("Status") {
                                Label("Verbunden", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            Button("Spiel-Admin trennen", role: .destructive) {
                                store.logoutGame()
                            }
                        } else {
                            SecureField("Satisfactory-Admin-Passwort", text: $gamePassword)
                            Button("Spiel-Admin verbinden") {
                                Task {
                                    await store.loginGame(password: gamePassword)
                                    gamePassword = ""
                                }
                            }
                            .disabled(gamePassword.isEmpty)
                        }
                        Text("Nötig für Speichern & Simulation (Satisfactory-Server-Admin-Passwort, nicht das WebUI-Passwort).")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let err = store.lastError {
                    Section { Text(err).foregroundStyle(.red).font(.footnote) }
                }

                Section {
                    LabeledContent("Alarme", value: "über ntfy-App")
                    Text("Strom-/Zug-Alarme kommen als Push über die ntfy-App (separat abonniert).")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
        }
    }

    private var statusText: String {
        switch store.connectionState {
        case .idle: return "Bereit"
        case .connecting: return "Verbinde …"
        case .connected: return "Verbunden"
        case .failed: return "Fehlgeschlagen"
        }
    }
    private var statusColor: Color {
        switch store.connectionState {
        case .connected: return .green
        case .failed: return .red
        default: return .secondary
        }
    }
}
