import SwiftUI
import Foundation
import Vision
import CoreGraphics
import AVFoundation
import Combine
import ImageIO

final class WorkoutViewModel: ObservableObject, @unchecked Sendable {
    // MARK: - Propriedades publicadas para a interface

    @Published var currentPhase: WorkoutPhase = .framing
    @Published var punchCount: Int = 0
    @Published var isProperlyFramed: Bool = false
    @Published var framingProgress: Double = 0
    @Published var lastDetectedPunch: PunchType = .none
    @Published var lastPunchSpeed: Double?
    @Published var userStance: Stance = .orthodox
    @Published var bodyJoints: [BodyJoint] = []
    @Published private(set) var punchResults: [PunchResult] = []

    // MARK: - Parâmetros originais calibrados para o ângulo de 45 graus

    private let bodyMinimumConfidence: VNConfidence = 0.25
    private let leadWristMinimumConfidence: VNConfidence = 0.20
    private let rearWristMinimumConfidence: VNConfidence = 0.12
    private let punchScoreThreshold: CGFloat = 0.74
    private let scoreDifferenceThreshold: CGFloat = 0.10
    private let smoothingFactor: CGFloat = 0.35
    private let requiredStableFrames = 2
    private let guardFramesBeforeReset = 4
    private let maxLeadWristPredictionFrames = 3
    private let maxRearWristPredictionFrames = 6

    private let speedWindowSize = 8
    private let maximumPlausibleSpeed = 25.0

    // MARK: - Estado interno original de rastreamento e estabilização

    private var smoothedJointPositions: [String: CGPoint] = [:]
    private var trackedVisionPoints: [String: TrackedPoint] = [:]
    private var pendingPunch: PunchType = .none
    private var stableFrameCount = 0
    private var guardFrameCount = 0
    private var hasRegisteredCurrentPunch = false

    // MARK: - Estado adicional usado somente para os resultados

    private var workoutStartedAt: Date?
    private var workoutSampleStartTimestamp: TimeInterval?
    private var previousLeftWrist: CGPoint?
    private var previousRightWrist: CGPoint?
    private var previousSpeedTimestamp: TimeInterval?
    private var recentLeftSpeeds: [Double] = []
    private var recentRightSpeeds: [Double] = []
    private var speedTrackingHadActivePunch = false

    // MARK: - API pública

    func setStance(_ stance: Stance) {
        guard currentPhase == .framing else { return }
        userStance = stance
    }

    // MARK: - Processamento principal original

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let frameTimestamp = CMTimeGetSeconds(presentationTime)
        let validTimestamp = frameTimestamp.isFinite
            ? frameTimestamp
            : Date().timeIntervalSinceReferenceDate

