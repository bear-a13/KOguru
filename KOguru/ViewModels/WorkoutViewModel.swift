import SwiftUI
import Vision
import CoreGraphics
import AVFoundation
import Combine
import ImageIO

class WorkoutViewModel: ObservableObject {
    // MARK: - Propriedades Publicadas (UI)
    @Published var currentPhase: WorkoutPhase = .framing
    @Published var punchCount: Int = 0
    @Published var isProperlyFramed: Bool = false
    @Published var lastDetectedPunch: PunchType = .none
    @Published var userStance: Stance = .orthodox
    @Published var bodyJoints: [BodyJoint] = []
    
    // MARK: - Parâmetros Calibrados para Ângulo de 45°
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
    
    // MARK: - Estado Interno de Rastreamento
    private var smoothedJointPositions: [String: CGPoint] = [:]
    private var trackedVisionPoints: [String: TrackedPoint] = [:]
    private var pendingPunch: PunchType = .none
    private var stableFrameCount = 0
    private var guardFrameCount = 0
    private var hasRegisteredCurrentPunch = false
    
    // MARK: - Processamento Principal
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, _ in
            guard let self = self else { return }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let body = observations.first else {
                if self.currentPhase == .framing {
                    DispatchQueue.main.async { self.isProperlyFramed = false }
                }
                return
            }
            
            switch self.currentPhase {
            case .framing:
                self.checkFraming(body: body)
            case .counting:
                self.analyzePose(body, isMirrored: true)
            case .finished:
                break
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
        try? handler.perform([request])
    }
    
    // MARK: - Fase 1: Enquadramento
    private func checkFraming(body: VNHumanBodyPoseObservation) {
        let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftShoulder, .rightShoulder,
            .leftWrist, .rightWrist, .leftAnkle, .rightAnkle
        ]
        
        var allVisible = true
        for joint in requiredJoints {
            if let point = try? body.recognizedPoint(joint), point.confidence > 0.3 {
            } else {
                allVisible = false
                break
            }
        }
        
