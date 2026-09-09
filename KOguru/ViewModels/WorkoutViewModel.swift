import SwiftUI
import Vision
import CoreGraphics
import AVFoundation
import Combine
import ImageIO

final class WorkoutViewModel: ObservableObject, @unchecked Sendable {
    // MARK: - Estado publicado para a interface

    @Published private(set) var currentPhase: WorkoutPhase = .framing
    @Published private(set) var isProperlyFramed = false
    @Published private(set) var framingProgress = 0.0
    @Published private(set) var lastDetectedPunch: PunchType = .none
    @Published private(set) var lastPunchSpeed: Double?
    @Published private(set) var userStance: Stance = .orthodox
    @Published private(set) var bodyJoints: [BodyJoint] = []
    @Published private(set) var punchResults: [PunchResult] = []

    var punchCount: Int {
        punchResults.count
    }

    // MARK: - Configuração do MVP

    private let bodyMinimumConfidence: VNConfidence = 0.25
    private let leadWristMinimumConfidence: VNConfidence = 0.20
    private let rearWristMinimumConfidence: VNConfidence = 0.15

    private let framingRequiredFrames = 15
    private let smoothingFactor: CGFloat = 0.35
    private let maxLeadWristPredictionFrames = 2
    private let maxRearWristPredictionFrames = 4

    /// O braço começou a se estender, mas o golpe ainda não foi confirmado.
    private let punchStartScore: CGFloat = 0.56

    /// Extensão necessária por mais de um frame para confirmar o golpe.
    private let punchConfirmationScore: CGFloat = 0.73
    private let punchReleaseScore: CGFloat = 0.48
    private let scoreDifferenceThreshold: CGFloat = 0.08
    private let minimumHandSpeed = 0.55
    private let minimumOutwardSpeed = 0.25
    private let maximumPlausibleSpeed = 25.0
    private let confirmationFramesRequired = 2
    private let releaseFramesRequired = 3
    private let maximumPunchDuration: TimeInterval = 1.50
    private let preTriggerSpeedWindowSize = 5

    // MARK: - Estado exclusivo do processamento de vídeo

    /// Impede que dois frames ou o encerramento da sessão alterem o estado ao mesmo tempo.
    private let processingGate = DispatchSemaphore(value: 1)
    private var processingPhase: WorkoutPhase = .framing
    private var processingStance: Stance = .orthodox

    private var recordedPunches: [PunchResult] = []
    private var workoutStartedAt: Date?
    private var workoutSampleStartTimestamp: TimeInterval?
    private var lastFrameTimestamp: TimeInterval?

    private var stableFramingFrames = 0
    private var smoothedJointPositions: [String: CGPoint] = [:]
    private var trackedVisionPoints: [String: TrackedPoint] = [:]

    private var previousLeftWrist: CGPoint?
    private var previousRightWrist: CGPoint?
    private var previousLeftReach: CGFloat?
    private var previousRightReach: CGFloat?
    private var previousMotionTimestamp: TimeInterval?
    private var recentLeftOutboundSpeeds: [Double] = []
    private var recentRightOutboundSpeeds: [Double] = []

    private var activePunch: ActivePunch?

    // MARK: - API pública

    func setStance(_ stance: Stance) {
        processingGate.wait()
        processingStance = stance
        processingGate.signal()

        userStance = stance
    }

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        // Se um frame anterior ainda estiver sendo analisado, descarta este frame.
        // Isso evita acumular atraso e mantém a análise próxima do tempo real.
        guard processingGate.wait(timeout: .now()) == .success else { return }
        defer { processingGate.signal() }

