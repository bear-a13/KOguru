import Foundation
import CoreGraphics

struct PunchClassifier {
    private let punchScoreThreshold: CGFloat = 0.74
    private let scoreDifferenceThreshold: CGFloat = 0.10
    private let requiredStableFrames = 2
    private let guardFramesBeforeReset = 4

    private var pendingPunch: PunchType = .none
    private var lastDetectedPunch: PunchType = .none
    private var stableFrameCount = 0
    private var guardFrameCount = 0

    mutating func detect(
        leftShoulder: CGPoint,
        leftElbow: CGPoint,
        leftWrist: CGPoint,
        rightShoulder: CGPoint,
        rightElbow: CGPoint,
        rightWrist: CGPoint,
        shoulderWidth: CGFloat,
        stance: Stance
    ) -> PunchType {
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

        return stabilize(detected)
    }

    mutating func stabilize(_ detected: PunchType) -> PunchType {
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

    mutating func reset() {
        pendingPunch = .none
        lastDetectedPunch = .none
        stableFrameCount = 0
        guardFrameCount = 0
    }

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