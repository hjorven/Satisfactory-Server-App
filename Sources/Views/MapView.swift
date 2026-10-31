import SwiftUI

struct MapView: View {
    @Environment(ServerStore.self) private var store
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var loading = false

    private let buildingColor = Color.orange.opacity(0.35)
    private let markerColor = Color.orange
    private let vehicleColor = Color.blue
    private let playerColor = Color(red: 0.72, green: 0.95, blue: 0.29)   // App-Akzent

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { ctx, size in draw(ctx, size: size) }
                    .scaleEffect(scale)
                    .offset(offset)
                    .contentShape(Rectangle())
                    .gesture(
                        SimultaneousGesture(
                            MagnifyGesture()
                                .onChanged { v in scale = clamp(lastScale * v.magnification) }
                                .onEnded { _ in lastScale = scale },
                            DragGesture()
                                .onChanged { v in offset = CGSize(width: lastOffset.width + v.translation.width,
                                                                  height: lastOffset.height + v.translation.height) }
                                .onEnded { _ in lastOffset = offset }
                        )
                    )
                    .onTapGesture(count: 2) { reset() }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .topLeading) { legend.padding(12) }
            .overlay {
                if isEmpty {
                    ContentUnavailableView {
                        Label("Keine Kartendaten", systemImage: "map")
                    } description: {
                        Text("Läuft der Server und ist FRM aktiv?")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if loading { ProgressView().padding(10).glassEffect(in: .circle).padding(12) }
            }
        }
        .padding()
        .navigationTitle("Karte")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { reset() } label: { Image(systemName: "scope") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
        .task { await load() }
    }

    // MARK: - Daten

    private struct P { var x: Double; var y: Double; var kind: Int; var label: String? }

    private var points: [P] {
        var out: [P] = []
        // Gebäude (gedünnt, damit die Karte nicht überladen wird)
        let b = store.mapBuildings.compactMap { $0.location }
        let step = max(1, b.count / 1500)
        var i = 0
        while i < b.count { out.append(P(x: b[i].x, y: b[i].y, kind: 0, label: nil)); i += step }
        // Marker
        for m in store.mapMarkers { if let l = m.location { out.append(P(x: l.x, y: l.y, kind: 1, label: nil)) } }
        // Fahrzeuge
        for v in store.vehicles { if let l = v.location { out.append(P(x: l.x, y: l.y, kind: 2, label: v.Name)) } }
        // Spieler (zuletzt = oben)
        for p in store.players { if let l = p.location { out.append(P(x: l.x, y: l.y, kind: 3, label: p.Name)) } }
        return out
    }

    private var isEmpty: Bool { points.isEmpty }

    private func load() async {
        loading = true
        await store.fetchMap()
        loading = false
    }

    private func clamp(_ v: CGFloat) -> CGFloat { min(10, max(0.6, v)) }
    private func reset() { withAnimation(.easeOut(duration: 0.25)) { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero } }

    // MARK: - Zeichnen

    private func draw(_ ctx: GraphicsContext, size: CGSize) {
        drawGrid(ctx, size: size)
        let pts = points
        guard !pts.isEmpty else { return }

        let xs = pts.map(\.x), ys = pts.map(\.y)
        var minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
        let padX = max(5000, (maxX - minX) * 0.08), padY = max(5000, (maxY - minY) * 0.08)
        minX -= padX; maxX += padX; minY -= padY; maxY += padY
        let w = max(1, maxX - minX), h = max(1, maxY - minY)
        let s = min(size.width / w, size.height / h)
        let ox = (size.width - w * s) / 2, oy = (size.height - h * s) / 2
        func proj(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: ox + (x - minX) * s, y: oy + (y - minY) * s)
        }

        for p in pts {
            let pt = proj(p.x, p.y)
            switch p.kind {
            case 0:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 1.5, y: pt.y - 1.5, width: 3, height: 3)),
                         with: .color(buildingColor))
            case 1:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)),
                         with: .color(markerColor))
            case 2:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 3.5, y: pt.y - 3.5, width: 7, height: 7)),
                         with: .color(vehicleColor))
            default:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 7, y: pt.y - 7, width: 14, height: 14)),
                         with: .color(.black.opacity(0.5)))
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)),
                         with: .color(playerColor))
                if let name = p.label {
                    ctx.draw(Text(name).font(.caption2.bold()).foregroundStyle(.white),
                             at: CGPoint(x: pt.x, y: pt.y - 14))
                }
            }
        }
    }

    private func drawGrid(_ ctx: GraphicsContext, size: CGSize) {
        var path = Path()
        let gap: CGFloat = 56
        var x: CGFloat = 0
        while x <= size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += gap }
        var y: CGFloat = 0
        while y <= size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += gap }
        ctx.stroke(path, with: .color(.white.opacity(0.06)), lineWidth: 1)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 5) {
            dot(playerColor, "Spieler")
            dot(markerColor, "Marker")
            dot(vehicleColor, "Fahrzeuge")
            dot(buildingColor, "Gebäude")
        }
        .font(.caption2)
        .padding(8)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }

    private func dot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 6) { Circle().fill(c).frame(width: 8, height: 8); Text(t) }
    }
}
