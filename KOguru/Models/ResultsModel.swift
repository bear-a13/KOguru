//
//  ResultsModel.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 08/09/26.
//

import Foundation

enum PunchSpeedUnit: String, Codable, Sendable {
    case shoulderWidthsPerSecond
    case metersPerSecond
    
    var symbol: String {
        switch self {
        case .shoulderWidthsPerSecond:
            return "m/s"
        case .metersPerSecond:
            return "m/s"
        }
    }
    
    var description: String {
        switch self {
        case .shoulderWidthsPerSecond:
            return "Largura de ombro por segundo"
        case .metersPerSecond:
            return "Metros por segundo"
        }
    }
}

struct PunchEvaluation: Codable, Hashable, Sendable {
    let expectedType: PunchType?
    let classifierConfidence: Double?
    let guardHandMaintained: Bool?
    let returnedToGuard: Bool?
    let techniqueScore: Double?
    
    init(
        expectedType: PunchType? = nil,
        classifierConfidence: Double? = nil,
        guardHandMaintained: Bool? = nil,
        returnedToGuard: Bool? = nil,
        techniqueScore: Double? = nil
    ) {
        self.expectedType = expectedType
        self.classifierConfidence = classifierConfidence
        self.guardHandMaintained = guardHandMaintained
        self.returnedToGuard = returnedToGuard
        self.techniqueScore = techniqueScore
    }
}


struct PunchResult: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let type: PunchType
    let timestamp: TimeInterval
    let peakSpeed: Double
    let duration: TimeInterval?
    let evaluation: PunchEvaluation?
    
    init(
        id: UUID = UUID(),
        type: PunchType,
        timestamp: TimeInterval,
        peakSpeed: Double,
        duration: TimeInterval? = nil,
        evaluation: PunchEvaluation? = nil
    ){
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.peakSpeed = peakSpeed
        self.duration = duration
        self.evaluation = evaluation
    }
}


struct ResultsModel: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let stance: Stance
    let speedUnit: PunchSpeedUnit
    let punches: [PunchResult]

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        stance: Stance,
        speedUnit: PunchSpeedUnit = .shoulderWidthsPerSecond,
        punches: [PunchResult]
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = max(endedAt, startedAt)
        self.stance = stance
        self.speedUnit = speedUnit
        self.punches = punches.filter { $0.type != .none }
    }

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }

    var totalPunches: Int {
        punches.count
    }

    var jabCount: Int {
        count(for: .jab)
    }

    var crossCount: Int {
        count(for: .cross)
    }

    var averageSpeed: Double {
        guard !punches.isEmpty else { return 0 }
        return punches.reduce(0) { $0 + $1.peakSpeed } / Double(punches.count)
    }

    var maximumSpeed: Double {
        fastestPunch?.peakSpeed ?? 0
    }

    var fastestPunch: PunchResult? {
        punches.max { $0.peakSpeed < $1.peakSpeed }
    }

    var averagePunchDuration: TimeInterval? {
        let durations = punches.compactMap(\.duration)
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    var averageTechniqueScore: Double? {
        average(of: punches.compactMap { $0.evaluation?.techniqueScore })
    }

    var guardSuccessRate: Double? {
        rate(of: punches.compactMap { $0.evaluation?.guardHandMaintained })
    }

    var returnToGuardRate: Double? {
        rate(of: punches.compactMap { $0.evaluation?.returnedToGuard })
    }

    var classificationAccuracy: Double? {
        let comparisons = punches.compactMap { punch -> Bool? in
            guard let expected = punch.evaluation?.expectedType,
                  expected != .none else {
                return nil
            }
            return expected == punch.type
        }

        return rate(of: comparisons)
    }

    func count(for type: PunchType) -> Int {
        punches.lazy.filter { $0.type == type }.count
    }

    private func average(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func rate(of values: [Bool]) -> Double? {
        guard !values.isEmpty else { return nil }
        let successes = values.lazy.filter { $0 }.count
        return Double(successes) / Double(values.count)
    }
}
