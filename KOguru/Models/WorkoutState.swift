//
//  WorkoutState.swift.swift
//  KOguru
//
//  Created by Bernardo on 01/09/26.
//
import Foundation
import CoreGraphics

enum WorkoutPhase {
    case framing
    case counting
    case finished
}

enum PunchType: String {
    case none = "EM GUARDA"
    case jab = "JAB"
    case direto = "DIRETO"
}

enum Stance {
    case orthodox
    case southpaw
}

struct BodyJoint: Identifiable {
    let id = UUID()
    let name: String
    let position: CGPoint
}
