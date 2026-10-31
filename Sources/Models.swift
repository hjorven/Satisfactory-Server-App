import Foundation

struct Overview: Codable {
    var running: Bool
    var status: String
    var cpu: Double?
    var ramMB: Double?
    var session: String?
    var paused: Bool?
    var power: Power
    var alerts: [Alert]
    var role: String?

    struct Power: Codable {
        var production: Int
        var consumption: Int
        var capacity: Int
        var circuits: Int
        var tripped: Int
    }

    struct Alert: Codable, Identifiable {
        var key: String
        var type: String
        var message: String
        var id: String { key }
    }
}

struct PowerCircuit: Codable, Identifiable {
    var CircuitGroupID: Int
    var PowerProduction: Double
    var PowerConsumed: Double
    var PowerCapacity: Double
    var BatteryPercent: Double?
    var BatteryCapacity: Double?
    var FuseTriggered: Bool

    var id: Int { CircuitGroupID }
}

struct PowerSample: Identifiable {
    let id = UUID()
    let time: Date
    let production: Double
    let consumption: Double
}

struct HealthResponse: Codable {
    var ok: Bool
    var configured: Bool
}

struct LoginResponse: Codable {
    var success: Bool?
    var role: String?
}
