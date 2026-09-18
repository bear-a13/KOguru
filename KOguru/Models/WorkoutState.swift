//
//  WorkoutState.swift.swift
//  KOguru
//
//  Created by Bernardo on 01/09/26.
//
import Foundation
import CoreGraphics

enum WorkoutPhase: String, Codable, Hashable, Sendable {
    case framing
    case counting
    case finished
}

enum PunchType: String, Codable, CaseIterable, Hashable, Sendable {
    case none = "EM GUARDA"
    case jab = "JAB"
    case cross = "DIRETO"
}

enum Stance: String, Codable, CaseIterable, Hashable, Sendable {
    case orthodox
    case southpaw

    var displayName: String {
        switch self {
        case .orthodox:
            return "Ortodoxa"
        case .southpaw:
            return "Canhota"
        }
    }
}

struct BodyJoint: Identifiable {
    var id: String { name }

    let name: String
    let position: CGPoint
}
