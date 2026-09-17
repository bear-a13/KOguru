//
//  DrillResultsModel.swift
//  KOguru
//

import Foundation

struct DrillResultsModel: Identifiable, Hashable, Sendable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let combosCompleted: Int
    let correctPunches: Int
    let wrongPunches: Int

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        combosCompleted: Int,
        correctPunches: Int,
        wrongPunches: Int
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = max(endedAt, startedAt)
        self.combosCompleted = combosCompleted
        self.correctPunches = correctPunches
        self.wrongPunches = wrongPunches
    }

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }

    var totalPunches: Int {
        correctPunches + wrongPunches
    }

    var accuracy: Double {
        guard totalPunches > 0 else { return 0 }
        return Double(correctPunches) / Double(totalPunches)
    }
}