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

struct Player: Codable, Identifiable {
    var ID: String?
    var Name: String
    var Online: Bool
    var PlayerHP: Double?
    var Dead: Bool?
    var id: String { self.ID ?? Name }
}

struct SaveGame: Codable, Identifiable {
    var saveName: String
    var sessionName: String?
    var saveDateTime: String?
    var playDurationSeconds: Double?
    var isModdedSave: Bool?
    var id: String { saveName + (saveDateTime ?? "") }
}

struct SavesResponse: Codable {
    var saves: [SaveGame]
    var sessions: [String]?
}

struct BackupItem: Codable, Identifiable {
    var name: String
    var sizeMB: Double
    var modified: String
    var id: String { name }
}

struct BackupStatus: Codable {
    var lastRun: String?
    var localCount: Int?
    var nasOk: Bool?
    var nasCount: Int?
}

struct BackupsResponse: Codable {
    var backups: [BackupItem]
    var status: BackupStatus?
}

struct HealthResponse: Codable {
    var ok: Bool
    var configured: Bool
}

struct LoginResponse: Codable {
    var success: Bool?
    var role: String?
}
