import Foundation

struct FocusConfiguration: Codable, Equatable {
    var focusDurationSec: Int
    var breakDurationSec: Int
    var sessionCount: Int
    var lastSessionDate: Date?
    var hourlyRate: Double

    static let defaultFocusSec = 1500
    static let defaultBreakSec = 300

    init(
        focusDurationSec: Int = FocusConfiguration.defaultFocusSec,
        breakDurationSec: Int = FocusConfiguration.defaultBreakSec,
        sessionCount: Int = 0,
        lastSessionDate: Date? = nil,
        hourlyRate: Double = 0
    ) {
        self.focusDurationSec = focusDurationSec
        self.breakDurationSec = breakDurationSec
        self.sessionCount = sessionCount
        self.lastSessionDate = lastSessionDate
        self.hourlyRate = hourlyRate
    }

    enum CodingKeys: String, CodingKey {
        case focusDurationSec, breakDurationSec, sessionCount, lastSessionDate, hourlyRate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        focusDurationSec = try c.decodeIfPresent(Int.self, forKey: .focusDurationSec) ?? FocusConfiguration.defaultFocusSec
        breakDurationSec = try c.decodeIfPresent(Int.self, forKey: .breakDurationSec) ?? FocusConfiguration.defaultBreakSec
        sessionCount = try c.decodeIfPresent(Int.self, forKey: .sessionCount) ?? 0
        lastSessionDate = try c.decodeIfPresent(Date.self, forKey: .lastSessionDate)
        hourlyRate = try c.decodeIfPresent(Double.self, forKey: .hourlyRate) ?? 0
    }
}

enum FocusTimerPhase: String {
    case idle
    case focus
    case breakTime
}
