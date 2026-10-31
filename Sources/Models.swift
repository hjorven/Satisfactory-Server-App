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

struct FRMLoc: Codable {
    var x: Double
    var y: Double
    var z: Double?
}

struct Player: Codable, Identifiable {
    var ID: String?
    var Name: String
    var Online: Bool
    var PlayerHP: Double?
    var Dead: Bool?
    var location: FRMLoc?
    var lastSeen: Double?   // ms seit Epoche, serverseitig getrackt
    var onlineMs: Double?   // akkumulierte Online-Zeit (ab Tracking-Start)
    var distanceM: Double?  // gelaufene Distanz in Metern (ab Tracking-Start)
    var id: String { self.ID ?? Name }
}

// #5 Karte
struct MapMarker: Codable {
    var Name: String?
    var location: FRMLoc?
    var MapMarkerType: String?
}
struct MapBuilding: Codable {
    var location: FRMLoc?
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

// #6 Produktion
struct ProdItem: Codable, Identifiable {
    var Name: String
    var ClassName: String?
    var CurrentProd: Double?
    var MaxProd: Double?
    var CurrentConsumed: Double?
    var MaxConsumed: Double?
    var ProdPercent: Double?
    var ConsPercent: Double?
    var itemType: String?
    var id: String { ClassName ?? Name }
    enum CodingKeys: String, CodingKey {
        case Name, ClassName, CurrentProd, MaxProd, CurrentConsumed, MaxConsumed, ProdPercent, ConsPercent
        case itemType = "Type"
    }
}

// #8 Transport (Züge/Fahrzeuge/Drohnen) – FRM-Felder sind je nach Aufbau unterschiedlich,
// daher alles optional.
struct TrainInfo: Codable {
    var Name: String?
    var Derailed: Bool?
    var Status: String?
    var Speed: Double?
    var TotalMass: Double?
}

struct VehicleInfo: Codable {
    var Name: String?
    var ClassName: String?
    var Speed: Double?
    var ForwardSpeed: Double?
    var AutoPilot: Bool?
    var location: FRMLoc?
}

struct DroneInfo: Codable {
    var Name: String?
    var HomeStation: String?
    var PairedStation: String?
    var CurrentFlyingMode: String?
    var FlyingSpeed: Double?
}

// #4 Mods
struct ModItem: Codable, Identifiable {
    var name: String
    var type: String
    var sizeMB: Double
    var id: String { name }
}
struct ModsResponse: Codable {
    var mods: [ModItem]
    var directoryExists: Bool?
}

// #2 Server-Einstellungen
struct ServerSettings: Codable {
    var autoPause: Bool
    var autoSaveOnDisconnect: Bool
    var autosaveInterval: Double
}

// Bonus: In-Game-Session
struct SessionInfo: Codable {
    var SessionName: String?
    var PassedDays: Int?
    var Hours: Int?
    var Minutes: Int?
    var IsDay: Bool?
    var TotalPlayDurationText: String?
    var NumberOfDaysSinceLastDeath: Int?
}

// #7 Host-Monitor
struct HostInfo: Codable {
    var uptimeSec: Double?
    var memTotalMB: Double?
    var memAvailMB: Double?
    var load1: Double?
    var load5: Double?
    var cpuCount: Int?
    var diskTotalGB: Double?
    var diskUsedGB: Double?
    var diskFreeGB: Double?
}

// #9 Alarm-Center
struct AlertConfig: Codable {
    var power: Bool
    var derail: Bool
    var playerJoin: Bool
    var playerLeave: Bool
    var serverDown: Bool
    var lowDisk: Bool
    var lowDiskGB: Double
}
struct AlertHistoryItem: Codable, Identifiable {
    var time: Double
    var type: String
    var message: String
    var id: String { "\(time)-\(message)" }
}
struct AlertHistoryResponse: Codable { var history: [AlertHistoryItem] }

// #3 Neustart-Zeitplan
struct RestartSchedule: Codable {
    var enabled: Bool
    var time: String
    var skipIfPlayers: Bool
    var warnMinutes: Int
}
struct RestartTimerState: Codable {
    var active: Bool
    var at: Double?
}

struct WorldStats: Codable {
    var buildings: Int?
    var totalPlayDuration: String?
    var passedDays: Int?
}

struct HealthResponse: Codable {
    var ok: Bool
    var configured: Bool
}

struct LoginResponse: Codable {
    var success: Bool?
    var role: String?
}