        DispatchQueue.main.async {
            self.isProperlyFramed = allVisible
            if allVisible {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.currentPhase = .counting
                }
            }
        }
    }
    
    // MARK: - Fase 2: Análise de Pose e Detecção de Golpe
    private func analyzePose(_ body: VNHumanBodyPoseObservation, isMirrored: Bool) {
        guard let points = try? body.recognizedPoints(.all) else { return }
        
        let trackedPoints = buildTrackedPoints(from: points)
        let joints = buildBodyJoints(from: trackedPoints, isMirrored: isMirrored)
        
        guard let leftShoulder = trackedPoints["LS"],
              let leftWrist = trackedPoints["LW"],
              let leftElbow = trackedPoints["LE"],
              let rightShoulder = trackedPoints["RS"],
              let rightWrist = trackedPoints["RW"],
              let rightElbow = trackedPoints["RE"] else {
            publish(detected: stabilizedPunch(from: .none), joints: joints)
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
        
        let detected = classifyPunch(leftScore: leftScore, rightScore: rightScore)
        let finalPunch = stabilizedPunch(from: detected)
        
        publish(detected: finalPunch, joints: joints)
    }
    
    // MARK: - Rastreamento e Previsão de Pontos Ocultos
    private func buildTrackedPoints(from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> [String: CGPoint] {
        let isLeftRearHand = userStance == .southpaw
        let isRightRearHand = userStance == .orthodox
        
        let jointConfigs: [JointConfig] = [
            JointConfig(label: "LS", name: .leftShoulder, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "LE", name: .leftElbow, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 1),
            JointConfig(
                label: "LW",
                name: .leftWrist,
                minimumConfidence: isLeftRearHand ? rearWristMinimumConfidence : leadWristMinimumConfidence,
                maxPredictionFrames: isLeftRearHand ? maxRearWristPredictionFrames : maxLeadWristPredictionFrames
            ),
            JointConfig(label: "RS", name: .rightShoulder, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: "RE", name: .rightElbow, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 1),
            JointConfig(
                label: "RW",
                name: .rightWrist,
                minimumConfidence: isRightRearHand ? rearWristMinimumConfidence : leadWristMinimumConfidence,
                maxPredictionFrames: isRightRearHand ? maxRearWristPredictionFrames : maxLeadWristPredictionFrames
            )
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
        let predictionStrength = label.hasSuffix("W") ? CGFloat(0.65) : CGFloat(0.35)
        let predictedPosition = CGPoint(
            x: clamp(track.position.x + velocity.dx * predictionStrength, min: 0, max: 1),
            y: clamp(track.position.y + velocity.dy * predictionStrength, min: 0, max: 1)
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
    
    private func buildBodyJoints(from trackedPoints: [String: CGPoint], isMirrored: Bool) -> [BodyJoint] {
        let orderedLabels = ["LS", "LW", "LE", "RS", "RW", "RE"]
        return orderedLabels.compactMap { label in
            guard let point = trackedPoints[label] else { return nil }
            let mappedPoint = screenPoint(from: point, isMirrored: isMirrored)
            let smoothedPoint = smooth(point: mappedPoint, for: label)
            return BodyJoint(name: label, position: smoothedPoint)
        }
    }
    
    // MARK: - Algoritmo Biomecânico Ajustado para Posicionamento 45°
    private func armExtensionScore(
        shoulder: CGPoint,
        elbow: CGPoint,
        wrist: CGPoint,
        shoulderWidth: CGFloat
    ) -> CGFloat {
        // Extensão do cotovelo (exige abertura próxima do final)
        let angle = jointAngle(shoulder, elbow, wrist)
        let elbowStraightness = clamp((angle - 100) / 65, min: 0, max: 1)
        
        // Alcance relativo ao ombro
        let reach = clamp(distance(shoulder, wrist) / (shoulderWidth * 1.3), min: 0, max: 1)
        
        // Penalidade gradual apenas se a mão estiver visivelmente abaixo do peito
        let heightDifference = wrist.y - shoulder.y
        let lowHandPenalty = clamp((heightDifference - (shoulderWidth * 0.3)) / shoulderWidth, min: 0, max: 0.4)
        
        let score = (elbowStraightness * 0.60) + (reach * 0.40) - lowHandPenalty
        return max(score, 0)
    }
    private func classifyPunch(leftScore: CGFloat, rightScore: CGFloat) -> PunchType {
        let leadScore = userStance == .orthodox ? leftScore : rightScore
        let rearScore = userStance == .orthodox ? rightScore : leftScore
        
        guard max(leadScore, rearScore) >= punchScoreThreshold else { return .none }
        
        if leadScore - rearScore > scoreDifferenceThreshold {
            return .jab
        }
        
        if rearScore - leadScore > scoreDifferenceThreshold {
            return .direto
        }
        
        return .none
    }
    
    private func stabilizedPunch(from detected: PunchType) -> PunchType {
        if detected == .none {
            guardFrameCount += 1
            stableFrameCount = 0
            pendingPunch = .none
            return guardFrameCount >= guardFramesBeforeReset ? .none : lastDetectedPunch
        }
        
        guardFrameCount = 0
        if detected == pendingPunch {
            stableFrameCount += 1
        } else {
            pendingPunch = detected
            stableFrameCount = 1
        }
        
        return stableFrameCount >= requiredStableFrames ? detected : lastDetectedPunch
    }
    
    // MARK: - Atualização da UI e Contagem
    private func publish(detected: PunchType, joints: [BodyJoint]) {
        DispatchQueue.main.async {
            if detected != .none && !self.hasRegisteredCurrentPunch {
                self.punchCount += 1
                self.hasRegisteredCurrentPunch = true
            } else if detected == .none {
                self.hasRegisteredCurrentPunch = false
            }
            
            self.lastDetectedPunch = detected
            self.bodyJoints = joints
        }
    }
    
    // MARK: - Funções de Apoio Biomecânico
    private func screenPoint(from visionPoint: CGPoint, isMirrored: Bool) -> CGPoint {
        CGPoint(
            x: isMirrored ? 1 - visionPoint.x : visionPoint.x,
            y: 1 - visionPoint.y
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
    
    private func jointAngle(_ first: CGPoint, _ middle: CGPoint, _ last: CGPoint) -> CGFloat {
        let firstVector = CGVector(dx: first.x - middle.x, dy: first.y - middle.y)
        let secondVector = CGVector(dx: last.x - middle.x, dy: last.y - middle.y)
        let dotProduct = firstVector.dx * secondVector.dx + firstVector.dy * secondVector.dy
        let firstMagnitude = hypot(firstVector.dx, firstVector.dy)
        let secondMagnitude = hypot(secondVector.dx, secondVector.dy)
        guard firstMagnitude > 0, secondMagnitude > 0 else { return 0 }
        
        let cosine = clamp(dotProduct / (firstMagnitude * secondMagnitude), min: -1, max: 1)
        return acos(cosine) * 180 / .pi
    }
    
    private func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }
    
    func resetWorkout() {
        punchCount = 0
        currentPhase = .framing
        isProperlyFramed = false
        lastDetectedPunch = .none
        hasRegisteredCurrentPunch = false
    }
}

// MARK: - Estruturas Auxiliares
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
        guard let previousPosition else { return CGVector(dx: 0, dy: 0) }
        return CGVector(
            dx: position.x - previousPosition.x,
            dy: position.y - previousPosition.y
        )
    }
}
