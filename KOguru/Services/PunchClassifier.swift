import Foundation
import CoreGraphics

enum PunchFrame: Equatable {
    case none
    case hold(PunchType)
    case newPunch(PunchType)

    var punch: PunchType {
        switch self {
        case .none: return .none
        case .hold(let type): return type
        case .newPunch(let type): return type
        }
    }

    var shouldCount: Bool {
        if case .newPunch = self { return true }
        return false
    }
}

struct PunchClassifier {
    // MARK: - Parâmetros de detecção de golpe

    private let punchScoreThreshold: CGFloat = 0.74
    private let scoreDifferenceThreshold: CGFloat = 0.10
    private let requiredStableFrames = 2
    private let guardFramesBeforeReset = 4

    // MARK: - Parâmetros da guarda (regra do negativo)

    private let guardMaxElbowAngle: CGFloat = 135
    private let guardMaxWristDrop = 0.5
    private let guardMaxReach = 1.15

    // MARK: - Estado interno de estabilização

    private var pendingPunch: PunchType = .none
    private var lastDetectedPunch: PunchType = .none
    private var stableFrameCount = 0
    private var guardFrameCount = 0

    // MARK: - Gate de retorno à guarda

    private var awaitingReturnToGuard = true
    private var hasRegisteredPunch = false

    mutating func analyze(
        leftShoulder: CGPoint,
        leftElbow: CGPoint,
        leftWrist: CGPoint,
        rightShoulder: CGPoint,
        rightElbow: CGPoint,
        rightWrist: CGPoint,
        shoulderWidth: CGFloat,
        stance: Stance
    ) -> PunchFrame {
        let guarded = isInGuard(
            leftShoulder: leftShoulder,
            leftElbow: leftElbow,
            leftWrist: leftWrist,
            rightShoulder: rightShoulder,
            rightElbow: rightElbow,
            rightWrist: rightWrist,
            shoulderWidth: shoulderWidth
        )

        // Enquanto aguarda o retorno à guarda, nenhum novo golpe conta.
        if awaitingReturnToGuard {
            if guarded {
                awaitingReturnToGuard = false
                hasRegisteredPunch = false
                resetStabilization()
            } else {
                return .hold(lastDetectedPunch)
            }
        }

        let leftScore = armExtensionScore(
            shoulder: leftShoulder,
            elbow: leftElbow,
            wrist: leftWrist,
            shoulderWidth: shoulderWidth
        )

        let rightScore = armExtensionScore(
            shoulder: rightShoulder,
            elbow: rightElbow,
            wrist: rightWrist,
            shoulderWidth: shoulderWidth
        )

        let detected = classifyPunch(
            leftScore: leftScore,
            rightScore: rightScore,
            stance: stance
        )

        let stabilized = stabilize(detected)

        // Golpe não estabilizado: nada acontece.
        if stabilized == .none {
            return .none
        }

        // Mesmo golpe já registrado: continua exibindo, mas não conta de novo.
        if hasRegisteredPunch {
            return .hold(stabilized)
        }

        // Novo golpe vindo da guarda: registra e aguarda o retorno.
        hasRegisteredPunch = true
        awaitingReturnToGuard = true
        return .newPunch(stabilized)
    }

    mutating func loseTracking() -> PunchFrame {
        .none
    }

    mutating func reset() {
        pendingPunch = .none
        lastDetectedPunch = .none
        stableFrameCount = 0
        guardFrameCount = 0
        awaitingReturnToGuard = true
        hasRegisteredPunch = false
    }

    // MARK: - Guarda (regra do negativo)

    private func isInGuard(
        leftShoulder: CGPoint,
        leftElbow: CGPoint,
        leftWrist: CGPoint,
        rightShoulder: CGPoint,
        rightElbow: CGPoint,
        rightWrist: CGPoint,
        shoulderWidth: CGFloat
    ) -> Bool {
        armIsInGuard(
            shoulder: leftShoulder,
            elbow: leftElbow,
            wrist: leftWrist,
            shoulderWidth: shoulderWidth
        ) && armIsInGuard(
            shoulder: rightShoulder,
            elbow: rightElbow,
            wrist: rightWrist,
            shoulderWidth: shoulderWidth
        )
    }

    private func armIsInGuard(
        shoulder: CGPoint,
        elbow: CGPoint,
        wrist: CGPoint,
        shoulderWidth: CGFloat
    ) -> Bool {
        let elbowAngle = WorkoutMath.jointAngle(shoulder, elbow, wrist)
        let isElbowBent = elbowAngle <= guardMaxElbowAngle
        let wristDrop = wrist.y - shoulder.y
        let isWristHigh = wristDrop <= shoulderWidth * guardMaxWristDrop
        let isFolded = WorkoutMath.distance(shoulder, wrist)
            <= shoulderWidth * guardMaxReach
        return isElbowBent && isWristHigh && isFolded
    }

    // MARK: - Estabilização

    private mutating func stabilize(_ detected: PunchType) -> PunchType {
        if detected == .none {
            guardFrameCount += 1
            stableFrameCount = 0
            pendingPunch = .none
            lastDetectedPunch = guardFrameCount >= guardFramesBeforeReset
                ? .none
                : lastDetectedPunch
            return lastDetectedPunch
        }

        guardFrameCount = 0

        if detected == pendingPunch {
            stableFrameCount += 1
        } else {
            pendingPunch = detected
            stableFrameCount = 1
        }

        lastDetectedPunch = stableFrameCount >= requiredStableFrames
            ? detected
            : lastDetectedPunch
        return lastDetectedPunch
    }

    private mutating func resetStabilization() {
        pendingPunch = .none
        lastDetectedPunch = .none
        stableFrameCount = 0
        guardFrameCount = 0
    }

    // MARK: - Classificação biomecânica

    private func armExtensionScore(
        shoulder: CGPoint,
        elbow: CGPoint,
        wrist: CGPoint,
        shoulderWidth: CGFloat
    ) -> CGFloat {
        let angle = WorkoutMath.jointAngle(shoulder, elbow, wrist)
        let elbowStraightness = WorkoutMath.clamp((angle - 100) / 65, min: 0, max: 1)
        let reach = WorkoutMath.clamp(
            WorkoutMath.distance(shoulder, wrist) / (shoulderWidth * 1.3),
            min: 0,
            max: 1
        )
        let heightDifference = wrist.y - shoulder.y
        let lowHandPenalty = WorkoutMath.clamp(
            (heightDifference - (shoulderWidth * 0.3)) / shoulderWidth,
            min: 0,
            max: 0.4
        )
        let score = (elbowStraightness * 0.60)
            + (reach * 0.40)
            - lowHandPenalty
        return max(score, 0)
    }

    private func classifyPunch(
        leftScore: CGFloat,
        rightScore: CGFloat,
        stance: Stance
    ) -> PunchType {
        let leadScore = stance == .orthodox ? leftScore : rightScore
        let rearScore = stance == .orthodox ? rightScore : leftScore

        guard max(leadScore, rearScore) >= punchScoreThreshold else {
            return .none
        }

        if leadScore - rearScore > scoreDifferenceThreshold {
            return .jab
        }

        if rearScore - leadScore > scoreDifferenceThreshold {
            return .cross
        }

        return .none
    }
}