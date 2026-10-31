import SwiftUI

struct MapView: View {
    @Environment(ServerStore.self) private var store
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var loading = false
    @State private var framed = false

    // Welt-Grenzen (cm) – entsprechen der quadratischen 5000×5000 In-Game-Karte
    private let minX = -324698.832, maxX = 425301.832
    private let minY = -375000.0, maxY = 375000.0

    private let buildingColor = Color.orange.opacity(0.9)
    private let markerColor = Color.white
    private let vehicleColor = Color.cyan
    private let playerColor = Color(red: 0.72, green: 0.95, blue: 0.29)

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                ZStack {
                    Image("worldmap")
                        .resizable()
                        .frame(width: side, height: side)
                    Canvas { ctx, size in draw(ctx, size: size) }
                        .frame(width: side, height: side)
                }
                .scaleEffect(scale)
                .offset(offset)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contentShape(Rectangle())
            .highPriorityGesture(
                MagnifyGesture()
                    .onChanged { v in
                        let s1 = clamp(lastScale * v.magnification)
                        let r = s1 / lastScale
                        let ax = v.startAnchor.x * geo.size.width - geo.size.width / 2
                        let ay = v.startAnchor.y * geo.size.height - geo.size.height / 2
                        scale = s1
                        offset = CGSize(width: ax * (1 - r) + lastOffset.width * r,
                                        height: ay * (1 - r) + lastOffset.height * r)
                    }
                    .onEnded { _ in lastScale = scale; lastOffset = offset }
            )
            .gesture(
                DragGesture()
                    .onChanged { offset = CGSize(width: lastOffset.width + $0.translation.width,
                                                 height: lastOffset.height + $0.translation.height) }
                    .onEnded { _ in lastOffset = offset }
            )
            .onTapGesture(count: 2) { withAnimation(.easeOut(duration: 0.25)) { frameBase(side: side) } }
            .overlay(alignment: .topLeading) { legend.padding(12) }
            .overlay(alignment: .bottomTrailing) {
                if loading { ProgressView().padding(10).glassEffect(in: .circle).padding(12) }
            }
            .task {
                await load()
                if !framed { frameBase(side: side); framed = true }
            }
        }
        .padding()
        .navigationTitle("Karte")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
    }

    // MARK: - Punkte

    private struct P { var x: Double; var y: Double; var kind: Int; var label: String? }

    private var points: [P] {
        var out: [P] = []
        let b = store.mapBuildings.compactMap { $0.location }
        let step = max(1, b.count / 2000)
        var i = 0
        while i < b.count { out.append(P(x: b[i].x, y: b[i].y, kind: 0, label: nil)); i += step }
        for m in store.mapMarkers { if let l = m.location { out.append(P(x: l.x, y: l.y, kind: 1, label: nil)) } }
        for v in store.vehicles { if let l = v.location { out.append(P(x: l.x, y: l.y, kind: 2, label: v.Name)) } }
        for p in store.players { if let l = p.location { out.append(P(x: l.x, y: l.y, kind: 3, label: p.Name)) } }
        return out
    }

    private func nx(_ x: Double) -> Double { (x - minX) / (maxX - minX) }
    private func ny(_ y: Double) -> Double { (y - minY) / (maxY - minY) }

    private func load() async {
        loading = true
        await store.fetchMap()
        loading = false
    }

    private func clamp(_ v: CGFloat) -> CGFloat { min(14, max(0.8, v)) }

    /// Zentriert & zoomt auf die vorhandenen Objekte (Basis).
    private func frameBase(side: CGFloat) {
        let pts = points
        guard !pts.isEmpty else { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero; return }
        let xsN = pts.map { nx($0.x) }, ysN = pts.map { ny($0.y) }
        let cx = (xsN.min()! + xsN.max()!) / 2, cy = (ysN.min()! + ysN.max()!) / 2
        let span = max(xsN.max()! - xsN.min()!, ysN.max()! - ysN.min()!, 0.03)
        let s = min(14, max(1, 0.6 / span))
        scale = s; lastScale = s
        offset = CGSize(width: -(cx - 0.5) * side * s, height: -(cy - 0.5) * side * s)
        lastOffset = offset
    }

    // MARK: - Zeichnen

    private func draw(_ ctx: GraphicsContext, size: CGSize) {
        for p in points {
            let pt = CGPoint(x: nx(p.x) * size.width, y: ny(p.y) * size.height)
            switch p.kind {
            case 0:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 1.3, y: pt.y - 1.3, width: 2.6, height: 2.6)),
                         with: .color(buildingColor))
            case 1:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)),
                         with: .color(markerColor))
                ctx.stroke(Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)),
                           with: .color(.black.opacity(0.6)), lineWidth: 1)
            case 2:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 3.5, y: pt.y - 3.5, width: 7, height: 7)),
                         with: .color(vehicleColor))
            default:
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 7, y: pt.y - 7, width: 14, height: 14)),
                         with: .color(.black.opacity(0.6)))
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)),
                         with: .color(playerColor))
                if let name = p.label {
                    ctx.draw(Text(name).font(.system(size: 9, weight: .bold)).foregroundStyle(.white),
                             at: CGPoint(x: pt.x, y: pt.y - 13))
                }
            }
        }
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
