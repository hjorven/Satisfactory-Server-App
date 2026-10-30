import Foundation
import Network

/// Findet den Server per Bonjour (_satisctl._tcp) im lokalen Netz.
@MainActor
final class Discovery {
    private var browser: NWBrowser?

    func findServer(timeout: TimeInterval = 5) async -> URL? {
        await withCheckedContinuation { (cont: CheckedContinuation<URL?, Never>) in
            var finished = false
            let params = NWParameters.tcp
            params.includePeerToPeer = false
            let browser = NWBrowser(for: .bonjour(type: "_satisctl._tcp", domain: nil), using: params)
            self.browser = browser

            func finish(_ url: URL?) {
                if finished { return }
                finished = true
                browser.cancel()
                cont.resume(returning: url)
            }

            browser.browseResultsChangedHandler = { results, _ in
                guard let result = results.first else { return }
                let connection = NWConnection(to: result.endpoint, using: .tcp)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        if case let .hostPort(host, port)? = connection.currentPath?.remoteEndpoint {
                            var h = "\(host)"
                            if let idx = h.firstIndex(of: "%") { h = String(h[..<idx]) }
                            let hostPart = h.contains(":") ? "[\(h)]" : h
                            let url = URL(string: "http://\(hostPart):\(port.rawValue)")
                            connection.cancel()
                            finish(url)
                        }
                    case .failed, .cancelled:
                        connection.cancel()
                    default:
                        break
                    }
                }
                connection.start(queue: .main)
            }

            browser.start(queue: .main)
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { finish(nil) }
        }
    }
}
