import SwiftUI

struct ControlView: View {
    @Environment(ServerStore.self) private var store

    private var running: Bool { store.overview?.running ?? false }
    private var busy: Bool { store.busyAction != nil }

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

                    // Laufende Aktion / Rückmeldung
                    if busy, let s = store.actionStatus {
                        GlassCard {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text(s).font(.subheadline)
                            }
                        }
                    } else if let s = store.actionStatus {
                        GlassCard {
                            Label(s, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("SERVER").font(.caption2).foregroundStyle(.secondary)
                                Spacer()
                                Text(running ? "läuft" : "gestoppt")
                                    .font(.caption2.bold())
                                    .foregroundStyle(running ? .green : .secondary)
                            }
                            HStack {
                                controlButton("Start", "play.fill", "start",
                                              enabled: store.isAdmin && !busy && !running, prominent: true)
                                controlButton("Neustart", "arrow.clockwise", "restart",
                                              enabled: store.isAdmin && !busy && running)
                                controlButton("Stop", "stop.fill", "stop",
                                              enabled: store.isAdmin && !busy && running, role: .destructive)
                            }
                            controlButton("Jetzt speichern", "tray.and.arrow.down.fill", "save",
                                          enabled: store.isAdmin && !busy && running && store.gameAuthed)
                            if store.isAdmin && !store.gameAuthed {
                                gameAuthHint
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SIMULATION").font(.caption2).foregroundStyle(.secondary)
                            Text("Fabrik weiterlaufen lassen, auch wenn niemand online ist.")
                                .font(.footnote).foregroundStyle(.secondary)
                            let simOK = store.isAdmin && !busy && running && store.gameAuthed
                            HStack {
                                simButton("Dauerhaft", 0, enabled: simOK)
                                simButton("30 min", 30, enabled: simOK)
                                simButton("1 h", 60, enabled: simOK)
                            }
                            Button {
                                Task { await store.simulation(mode: "pause") }
                            } label: {
                                Label("Pausieren", systemImage: "pause.fill").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .disabled(!simOK)
                            if store.isAdmin && !store.gameAuthed {
                                gameAuthHint
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("VERWALTUNG").font(.caption2).foregroundStyle(.secondary)
                            NavigationLink { SavesView() } label: {
                                Label("Spielstände", systemImage: "externaldrive.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                            Divider()
                            NavigationLink { BackupsView() } label: {
                                Label("Backups", systemImage: "clock.arrow.circlepath")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                        }
                    }

                    if let err = store.lastError {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Steuerung")
        }
    }

    private var gameAuthHint: some View {
        Text("Für Speichern/Simulation zusätzlich das Satisfactory-Spiel-Admin-Passwort unter Einstellungen eingeben.")
            .font(.caption2).foregroundStyle(.orange)
    }

    @ViewBuilder
    private func controlButton(_ title: String, _ icon: String, _ action: String,
                               enabled: Bool, prominent: Bool = false, role: ButtonRole? = nil) -> some View {
        let button = Button(role: role) {
            Task { await store.control(action) }
        } label: {
            Label(title, systemImage: icon).frame(maxWidth: .infinity)
        }
        .disabled(!enabled)

        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }

    private func simButton(_ title: String, _ minutes: Int, enabled: Bool) -> some View {
        Button {
            Task { await store.simulation(mode: "run", minutes: minutes) }
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .disabled(!enabled)
    }
}
