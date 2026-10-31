import SwiftUI

struct ScheduleView: View {
    @Environment(ServerStore.self) private var store
    @State private var enabled = false
    @State private var timeDate = Date()
    @State private var skipIfPlayers = false
    @State private var warnMinutes: Double = 5
    @State private var oneTimeMinutes: Double = 10
    @State private var loaded = false

    var body: some View {
        Form {
            if !store.isAdmin {
                Section {
                    Text("Nur für Admins. Unter Einstellungen mit dem Admin-Passwort anmelden.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                Section("Täglicher Neustart") {
                    Toggle("Aktiviert", isOn: $enabled)
                    DatePicker("Uhrzeit", selection: $timeDate, displayedComponents: .hourAndMinute)
                    Toggle("Überspringen, wenn Spieler online", isOn: $skipIfPlayers)
                    Stepper("Vorwarnung (ntfy): \(Int(warnMinutes)) min",
                            value: $warnMinutes, in: 0...30, step: 1)
                    Button("Zeitplan speichern") {
                        Task {
                            await store.saveSchedule(RestartSchedule(
                                enabled: enabled, time: hhmm(timeDate),
                                skipIfPlayers: skipIfPlayers, warnMinutes: Int(warnMinutes)))
                        }
                    }
                    .disabled(store.busyAction != nil)
                }

                Section("Einmaliger Neustart") {
                    if store.restartTimer?.active == true {
                        Text("Neustart ist geplant.").foregroundStyle(.orange)
                        Button("Abbrechen", role: .destructive) { Task { await store.cancelRestartTimer() } }
                    } else {
                        Stepper("In \(Int(oneTimeMinutes)) min", value: $oneTimeMinutes, in: 0...180, step: 5)
                        Button("Neustart planen") { Task { await store.setRestartTimer(minutes: Int(oneTimeMinutes)) } }
                            .disabled(store.busyAction != nil)
                    }
                }

                Text("Hinweis: Eine Warnung im Spiel-Chat ist nicht möglich (Server-API bietet keine Broadcast-Funktion). Die Vorwarnung kommt per ntfy-Push.")
                    .font(.caption2).foregroundStyle(.secondary)

                if let s = store.actionStatus { Section { Text(s).foregroundStyle(.green).font(.footnote) } }
                if let e = store.lastError { Section { Text(e).foregroundStyle(.red).font(.footnote) } }
            }
        }
        .navigationTitle("Neustart-Zeitplan")
        .task {
            await store.fetchSchedule()
            if let s = store.schedule, !loaded {
                enabled = s.enabled
                timeDate = parse(s.time)
                skipIfPlayers = s.skipIfPlayers
                warnMinutes = Double(s.warnMinutes)
                loaded = true
            }
        }
    }

    private func hhmm(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
    private func parse(_ t: String) -> Date {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.date(from: t) ?? Date()
    }
}
