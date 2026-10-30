import SwiftUI

struct ConnectView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "server.rack")
                    .font(.system(size: 54))
                    .foregroundStyle(.tint)
                Text("Satisfactory Server")
                    .font(.largeTitle.bold())
                Text("Server im WLAN suchen oder Adresse eingeben.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if store.isDiscovering {
                    ProgressView("Suche im WLAN …")
                }

                Button {
                    Task { await store.autoDiscover() }
                } label: {
                    Label("Automatisch im WLAN suchen", systemImage: "wifi")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(store.isDiscovering)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Manuell").font(.headline)
                        TextField("z. B. 192.168.178.99", text: $store.manualAddress)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        Button("Verbinden") {
                            Task { await store.connectManual() }
                        }
                        .buttonStyle(.glass)
                    }
                }

                if let err = store.lastError {
                    Text(err).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Verbinden")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
