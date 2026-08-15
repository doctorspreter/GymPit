//
//  HealthPitMetricIDs.swift
//  GymPit
//
//  ERZEUGT – NICHT BEARBEITEN.
//
//  Quelle: HealthPit, Healthpit/Core/MetricCatalog.swift
//  Neu erzeugen: python3 Scripts/export-metric-ids.py <ziel>
//
//  Diese Datei ist der Vertrag zwischen GymPit und HealthPit. Beide
//  benutzen dieselben Bezeichner, damit ein Wert unterwegs nicht
//  umbenannt werden muss und in HealthPit auf der richtigen Entitaet
//  landet.
//

import Foundation

/// Ein Wert, wie HealthPit ihn kennt.
struct HealthPitMetric: Hashable, Sendable {
    /// Die zentrale, dauerhaft stabile Kennung.
    let id: String
    /// Kanonische Einheit; `nil` bei Text-, Enum- und Ja/Nein-Werten.
    let unit: String?
    /// Klartext, wie HealthPit ihn fuehrt.
    let name: String
}

enum HealthPitMetricIDs {

    /// Distance
    static let actDistance = HealthPitMetric(id: "ACT_DISTANCE", unit: "M", name: "Distance")
    /// Cycling distance
    static let actDistanceCycling = HealthPitMetric(id: "ACT_DISTANCE_CYCLING", unit: "M", name: "Cycling distance")
    /// Downhill snow sports distance
    static let actDistanceSnowSports = HealthPitMetric(id: "ACT_DISTANCE_SNOW_SPORTS", unit: "M", name: "Downhill snow sports distance")
    /// Swimming distance
    static let actDistanceSwimming = HealthPitMetric(id: "ACT_DISTANCE_SWIMMING", unit: "M", name: "Swimming distance")
    /// Walking + running distance
    static let actDistanceWalkRun = HealthPitMetric(id: "ACT_DISTANCE_WALK_RUN", unit: "M", name: "Walking + running distance")
    /// Wheelchair distance
    static let actDistanceWheelchair = HealthPitMetric(id: "ACT_DISTANCE_WHEELCHAIR", unit: "M", name: "Wheelchair distance")
    /// Maximum heart rate
    static let hrtMaxRate = HealthPitMetric(id: "HRT_MAX_RATE", unit: "BPM", name: "Maximum heart rate")
    /// Heart rate
    static let hrtRate = HealthPitMetric(id: "HRT_RATE", unit: "BPM", name: "Heart rate")
    /// Active energy burned
    static let nrgActive = HealthPitMetric(id: "NRG_ACTIVE", unit: "KCAL", name: "Active energy burned")
    /// Total workout count
    static let wrkCountTotal = HealthPitMetric(id: "WRK_COUNT_TOTAL", unit: "CNT", name: "Total workout count")
    /// Workout distance
    static let wrkDistance = HealthPitMetric(id: "WRK_DISTANCE", unit: "M", name: "Workout distance")
    /// Workout duration
    static let wrkDuration = HealthPitMetric(id: "WRK_DURATION", unit: "S", name: "Workout duration")
    /// Workout energy burned
    static let wrkEnergy = HealthPitMetric(id: "WRK_ENERGY", unit: "KCAL", name: "Workout energy burned")
    /// Backrest setting
    static let wrkEquipmentBackrest = HealthPitMetric(id: "WRK_EQUIPMENT_BACKREST", unit: nil, name: "Backrest setting")
    /// Handle setting
    static let wrkEquipmentHandle = HealthPitMetric(id: "WRK_EQUIPMENT_HANDLE", unit: nil, name: "Handle setting")
    /// Equipment
    static let wrkEquipmentName = HealthPitMetric(id: "WRK_EQUIPMENT_NAME", unit: nil, name: "Equipment")
    /// Range setting
    static let wrkEquipmentRange = HealthPitMetric(id: "WRK_EQUIPMENT_RANGE", unit: nil, name: "Range setting")
    /// Seat setting
    static let wrkEquipmentSeat = HealthPitMetric(id: "WRK_EQUIPMENT_SEAT", unit: nil, name: "Seat setting")
    /// Exercise
    static let wrkExercise = HealthPitMetric(id: "WRK_EXERCISE", unit: nil, name: "Exercise")
    /// Workout injury note
    static let wrkInjury = HealthPitMetric(id: "WRK_INJURY", unit: nil, name: "Workout injury note")
    /// Workout route
    static let wrkRoute = HealthPitMetric(id: "WRK_ROUTE", unit: nil, name: "Workout route")
    /// Set is a personal record
    static let wrkSetIsPersonalRecord = HealthPitMetric(id: "WRK_SET_IS_PERSONAL_RECORD", unit: nil, name: "Set is a personal record")
    /// Repetitions
    static let wrkSetReps = HealthPitMetric(id: "WRK_SET_REPS", unit: "CNT", name: "Repetitions")
    /// Rate of perceived exertion
    static let wrkSetRpe = HealthPitMetric(id: "WRK_SET_RPE", unit: "SCORE", name: "Rate of perceived exertion")
    /// Set type
    static let wrkSetType = HealthPitMetric(id: "WRK_SET_TYPE", unit: nil, name: "Set type")
    /// Set volume
    static let wrkSetVolume = HealthPitMetric(id: "WRK_SET_VOLUME", unit: "KG", name: "Set volume")
    /// Set weight
    static let wrkSetWeight = HealthPitMetric(id: "WRK_SET_WEIGHT", unit: "KG", name: "Set weight")
    /// Workout sport type
    static let wrkSport = HealthPitMetric(id: "WRK_SPORT", unit: nil, name: "Workout sport type")
    /// Workout weather
    static let wrkWeather = HealthPitMetric(id: "WRK_WEATHER", unit: nil, name: "Workout weather")

    /// Alles, was GymPit liefern kann – fuer Pruefungen und Anzeigen.
    static let all: [HealthPitMetric] = [
        actDistance,
        actDistanceCycling,
        actDistanceSnowSports,
        actDistanceSwimming,
        actDistanceWalkRun,
        actDistanceWheelchair,
        hrtMaxRate,
        hrtRate,
        nrgActive,
        wrkCountTotal,
        wrkDistance,
        wrkDuration,
        wrkEnergy,
        wrkEquipmentBackrest,
        wrkEquipmentHandle,
        wrkEquipmentName,
        wrkEquipmentRange,
        wrkEquipmentSeat,
        wrkExercise,
        wrkInjury,
        wrkRoute,
        wrkSetIsPersonalRecord,
        wrkSetReps,
        wrkSetRpe,
        wrkSetType,
        wrkSetVolume,
        wrkSetWeight,
        wrkSport,
        wrkWeather,
    ]
}
