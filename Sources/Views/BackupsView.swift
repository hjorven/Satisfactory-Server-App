import SwiftUI

struct BackupsView: View {
    @Environment(ServerStore.self) private var store
    @State private var toRestore: BackupItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !store.isAdmin {
                    GlassCard {
                        Label("Nur für Admins. Unter Einstellungen mit dem Admin-Passwort anmelden.",
                              systemImage: "info.circle")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("STATUS").font(.caption2).foregroundStyle(.secondary)
                            StatusRow(label: "Lokale Backups", value: "\(store.backupStatus?.localCount ?? store.backups.count)")
                            StatusRow(label: "NAS", value: store.backupStatus?.nasOk == true
                                      ? "OK (\(store.backupStatus?.nasCount ?? 0))" : "nicht erreichbar")
                            if let lr = store.backupStatus?.lastRun, !lr.isEmpty {
                                StatusRow(label: "Letzter Lauf", value: lr)
                            }
                            Button { Task { await store.runBackup() } } label: {
                                Label("Jetzt sichern", systemImage: "externaldrive.fill.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminent).disabled(store.busyAction != nil)
                        }
                    }

                    if store.busyAction != nil, let s = store.actionStatus {
                        GlassCard { HStack(spacing: 10) { ProgressView(); Text(s).font(.subheadline) } }
                    } else if let s = store.actionStatus {
                        Label(s, systemImage: "checkmark.circle.fill")
                            .font(.footnote).foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(store.backups) { b in backupCard(b) }
                }

                if let e = store.lastError {
                    Label(e, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote).foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Backups")
        .task { if store.isAdmin { await store.fetchBackups() } }
        .refreshable { await store.fetchBackups() }
        .confirmationDialog("Backup wiederherstellen? Der Server wird gestoppt, der aktuelle Stand gesichert und ersetzt.",
                            isPresented: restoreBinding, presenting: toRestore) { b in
            Button("Wiederherstellen", role: .destructive) { Task { await store.restoreBackup(b.name) } }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private func backupCard(_ b: BackupItem) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(prettyName(b.name)).font(.subheadline.weight(.semibold))
                HStack {
                    Text("\(String(format: "%.1f", b.sizeMB)) MB")
                    Spacer()
                    Text(prettyDate(b.modified))
                }
                .font(.caption).foregroundStyle(.secondary)
                Button(role: .destructive) { toRestore = b } label: {
                    Label("Wiederherstellen", systemImage: "arrow.counterclockwise.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass).disabled(store.busyAction != nil)
            }
        }
    }

    private var restoreBinding: Binding<Bool> {
        Binding(get: { toRestore != nil }, set: { if !$0 { toRestore = nil } })
    }

    // "saves_2026-10-31_061543.tar.gz" -> "31.10.2026 06:15:43"
    private func prettyName(_ name: String) -> String {
        let core = name.replacingOccurrences(of: "saves_", with: "").replacingOccurrences(of: ".tar.gz", with: "")
        let parts = core.split(separator: "_")
        guard parts.count == 2 else { return name }
        let d = parts[0].split(separator: "-")
        let t = parts[1]
        guard d.count == 3, t.count == 6 else { return name }
        let hh = t.prefix(2), mm = t.dropFirst(2).prefix(2), ss = t.dropFirst(4).prefix(2)
        return "\(d[2]).\(d[1]).\(d[0])  \(hh):\(mm):\(ss)"
    }

    private func prettyDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        guard let date else { return "" }
        let out = DateFormatter()
        out.dateFormat = "dd.MM. HH:mm"
        return out.string(from: date)
    }
}
