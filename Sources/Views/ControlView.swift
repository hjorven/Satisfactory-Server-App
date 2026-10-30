import SwiftUI

struct ControlView: View {
    @Environment(ServerStore.self) private var store
    @State private var confirm: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if !store.isAdmin {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Nur Ansicht (Gast)", systemImage: "eye")
                                    .font(.headline)
                                Text("Zum Steuern unter Einstellungen mit dem Admin-Passwort anmelden.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SERVER").font(.caption2).foregroundStyle(.secondary)
                            HStack {
                                controlButton("Start", "play.fill", "start", prominent: true)
                                controlButton("Neustart", "arrow.clockwise", "restart")
                                controlButton("Stop", "stop.fill", "stop", role: .destructive)
                            }
                            controlButton("Jetzt speichern", "tray.and.arrow.down.fill", "save")
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SIMULATION").font(.caption2).foregroundStyle(.secondary)
                            Text("Fabrik weiterlaufen lassen, auch wenn niemand online ist.")
                                .font(.footnote).foregroundStyle(.secondary)
                            HStack {
                                simButton("Dauerhaft", 0)
                                simButton("30 min", 30)
                                simButton("1 h", 60)
                            }
                            Button {
                                Task { await store.simulation(mode: "pause") }
                            } label: {
                                Label("Pausieren", systemImage: "pause.fill").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .disabled(!store.isAdmin || store.busyAction != nil)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("BACKUP").font(.caption2).foregroundStyle(.secondary)
                            Button {
                                Task { await store.runBackup() }
                            } label: {
                                Label("Jetzt sichern", systemImage: "externaldrive.fill.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .disabled(!store.isAdmin || store.busyAction != nil)
                        }
                    }

                    if let err = store.lastError {
                        Text(err).font(.footnote).foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Steuerung")
        }
    }

    @ViewBuilder
    private func controlButton(_ title: String, _ icon: String, _ action: String, prominent: Bool = false, role: ButtonRole? = nil) -> some View {
        let button = Button(role: role) {
            Task { await store.control(action) }
        } label: {
            Label(title, systemImage: icon).frame(maxWidth: .infinity)
        }
        .disabled(!store.isAdmin || store.busyAction != nil)

        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }

    private func simButton(_ title: String, _ minutes: Int) -> some View {
        Button {
            Task { await store.simulation(mode: "run", minutes: minutes) }
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .disabled(!store.isAdmin || store.busyAction != nil)
    }
}