        guard processingPhase != .finished,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timestamp = CMTimeGetSeconds(presentationTime)
        guard timestamp.isFinite else { return }
        lastFrameTimestamp = timestamp

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .upMirrored,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            publishMissingBody()
            return
        }

        guard let body = request.results?.first else {
            publishMissingBody()
            return
        }

        switch processingPhase {
        case .framing:
            checkFraming(body: body, timestamp: timestamp)
        case .counting:
            analyzePose(body, timestamp: timestamp)
        case .finished:
            break
        }
    }

    func resetWorkout() {
        processingGate.wait()
        resetProcessingState()
        processingGate.signal()

        currentPhase = .framing
        isProperlyFramed = false
        framingProgress = 0
        lastDetectedPunch = .none
        lastPunchSpeed = nil
        bodyJoints = []
        punchResults = []
    }

    @discardableResult
    func finishWorkout() -> ResultsModel {
        processingGate.wait()

        processingPhase = .finished

        // Se o usuário tocar em finalizar durante um golpe já confirmado,
        // preserva o golpe e marca que o retorno à guarda não foi observado.
        if let activePunch, activePunch.isConfirmed {
            let endTimestamp = lastFrameTimestamp ?? activePunch.lastTimestamp
            let result = makePunchResult(
                from: activePunch,
                endTimestamp: endTimestamp,
                returnedToGuard: false
            )
            recordedPunches.append(result)
        }
        activePunch = nil

        let punchesSnapshot = recordedPunches
        let startedAt = workoutStartedAt ?? Date()
        let stance = processingStance

        processingGate.signal()

        punchResults = punchesSnapshot
        currentPhase = .finished
        lastDetectedPunch = .none

        return ResultsModel(
            startedAt: startedAt,
            endedAt: Date(),
            stance: stance,
            speedUnit: .shoulderWidthsPerSecond,
            punches: punchesSnapshot
        )
    }

    // MARK: - Enquadramento

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

        let allVisible = requiredJoints.allSatisfy { joint in
            guard let point = try? body.recognizedPoint(joint) else { return false }
            return point.confidence >= 0.30
        }

        stableFramingFrames = allVisible ? stableFramingFrames + 1 : 0
        let progress = min(
            Double(stableFramingFrames) / Double(framingRequiredFrames),
            1
        )

        if stableFramingFrames >= framingRequiredFrames {
            processingPhase = .counting
            workoutStartedAt = Date()
            workoutSampleStartTimestamp = timestamp
            resetMotionHistory()
        }

        let didStart = processingPhase == .counting
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isProperlyFramed = allVisible
            self.framingProgress = progress

            if didStart {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.currentPhase = .counting
                }
            }
        }
    }

    // MARK: - Análise do golpe

    private func analyzePose(
        _ body: VNHumanBodyPoseObservation,
        timestamp: TimeInterval
    ) {
        guard let points = try? body.recognizedPoints(.all) else { return }

        let trackedPoints = buildTrackedPoints(from: points)
        let joints = buildBodyJoints(
            from: trackedPoints,
            isMirrored: true
        )

        guard let leftShoulder = trackedPoints[JointLabel.leftShoulder],
              let leftElbow = trackedPoints[JointLabel.leftElbow],
              let leftWrist = trackedPoints[JointLabel.leftWrist],
              let rightShoulder = trackedPoints[JointLabel.rightShoulder],
              let rightElbow = trackedPoints[JointLabel.rightElbow],
              let rightWrist = trackedPoints[JointLabel.rightWrist] else {
            publishFrame(joints: joints, displayedPunch: .none, completedPunch: nil)
            return
        }

        let nose = trackedPoints[JointLabel.nose]
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

        let motions = updateWristMotions(
            leftShoulder: leftShoulder,
            leftWrist: leftWrist,
            rightShoulder: rightShoulder,
            rightWrist: rightWrist,
            shoulderWidth: shoulderWidth,
            timestamp: timestamp
        )

        let frame = PunchFrame(
            timestamp: timestamp,
            shoulderWidth: shoulderWidth,
            nose: nose,
            leftShoulder: leftShoulder,
            leftWrist: leftWrist,
            rightShoulder: rightShoulder,
            rightWrist: rightWrist,
            leftScore: leftScore,
            rightScore: rightScore,
            leftMotion: motions.left,
            rightMotion: motions.right
        )

        let completedPunch = updatePunchState(with: frame)
        if let completedPunch {
            recordedPunches.append(completedPunch)
        }

        let displayedPunch: PunchType
        if let activePunch, activePunch.isConfirmed {
            displayedPunch = activePunch.type
        } else if let completedPunch {
            displayedPunch = completedPunch.type
        } else {
            displayedPunch = .none
        }

        publishFrame(
            joints: joints,
            displayedPunch: displayedPunch,
            completedPunch: completedPunch
        )
    }

    private func updatePunchState(with frame: PunchFrame) -> PunchResult? {
        let candidate = classifyCandidate(
            leftScore: frame.leftScore,
            rightScore: frame.rightScore
        )

        if activePunch == nil {
            startPunchIfNeeded(candidate: candidate, frame: frame)
            return nil
        }

        guard var active = activePunch else { return nil }
        active.lastTimestamp = frame.timestamp

        let activeScore = score(for: active.hand, in: frame)
        let activeMotion = motion(for: active.hand, in: frame)
        active.maximumExtensionScore = max(active.maximumExtensionScore, activeScore)

        // Guarda apenas velocidade da fase de avanço. O retorno não aumenta o pico.
        if activeMotion.outwardSpeed > 0 {
            active.peakSpeed = max(active.peakSpeed, activeMotion.speed)
        }

        updateGuardEvaluation(active: &active, frame: frame)

        if activeScore >= punchConfirmationScore {
            active.confirmationFrames += 1
            if active.confirmationFrames >= confirmationFramesRequired {
                active.isConfirmed = true
            }
        } else if !active.isConfirmed {
            active.confirmationFrames = 0
        }

        let switchedToAnotherPunch = candidate != .none && candidate != active.type
        if switchedToAnotherPunch,
           canStartPunch(candidate, frame: frame) {
            let completed = active.isConfirmed
                ? makePunchResult(
                    from: active,
                    endTimestamp: frame.timestamp,
                    returnedToGuard: isStrikingHandInGuard(active.hand, frame: frame)
                )
                : nil

            activePunch = makeActivePunch(type: candidate, frame: frame)
            return completed
        }

        if activeScore <= punchReleaseScore && activeMotion.outwardSpeed <= 0 {
            active.releaseFrames += 1
        } else {
            active.releaseFrames = 0
        }

        let timedOut = frame.timestamp - active.startTimestamp >= maximumPunchDuration
        let wasReleased = active.releaseFrames >= releaseFramesRequired

        if wasReleased || timedOut {
            activePunch = nil

            guard active.isConfirmed else { return nil }

            return makePunchResult(
                from: active,
                endTimestamp: frame.timestamp,
                returnedToGuard: wasReleased && isStrikingHandInGuard(active.hand, frame: frame)
            )
        }

        activePunch = active
        return nil
    }

    private func startPunchIfNeeded(candidate: PunchType, frame: PunchFrame) {
        guard candidate != .none, canStartPunch(candidate, frame: frame) else { return }
        activePunch = makeActivePunch(type: candidate, frame: frame)
    }

    private func canStartPunch(_ type: PunchType, frame: PunchFrame) -> Bool {
        guard type != .none else { return false }
        let hand = hand(for: type)
        let currentMotion = motion(for: hand, in: frame)
        return currentMotion.speed >= minimumHandSpeed
            && currentMotion.outwardSpeed >= minimumOutwardSpeed
    }

    private func makeActivePunch(type: PunchType, frame: PunchFrame) -> ActivePunch {
        let hand = hand(for: type)
        let currentMotion = motion(for: hand, in: frame)
        let preTriggerPeak: Double

        switch hand {
        case .left:
            preTriggerPeak = recentLeftOutboundSpeeds.max() ?? 0
            recentLeftOutboundSpeeds.removeAll(keepingCapacity: true)
        case .right:
            preTriggerPeak = recentRightOutboundSpeeds.max() ?? 0
            recentRightOutboundSpeeds.removeAll(keepingCapacity: true)
        }

        return ActivePunch(
            type: type,
            hand: hand,
            startTimestamp: frame.timestamp,
            lastTimestamp: frame.timestamp,
            peakSpeed: max(currentMotion.speed, preTriggerPeak),
            maximumExtensionScore: score(for: hand, in: frame),
            confirmationFrames: 0,
            releaseFrames: 0,
            isConfirmed: false,
            guardSampleCount: 0,
            guardMaintainedSampleCount: 0
        )
    }

    private func makePunchResult(
        from active: ActivePunch,
        endTimestamp: TimeInterval,
        returnedToGuard: Bool
    ) -> PunchResult {
        let relativeTimestamp = active.startTimestamp - (workoutSampleStartTimestamp ?? active.startTimestamp)
        let guardMaintained: Bool?

        if active.guardSampleCount > 0 {
            let successRate = Double(active.guardMaintainedSampleCount)
                / Double(active.guardSampleCount)
            guardMaintained = successRate >= 0.70
        } else {
            guardMaintained = nil
        }

        let evaluation = PunchEvaluation(
            expectedType: nil,
            classifierConfidence: nil,
            guardHandMaintained: guardMaintained,
            returnedToGuard: returnedToGuard,
            techniqueScore: nil
        )

        return PunchResult(
            type: active.type,
            timestamp: relativeTimestamp,
            peakSpeed: active.peakSpeed,
            duration: endTimestamp - active.startTimestamp,
            evaluation: evaluation
        )
    }

    // MARK: - Heurísticas biomecânicas

    private func armExtensionScore(
        shoulder: CGPoint,
        elbow: CGPoint,
        wrist: CGPoint,
        shoulderWidth: CGFloat
    ) -> CGFloat {
        let angle = jointAngle(shoulder, elbow, wrist)
        let elbowStraightness = clamp((angle - 100) / 65, min: 0, max: 1)
        let reach = clamp(
            distance(shoulder, wrist) / (shoulderWidth * 1.30),
            min: 0,
            max: 1
        )

        // Coordenadas do Vision crescem para cima. Valor negativo significa mão abaixo.
        let belowShoulder = max(shoulder.y - wrist.y, 0)
        let lowHandPenalty = clamp(
            (belowShoulder - shoulderWidth * 0.30) / shoulderWidth,
            min: 0,
            max: 0.40
        )

        return max((elbowStraightness * 0.60) + (reach * 0.40) - lowHandPenalty, 0)
    }

    private func classifyCandidate(
        leftScore: CGFloat,
        rightScore: CGFloat
    ) -> PunchType {
        let leadScore = processingStance == .orthodox ? leftScore : rightScore
        let rearScore = processingStance == .orthodox ? rightScore : leftScore

        guard max(leadScore, rearScore) >= punchStartScore else { return .none }

        if leadScore - rearScore >= scoreDifferenceThreshold {
            return .jab
        }

        if rearScore - leadScore >= scoreDifferenceThreshold {
            return .cross
        }

        return .none
    }

    private func hand(for type: PunchType) -> TrackedHand {
        switch (processingStance, type) {
        case (.orthodox, .jab), (.southpaw, .cross):
            return .left
        case (.orthodox, .cross), (.southpaw, .jab), (_, .none):
            return .right
        }
    }

    private func score(for hand: TrackedHand, in frame: PunchFrame) -> CGFloat {
        hand == .left ? frame.leftScore : frame.rightScore
    }

    private func motion(for hand: TrackedHand, in frame: PunchFrame) -> WristMotion {
        hand == .left ? frame.leftMotion : frame.rightMotion
    }

    private func updateGuardEvaluation(active: inout ActivePunch, frame: PunchFrame) {
        guard let nose = frame.nose else { return }

        let guardIsMaintained: Bool
        switch active.hand {
        case .left:
            guardIsMaintained = isHandInGuard(
                wrist: frame.rightWrist,
                shoulder: frame.rightShoulder,
                nose: nose,
                shoulderWidth: frame.shoulderWidth
            )
        case .right:
            guardIsMaintained = isHandInGuard(
                wrist: frame.leftWrist,
                shoulder: frame.leftShoulder,
                nose: nose,
                shoulderWidth: frame.shoulderWidth
            )
        }

        active.guardSampleCount += 1
        if guardIsMaintained {
            active.guardMaintainedSampleCount += 1
        }
    }

    private func isStrikingHandInGuard(_ hand: TrackedHand, frame: PunchFrame) -> Bool {
        guard let nose = frame.nose else { return false }

        switch hand {
        case .left:
            return isHandInGuard(
                wrist: frame.leftWrist,
                shoulder: frame.leftShoulder,
                nose: nose,
                shoulderWidth: frame.shoulderWidth
            )
        case .right:
            return isHandInGuard(
                wrist: frame.rightWrist,
                shoulder: frame.rightShoulder,
                nose: nose,
                shoulderWidth: frame.shoulderWidth
            )
        }
    }

    private func isHandInGuard(
        wrist: CGPoint,
        shoulder: CGPoint,
        nose: CGPoint,
        shoulderWidth: CGFloat
    ) -> Bool {
        let faceDistance = distance(wrist, nose) / shoulderWidth
        let shoulderDistance = distance(wrist, shoulder) / shoulderWidth
        let isNotTooLow = wrist.y >= shoulder.y - shoulderWidth * 0.40

        return isNotTooLow && (faceDistance <= 1.15 || shoulderDistance <= 1.05)
    }

    // MARK: - Velocidade relativa

    private func updateWristMotions(
        leftShoulder: CGPoint,
        leftWrist: CGPoint,
        rightShoulder: CGPoint,
        rightWrist: CGPoint,
        shoulderWidth: CGFloat,
        timestamp: TimeInterval
    ) -> (left: WristMotion, right: WristMotion) {
        let leftReach = distance(leftShoulder, leftWrist) / shoulderWidth
        let rightReach = distance(rightShoulder, rightWrist) / shoulderWidth

        defer {
            previousLeftWrist = leftWrist
            previousRightWrist = rightWrist
            previousLeftReach = leftReach
            previousRightReach = rightReach
            previousMotionTimestamp = timestamp
        }

        guard let previousLeftWrist,
              let previousRightWrist,
              let previousLeftReach,
              let previousRightReach,
              let previousMotionTimestamp else {
            return (.zero, .zero)
        }

        let deltaTime = timestamp - previousMotionTimestamp
        guard deltaTime > 0.001, deltaTime < 0.25 else {
            recentLeftOutboundSpeeds.removeAll(keepingCapacity: true)
            recentRightOutboundSpeeds.removeAll(keepingCapacity: true)
            return (.zero, .zero)
        }

        let leftSpeed = plausibleSpeed(
            Double(distance(leftWrist, previousLeftWrist) / shoulderWidth) / deltaTime
        )
        let rightSpeed = plausibleSpeed(
            Double(distance(rightWrist, previousRightWrist) / shoulderWidth) / deltaTime
        )

        let leftOutwardSpeed = Double(leftReach - previousLeftReach) / deltaTime
        let rightOutwardSpeed = Double(rightReach - previousRightReach) / deltaTime

        appendRolling(
            leftOutwardSpeed > 0.05 ? leftSpeed : 0,
            to: &recentLeftOutboundSpeeds
        )
        appendRolling(
            rightOutwardSpeed > 0.05 ? rightSpeed : 0,
            to: &recentRightOutboundSpeeds
        )

        return (
            WristMotion(speed: leftSpeed, outwardSpeed: leftOutwardSpeed),
            WristMotion(speed: rightSpeed, outwardSpeed: rightOutwardSpeed)
        )
    }

    private func plausibleSpeed(_ speed: Double) -> Double {
        guard speed.isFinite, speed >= 0, speed <= maximumPlausibleSpeed else { return 0 }
        return speed
    }

    private func appendRolling(_ value: Double, to values: inout [Double]) {
        values.append(value)
        if values.count > preTriggerSpeedWindowSize {
            values.removeFirst(values.count - preTriggerSpeedWindowSize)
        }
    }

    // MARK: - Rastreamento dos pontos

    private func buildTrackedPoints(
        from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> [String: CGPoint] {
        let leftIsRearHand = processingStance == .southpaw
        let rightIsRearHand = processingStance == .orthodox

        let configs: [JointConfig] = [
            // Cabeça e pescoço. O nariz é usado na avaliação de guarda;
            // o pescoço é usado para desenhar o esqueleto completo.
            JointConfig(label: JointLabel.nose, name: .nose, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.neck, name: .neck, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),

            // Tronco superior e braços.
            JointConfig(label: JointLabel.leftShoulder, name: .leftShoulder, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.rightShoulder, name: .rightShoulder, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.leftElbow, name: .leftElbow, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 1),
            JointConfig(label: JointLabel.rightElbow, name: .rightElbow, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 1),
            JointConfig(
                label: JointLabel.leftWrist,
                name: .leftWrist,
                minimumConfidence: leftIsRearHand ? rearWristMinimumConfidence : leadWristMinimumConfidence,
                maxPredictionFrames: leftIsRearHand ? maxRearWristPredictionFrames : maxLeadWristPredictionFrames
            ),
            JointConfig(
                label: JointLabel.rightWrist,
                name: .rightWrist,
                minimumConfidence: rightIsRearHand ? rearWristMinimumConfidence : leadWristMinimumConfidence,
                maxPredictionFrames: rightIsRearHand ? maxRearWristPredictionFrames : maxLeadWristPredictionFrames
            ),

            // Tronco inferior e pernas para o BodySkeletonView da develop.
            JointConfig(label: JointLabel.leftHip, name: .leftHip, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.rightHip, name: .rightHip, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.leftKnee, name: .leftKnee, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.rightKnee, name: .rightKnee, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.leftAnkle, name: .leftAnkle, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0),
            JointConfig(label: JointLabel.rightAnkle, name: .rightAnkle, minimumConfidence: bodyMinimumConfidence, maxPredictionFrames: 0)
        ]

        var result: [String: CGPoint] = [:]
        for config in configs {
            result[config.label] = trackedPoint(
                points[config.name],
                label: config.label,
                minimumConfidence: config.minimumConfidence,
                maxPredictionFrames: config.maxPredictionFrames
            )
        }
        return result
    }

    private func trackedPoint(
        _ point: VNRecognizedPoint?,
        label: String,
        minimumConfidence: VNConfidence,
        maxPredictionFrames: Int
    ) -> CGPoint? {
        if let point, point.confidence >= minimumConfidence {
            let previous = trackedVisionPoints[label]
            trackedVisionPoints[label] = TrackedPoint(
                position: point.location,
                previousPosition: previous?.position,
                missingFrames: 0
            )
            return point.location
        }

        guard maxPredictionFrames > 0,
              var tracked = trackedVisionPoints[label],
              tracked.missingFrames < maxPredictionFrames else {
            trackedVisionPoints.removeValue(forKey: label)
            return nil
        }

        let strength: CGFloat = label.hasSuffix("W") ? 0.55 : 0.30
        let velocity = tracked.velocity
        let predicted = CGPoint(
            x: clamp(tracked.position.x + velocity.dx * strength, min: 0, max: 1),
            y: clamp(tracked.position.y + velocity.dy * strength, min: 0, max: 1)
        )

        tracked.previousPosition = tracked.position
        tracked.position = predicted
        tracked.missingFrames += 1
        trackedVisionPoints[label] = tracked
        return predicted
    }

    private func buildBodyJoints(
        from points: [String: CGPoint],
        isMirrored: Bool
    ) -> [BodyJoint] {
        JointLabel.ordered.compactMap { label in
            guard let point = points[label] else { return nil }

            // Conversão que já estava sendo usada pela develop para alinhar
            // o buffer landscape com o preview portrait da câmera frontal.
            let mappedPoint = screenPoint(
                from: point,
                isMirrored: isMirrored
            )
            let smoothed = smooth(point: mappedPoint, for: label)
            return BodyJoint(name: label, position: smoothed)
        }
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

    // MARK: - Publicação na Main Queue

    private func publishFrame(
        joints: [BodyJoint],
        displayedPunch: PunchType,
        completedPunch: PunchResult?
    ) {
        let punchesSnapshot = recordedPunches

        DispatchQueue.main.async { [weak self] in
            guard let self, self.currentPhase != .finished else { return }
            self.bodyJoints = joints
            self.lastDetectedPunch = displayedPunch
            self.punchResults = punchesSnapshot

            if let completedPunch {
                self.lastPunchSpeed = completedPunch.peakSpeed
            }
        }
    }

    private func publishMissingBody() {
        if processingPhase == .framing {
            stableFramingFrames = 0
            DispatchQueue.main.async { [weak self] in
                self?.isProperlyFramed = false
                self?.framingProgress = 0
            }
        } else if processingPhase == .counting {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.currentPhase != .finished else { return }
                self.bodyJoints = []
                self.lastDetectedPunch = .none
            }
        }
    }

    // MARK: - Utilitários

    private func resetProcessingState() {
        processingPhase = .framing
        recordedPunches.removeAll(keepingCapacity: true)
        workoutStartedAt = nil
        workoutSampleStartTimestamp = nil
        lastFrameTimestamp = nil
        stableFramingFrames = 0
        smoothedJointPositions.removeAll(keepingCapacity: true)
        trackedVisionPoints.removeAll(keepingCapacity: true)
        activePunch = nil
        resetMotionHistory()
    }

    private func resetMotionHistory() {
        previousLeftWrist = nil
        previousRightWrist = nil
        previousLeftReach = nil
        previousRightReach = nil
        previousMotionTimestamp = nil
        recentLeftOutboundSpeeds.removeAll(keepingCapacity: true)
        recentRightOutboundSpeeds.removeAll(keepingCapacity: true)
    }

    private func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    private func jointAngle(
        _ first: CGPoint,
        _ middle: CGPoint,
        _ last: CGPoint
    ) -> CGFloat {
        let firstVector = CGVector(dx: first.x - middle.x, dy: first.y - middle.y)
        let secondVector = CGVector(dx: last.x - middle.x, dy: last.y - middle.y)
        let dot = firstVector.dx * secondVector.dx + firstVector.dy * secondVector.dy
        let firstMagnitude = hypot(firstVector.dx, firstVector.dy)
        let secondMagnitude = hypot(secondVector.dx, secondVector.dy)

        guard firstMagnitude > 0, secondMagnitude > 0 else { return 0 }

        let cosine = clamp(
            dot / (firstMagnitude * secondMagnitude),
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
}

// MARK: - Tipos auxiliares privados

private enum TrackedHand {
    case left
    case right
}

private struct WristMotion {
    let speed: Double
    let outwardSpeed: Double

    static let zero = WristMotion(speed: 0, outwardSpeed: 0)
}

private struct PunchFrame {
    let timestamp: TimeInterval
    let shoulderWidth: CGFloat
    let nose: CGPoint?
    let leftShoulder: CGPoint
    let leftWrist: CGPoint
    let rightShoulder: CGPoint
    let rightWrist: CGPoint
    let leftScore: CGFloat
    let rightScore: CGFloat
    let leftMotion: WristMotion
    let rightMotion: WristMotion
}

private struct ActivePunch {
    let type: PunchType
    let hand: TrackedHand
    let startTimestamp: TimeInterval
    var lastTimestamp: TimeInterval
    var peakSpeed: Double
    var maximumExtensionScore: CGFloat
    var confirmationFrames: Int
    var releaseFrames: Int
    var isConfirmed: Bool
    var guardSampleCount: Int
    var guardMaintainedSampleCount: Int
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
        guard let previousPosition else { return .zero }
        return CGVector(
            dx: position.x - previousPosition.x,
            dy: position.y - previousPosition.y
        )
    }
}

private enum JointLabel {
    static let nose = "N"
    static let neck = "NK"
    static let leftShoulder = "LS"
    static let leftElbow = "LE"
    static let leftWrist = "LW"
    static let rightShoulder = "RS"
    static let rightElbow = "RE"
    static let rightWrist = "RW"
    static let leftHip = "LH"
    static let rightHip = "RH"
    static let leftKnee = "LK"
    static let rightKnee = "RK"
    static let leftAnkle = "LA"
    static let rightAnkle = "RA"

    static let ordered = [
        neck,
        leftShoulder,
        leftElbow,
        leftWrist,
        rightShoulder,
        rightElbow,
        rightWrist,
        leftHip,
        rightHip,
        leftKnee,
        rightKnee,
        leftAnkle,
        rightAnkle
    ]
}
