import Foundation
import Vision
import CoreGraphics

struct PoseTrackingService {
    private let bodyMinimumConfidence: VNConfidence = 0.25
    private let leadWristMinimumConfidence: VNConfidence = 0.20
    private let rearWristMinimumConfidence: VNConfidence = 0.12
    private let smoothingFactor: CGFloat = 0.35
    private let maxLeadWristPredictionFrames = 3
    private let maxRearWristPredictionFrames = 6

    private var smoothedJointPositions: [String: CGPoint] = [:]
    private var trackedVisionPoints: [String: TrackedPoint] = [:]

    mutating func track(
        from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        stance: Stance
    ) -> [String: CGPoint] {
        let isLeftRearHand = stance == .southpaw
        let isRightRearHand = stance == .orthodox

        let jointConfigs: [JointConfig] = [
            JointConfig(label: "NK", name: .neck, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "LS", name: .leftShoulder, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "RS", name: .rightShoulder, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "LE", name: .leftElbow, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 1),
            JointConfig(label: "RE", name: .rightElbow, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 1),
            JointConfig(
                label: "LW",
                name: .leftWrist,
                minimumConfidence: isLeftRearHand ? rearWristMinimumConfidence : leadWristMinimumConfidence,
                maxPredictionFrames: isLeftRearHand ? maxRearWristPredictionFrames : maxLeadWristPredictionFrames
            ),
            JointConfig(
                label: "RW",
                name: .rightWrist,
                minimumConfidence: isRightRearHand ? rearWristMinimumConfidence : leadWristMinimumConfidence,
                maxPredictionFrames: isRightRearHand ? maxRearWristPredictionFrames : maxLeadWristPredictionFrames
            ),
            JointConfig(label: "LH", name: .leftHip, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "RH", name: .rightHip, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "LK", name: .leftKnee, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "RK", name: .rightKnee, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "LA", name: .leftAnkle, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "RA", name: .rightAnkle, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0)
        ]

        var trackedPoints: [String: CGPoint] = [:]

        for config in jointConfigs {
            trackedPoints[config.label] = trackedPoint(
                points[config.name],
                label: config.label,
                minimumConfidence: config.minimumConfidence,
                maxPredictionFrames: config.maxPredictionFrames
            )
        }

        return trackedPoints
    }

    mutating func buildJoints(
        from trackedPoints: [String: CGPoint],
        isMirrored: Bool
    ) -> [BodyJoint] {
        let orderedLabels = [
            "NK",
            "LS", "LW", "LE",
            "RS", "RW", "RE",
            "LH", "RH",
            "LK", "RK",
            "LA", "RA"
        ]

        return orderedLabels.compactMap { label in
            guard let point = trackedPoints[label] else { return nil }
            let mappedPoint = screenPoint(from: point, isMirrored: isMirrored)
            let smoothedPoint = smooth(point: mappedPoint, for: label)
            return BodyJoint(name: label, position: smoothedPoint)
        }
    }

    mutating func reset() {
        smoothedJointPositions.removeAll(keepingCapacity: true)
        trackedVisionPoints.removeAll(keepingCapacity: true)
    }

    private mutating func trackedPoint(
        _ point: VNRecognizedPoint?,
        label: String,
        minimumConfidence: VNConfidence,
        maxPredictionFrames: Int
    ) -> CGPoint? {
        if let point, point.confidence >= minimumConfidence {
            updateTrackedPoint(label: label, position: point.location)
            return point.location
        }

        guard maxPredictionFrames > 0,
              var track = trackedVisionPoints[label],
              track.missingFrames < maxPredictionFrames else {
            trackedVisionPoints.removeValue(forKey: label)
            return nil
        }

        let velocity = track.velocity
        let predictionStrength = label.hasSuffix("W")
            ? CGFloat(0.65)
            : CGFloat(0.35)

        let predictedPosition = CGPoint(
            x: WorkoutMath.clamp(
                track.position.x + velocity.dx * predictionStrength,
                min: 0,
                max: 1
            ),
            y: WorkoutMath.clamp(
                track.position.y + velocity.dy * predictionStrength,
                min: 0,
                max: 1
            )
        )

        track.previousPosition = track.position
        track.position = predictedPosition
        track.missingFrames += 1
        trackedVisionPoints[label] = track
        return predictedPosition
    }

    private mutating func updateTrackedPoint(label: String, position: CGPoint) {
        let previous = trackedVisionPoints[label]
        trackedVisionPoints[label] = TrackedPoint(
            position: position,
            previousPosition: previous?.position,
            missingFrames: 0
        )
    }

    private func screenPoint(
        from visionPoint: CGPoint,
        isMirrored: Bool
    ) -> CGPoint {
        CGPoint(
            x: isMirrored ? 1 - visionPoint.y : visionPoint.y,
            y: 1 - visionPoint.x
        )
    }

    private mutating func smooth(point: CGPoint, for key: String) -> CGPoint {
        guard let previous = smoothedJointPositions[key] else {
            smoothedJointPositions[key] = point
            return point
        }

        let smoothed = CGPoint(
            x: previous.x + (point.x - previous.x) * smoothingFactor,
            y: previous.y + (point.y - previous.y) * smoothingFactor
        )

        smoothedJointPositions[key] = smoothed
        return smoothed
    }
}

private struct JointConfig {
    let label: String
    let name: VNHumanBodyPoseObservation.JointName
    let minimumConfidence: VNConfidence
    let maxPredictionFrames: Int
}

private struct TrackedPoint {
    var position: CGPoint
    var previousPosition: CGPoint?
    var missingFrames: Int

    var velocity: CGVector {
        guard let previousPosition else {
            return CGVector(dx: 0, dy: 0)
        }

        return CGVector(
            dx: position.x - previousPosition.x,
            dy: position.y - previousPosition.y
        )
    }
}