        let request = VNDetectHumanBodyPoseRequest { [weak self] request, _ in
            guard let self else { return }

            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let body = observations.first else {
                if self.currentPhase == .framing {
                    DispatchQueue.main.async {
                        self.isProperlyFramed = false
                        self.framingProgress = 0
                    }
                }
                return
            }

            switch self.currentPhase {
            case .framing:
                self.checkFraming(body: body, timestamp: validTimestamp)
            case .counting:
                self.analyzePose(
                    body,
                    isMirrored: true,
                    timestamp: validTimestamp
                )
            case .finished:
                break
            }
        }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .upMirrored,
            options: [:]
        )
        try? handler.perform([request])
    }

    // MARK: - Fase 1: enquadramento original

    private func checkFraming(
        body: VNHumanBodyPoseObservation,
        timestamp: TimeInterval
    ) {
        let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose,
            .leftShoulder,
            .rightShoulder,
            .leftWrist,
            .rightWrist,
            .leftAnkle,
            .rightAnkle
        ]

        var allVisible = true

        for joint in requiredJoints {
            if let point = try? body.recognizedPoint(joint),
               point.confidence > 0.3 {
                continue
            }

            allVisible = false
            break
        }

        // Só marca o início dos resultados. A regra que inicia o treino
        // continua sendo exatamente a do código anterior.
        if allVisible, workoutStartedAt == nil {
            workoutStartedAt = Date()
            workoutSampleStartTimestamp = timestamp
        }

        DispatchQueue.main.async {
            self.isProperlyFramed = allVisible
            self.framingProgress = allVisible ? 1 : 0

            if allVisible {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.currentPhase = .counting
                }
            }
        }
    }

    // MARK: - Fase 2: análise de pose e detecção original

    private func analyzePose(
        _ body: VNHumanBodyPoseObservation,
        isMirrored: Bool,
        timestamp: TimeInterval
    ) {
        guard let points = try? body.recognizedPoints(.all) else { return }

        let trackedPoints = buildTrackedPoints(from: points)
        let joints = buildBodyJoints(
            from: trackedPoints,
            isMirrored: isMirrored
        )

        guard let leftShoulder = trackedPoints["LS"],
              let leftWrist = trackedPoints["LW"],
              let leftElbow = trackedPoints["LE"],
              let rightShoulder = trackedPoints["RS"],
              let rightWrist = trackedPoints["RW"],
              let rightElbow = trackedPoints["RE"] else {
            let finalPunch = stabilizedPunch(from: .none)
            publish(
                detected: finalPunch,
                joints: joints,
                detectedSpeed: nil,
                timestamp: timestamp
            )
            updateSpeedWindowState(after: finalPunch)
            return
        }

        let shoulderWidth = max(distance(leftShoulder, rightShoulder), 0.12)

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

        // A velocidade é paralela: não altera classificação ou estabilização.
        updateSpeedMeasurements(
            leftWrist: leftWrist,
            rightWrist: rightWrist,
            shoulderWidth: shoulderWidth,
            timestamp: timestamp
        )

        let detected = classifyPunch(
            leftScore: leftScore,
            rightScore: rightScore
        )
        let finalPunch = stabilizedPunch(from: detected)
        let detectedSpeed = speedForPunch(finalPunch)

        publish(
            detected: finalPunch,
            joints: joints,
            detectedSpeed: detectedSpeed,
            timestamp: timestamp
        )

        updateSpeedWindowState(after: finalPunch)
    }

    // MARK: - Rastreamento e previsão de pontos ocultos original

    private func buildTrackedPoints(
        from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> [String: CGPoint] {
        let isLeftRearHand = userStance == .southpaw
        let isRightRearHand = userStance == .orthodox

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

    private func trackedPoint(
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
            x: clamp(
                track.position.x + velocity.dx * predictionStrength,
                min: 0,
                max: 1
            ),
            y: clamp(
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

    private func updateTrackedPoint(label: String, position: CGPoint) {
        let previous = trackedVisionPoints[label]
        trackedVisionPoints[label] = TrackedPoint(
            position: position,
            previousPosition: previous?.position,
            missingFrames: 0
        )
    }

    private func buildBodyJoints(
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

    // MARK: - Algoritmo biomecânico original

    private func armExtensionScore(
        shoulder: CGPoint,
        elbow: CGPoint,
        wrist: CGPoint,
        shoulderWidth: CGFloat
    ) -> CGFloat {
        let angle = jointAngle(shoulder, elbow, wrist)
        let elbowStraightness = clamp((angle - 100) / 65, min: 0, max: 1)
        let reach = clamp(
            distance(shoulder, wrist) / (shoulderWidth * 1.3),
            min: 0,
            max: 1
        )
        let heightDifference = wrist.y - shoulder.y
        let lowHandPenalty = clamp(
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
        rightScore: CGFloat
    ) -> PunchType {
        let leadScore = userStance == .orthodox ? leftScore : rightScore
        let rearScore = userStance == .orthodox ? rightScore : leftScore

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

    private func stabilizedPunch(from detected: PunchType) -> PunchType {
        if detected == .none {
            guardFrameCount += 1
            stableFrameCount = 0
            pendingPunch = .none
            return guardFrameCount >= guardFramesBeforeReset
                ? .none
                : lastDetectedPunch
        }

        guardFrameCount = 0

        if detected == pendingPunch {
            stableFrameCount += 1
        } else {
            pendingPunch = detected
            stableFrameCount = 1
        }

        return stableFrameCount >= requiredStableFrames
            ? detected
            : lastDetectedPunch
    }

    // MARK: - Publicação original + registro de resultado

    private func publish(
        detected: PunchType,
        joints: [BodyJoint],
        detectedSpeed: Double?,
        timestamp: TimeInterval
    ) {
        let relativeTimestamp = max(
            timestamp - (workoutSampleStartTimestamp ?? timestamp),
            0
        )

        DispatchQueue.main.async {
            // Mantém exatamente a condição do contador antigo.
            if detected != .none && !self.hasRegisteredCurrentPunch {
                let speed = detectedSpeed ?? 0

                self.punchCount += 1
                self.hasRegisteredCurrentPunch = true
                self.lastPunchSpeed = speed
                self.punchResults.append(
                    PunchResult(
                        type: detected,
                        timestamp: relativeTimestamp,
                        peakSpeed: speed,
                        duration: nil,
                        evaluation: nil
                    )
                )
            } else if detected == .none {
                self.hasRegisteredCurrentPunch = false
            }

            self.lastDetectedPunch = detected
            self.bodyJoints = joints
        }
    }

    // MARK: - Velocidade relativa usada somente nos resultados

    private func updateSpeedMeasurements(
        leftWrist: CGPoint,
        rightWrist: CGPoint,
        shoulderWidth: CGFloat,
        timestamp: TimeInterval
    ) {
        defer {
            previousLeftWrist = leftWrist
            previousRightWrist = rightWrist
            previousSpeedTimestamp = timestamp
        }

        guard let previousLeftWrist,
              let previousRightWrist,
              let previousSpeedTimestamp else {
            return
        }

        let deltaTime = timestamp - previousSpeedTimestamp
        guard deltaTime > 0.001, deltaTime < 0.25 else { return }

        let leftSpeed = plausibleSpeed(
            Double(distance(leftWrist, previousLeftWrist) / shoulderWidth)
                / deltaTime
        )
        let rightSpeed = plausibleSpeed(
            Double(distance(rightWrist, previousRightWrist) / shoulderWidth)
                / deltaTime
        )

        appendRolling(leftSpeed, to: &recentLeftSpeeds)
        appendRolling(rightSpeed, to: &recentRightSpeeds)
    }

    private func speedForPunch(_ punch: PunchType) -> Double? {
        guard punch != .none else { return nil }

        let usesLeftHand: Bool

        switch (userStance, punch) {
        case (.orthodox, .jab), (.southpaw, .cross):
            usesLeftHand = true
        case (.orthodox, .cross), (.southpaw, .jab):
            usesLeftHand = false
        case (_, .none):
            return nil
        }

        return usesLeftHand
            ? recentLeftSpeeds.max()
            : recentRightSpeeds.max()
    }

    private func updateSpeedWindowState(after punch: PunchType) {
        if punch != .none {
            speedTrackingHadActivePunch = true
            return
        }

        guard speedTrackingHadActivePunch else { return }
        speedTrackingHadActivePunch = false
        recentLeftSpeeds.removeAll(keepingCapacity: true)
        recentRightSpeeds.removeAll(keepingCapacity: true)
    }

    private func plausibleSpeed(_ speed: Double) -> Double {
        guard speed.isFinite,
              speed >= 0,
              speed <= maximumPlausibleSpeed else {
            return 0
        }
        return speed
    }

    private func appendRolling(_ value: Double, to values: inout [Double]) {
        values.append(value)
        if values.count > speedWindowSize {
            values.removeFirst(values.count - speedWindowSize)
        }
    }

    // MARK: - Funções de apoio biomecânico originais

    private func screenPoint(
        from visionPoint: CGPoint,
        isMirrored: Bool
    ) -> CGPoint {
        CGPoint(
            x: isMirrored ? 1 - visionPoint.y : visionPoint.y,
            y: 1 - visionPoint.x
        )
    }

    private func smooth(point: CGPoint, for key: String) -> CGPoint {
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

    private func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    private func jointAngle(
        _ first: CGPoint,
        _ middle: CGPoint,
        _ last: CGPoint
    ) -> CGFloat {
        let firstVector = CGVector(
            dx: first.x - middle.x,
            dy: first.y - middle.y
        )
        let secondVector = CGVector(
            dx: last.x - middle.x,
            dy: last.y - middle.y
        )
        let dotProduct = firstVector.dx * secondVector.dx
            + firstVector.dy * secondVector.dy
        let firstMagnitude = hypot(firstVector.dx, firstVector.dy)
        let secondMagnitude = hypot(secondVector.dx, secondVector.dy)

        guard firstMagnitude > 0, secondMagnitude > 0 else { return 0 }

        let cosine = clamp(
            dotProduct / (firstMagnitude * secondMagnitude),
            min: -1,
            max: 1
        )
        return acos(cosine) * 180 / .pi
    }

    private func clamp(
        _ value: CGFloat,
        min minimum: CGFloat,
        max maximum: CGFloat
    ) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    // MARK: - Reinício e finalização

    func resetWorkout() {
        punchCount = 0
        currentPhase = .framing
        isProperlyFramed = false
        framingProgress = 0
        lastDetectedPunch = .none
        lastPunchSpeed = nil
        bodyJoints = []
        punchResults = []

        smoothedJointPositions.removeAll(keepingCapacity: true)
        trackedVisionPoints.removeAll(keepingCapacity: true)
        pendingPunch = .none
        stableFrameCount = 0
        guardFrameCount = 0
        hasRegisteredCurrentPunch = false

        workoutStartedAt = nil
        workoutSampleStartTimestamp = nil
        previousLeftWrist = nil
        previousRightWrist = nil
        previousSpeedTimestamp = nil
        recentLeftSpeeds.removeAll(keepingCapacity: true)
        recentRightSpeeds.removeAll(keepingCapacity: true)
        speedTrackingHadActivePunch = false
    }

    @discardableResult
    func finishWorkout() -> ResultsModel {
        currentPhase = .finished
        lastDetectedPunch = .none
        bodyJoints = []

        let startedAt = workoutStartedAt ?? Date()

        return ResultsModel(
            startedAt: startedAt,
            endedAt: Date(),
            stance: userStance,
            speedUnit: .shoulderWidthsPerSecond,
            punches: punchResults
        )
    }
}

// MARK: - Estruturas auxiliares originais

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
