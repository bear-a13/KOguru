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
    @Published var lastDetectedPunch: PunchType = .none
    @Published var userStance: Stance = .orthodox
    @Published var bodyJoints: [BodyJoint] = []
    @Published private(set) var punchResults: [PunchResult] = []

    // MARK: - Serviços

    private var poseTracking: PoseTrackingService
    private var classifier: PunchClassifier
    private var speedTracker: SpeedTracker

    // MARK: - Estado interno para os resultados

    private var workoutStartedAt: Date?
    private var workoutSampleStartTimestamp: TimeInterval?
    private var hasRegisteredCurrentPunch = false

    // MARK: - Inicialização

    init(
        poseTracking: PoseTrackingService = PoseTrackingService(),
        classifier: PunchClassifier = PunchClassifier(),
        speedTracker: SpeedTracker = SpeedTracker()
    ) {
        self.poseTracking = poseTracking
        self.classifier = classifier
        self.speedTracker = speedTracker
    }

    // MARK: - Processamento principal

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

    // MARK: - Fase 1: enquadramento

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

            if allVisible {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.currentPhase = .counting
                }
            }
        }
    }

    // MARK: - Fase 2: análise de pose e detecção

    private func analyzePose(
        _ body: VNHumanBodyPoseObservation,
        isMirrored: Bool,
        timestamp: TimeInterval
    ) {
        guard let points = try? body.recognizedPoints(.all) else { return }

        let trackedPoints = poseTracking.track(
            from: points,
            stance: userStance
        )
        let joints = poseTracking.buildJoints(
            from: trackedPoints,
            isMirrored: isMirrored
        )

        guard let leftShoulder = trackedPoints["LS"],
              let leftWrist = trackedPoints["LW"],
              let leftElbow = trackedPoints["LE"],
              let rightShoulder = trackedPoints["RS"],
              let rightWrist = trackedPoints["RW"],
              let rightElbow = trackedPoints["RE"] else {
            let finalPunch = classifier.stabilize(.none)
            publish(
                detected: finalPunch,
                joints: joints,
                detectedSpeed: nil,
                timestamp: timestamp
            )
            speedTracker.resetWindow(after: finalPunch)
            return
        }

        let shoulderWidth = max(
            WorkoutMath.distance(leftShoulder, rightShoulder),
            0.12
        )

        // A velocidade é paralela: não altera classificação ou estabilização.
        speedTracker.update(
            leftWrist: leftWrist,
            rightWrist: rightWrist,
            shoulderWidth: shoulderWidth,
            timestamp: timestamp
        )

        let finalPunch = classifier.detect(
            leftShoulder: leftShoulder,
            leftElbow: leftElbow,
            leftWrist: leftWrist,
            rightShoulder: rightShoulder,
            rightElbow: rightElbow,
            rightWrist: rightWrist,
            shoulderWidth: shoulderWidth,
            stance: userStance
        )
        let detectedSpeed = speedTracker.speedForPunch(
            finalPunch,
            stance: userStance
        )

        publish(
            detected: finalPunch,
            joints: joints,
            detectedSpeed: detectedSpeed,
            timestamp: timestamp
        )

        speedTracker.resetWindow(after: finalPunch)
    }

    // MARK: - Publicação + registro de resultado

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

    // MARK: - Reinício e finalização

    func resetWorkout() {
        punchCount = 0
        currentPhase = .framing
        isProperlyFramed = false
        lastDetectedPunch = .none
        bodyJoints = []
        punchResults = []

        poseTracking.reset()
        classifier.reset()
        speedTracker.reset()

        workoutStartedAt = nil
        workoutSampleStartTimestamp = nil
        hasRegisteredCurrentPunch = false
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