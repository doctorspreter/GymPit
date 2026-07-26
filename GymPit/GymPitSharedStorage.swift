import Foundation

enum WorkoutPersistenceKeys {
    static let plan = "gympit_workout_plan_v1"
    static let routines = "gympit_routines_v1"
    static let defaultRoutineID = "gympit_default_routine_id_v1"
    static let history = "gympit_workout_history_v1"
    static let restEndDate = "gympit_rest_end_date_v1"
}

enum GymPitSharedStorage {
    static let appGroupID = "group.app.gympit"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func data(forKey key: String) -> Data? {
        defaults.data(forKey: key) ?? UserDefaults.standard.data(forKey: key)
    }

    static func string(forKey key: String) -> String? {
        defaults.string(forKey: key) ?? UserDefaults.standard.string(forKey: key)
    }

    static func set(_ value: Data, forKey key: String) {
        defaults.set(value, forKey: key)
        UserDefaults.standard.set(value, forKey: key)
    }

    static func set(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
        UserDefaults.standard.set(value, forKey: key)
    }

    static func date(forKey key: String) -> Date? {
        let timestamp = defaults.double(forKey: key)
        let fallbackTimestamp = UserDefaults.standard.double(forKey: key)
        let value = timestamp > 0 ? timestamp : fallbackTimestamp
        return value > 0 ? Date(timeIntervalSince1970: value) : nil
    }

    static func set(_ value: Date?, forKey key: String) {
        if let value {
            defaults.set(value.timeIntervalSince1970, forKey: key)
            UserDefaults.standard.set(value.timeIntervalSince1970, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
