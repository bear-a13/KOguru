import SwiftUI
import AVFoundation

struct DrillSessionView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var drillManager = DrillManager()
    @Environment(\.dismiss) private var dismiss

    @State private var drillResult: DrillResultsModel?
    
    // Estados da animação e tempo total
    @State private var isTimePulsing = false
    private let totalRoundTime: Double = 60.0 // Ajuste este valor para a duração real do seu round

    private static let cameraControlQueue = DispatchQueue(
        label: "br.com.koguru.drill-camera-control",
        qos: .userInitiated
    )

    var body: some View {
        Group {
            if let drillResult {
                DrillResultsView(
                    result: drillResult,
                    onRestart: restartDrill,
                    onDone: closeDrill
                )
                .transition(.opacity)
            } else {
                cameraContent
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            configureCamera()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            drillManager.stopDrill()
            stopCamera()
        }
        .onChange(of: workoutViewModel.currentPhase) { newPhase in
            if newPhase == .counting {
                drillManager.startDrill()
            }
        }
        .onChange(of: workoutViewModel.lastDetectedPunch) { newPunch in
            drillManager.processPunch(newPunch)
        }
        .onChange(of: drillManager.isRoundOver) { isOver in
            if isOver {
                finishDrill()
            }
        }
    }

    // MARK: - Interface da câmera

    private var cameraContent: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            if workoutViewModel.currentPhase == .counting {
                BodySkeletonView(joints: workoutViewModel.bodyJoints)
                    .accessibilityHidden(true)
            }

            if workoutViewModel.currentPhase == .framing {
                FramingOverlayView(isFramed: workoutViewModel.isProperlyFramed)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(workoutViewModel.isProperlyFramed ? "Corpo enquadrado corretamente" : "Ajuste sua posição em frente à câmera")
            }

            VStack {
                HStack {
                    CircleIconButton(systemName: "xmark") { closeDrill() }
                        .accessibilityLabel("Encerrar drill")
                        .accessibilityHint("Toque duas vezes para parar o treino e sair")

                    Spacer()

                    Text("DRILL")
                        .font(Font.custom("Anton", size: 36))
                        .foregroundColor(.white)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Color.clear.frame(width: 40, height: 40)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                if workoutViewModel.currentPhase == .counting {
                    ZStack {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                                                                Capsule()
                                    .fill(Color.vermelhoCard)
                                    .frame(width: max(0, geo.size.width * CGFloat(drillManager.timeRemaining / totalRoundTime)))
                                    .animation(.linear, value: drillManager.timeRemaining)
                                
                                Text(formattedTime)
                                    .font(Font.custom("Anton", size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: geo.size.width, alignment: .center)
                                    
                            }
                        }
                        .frame(height: 55)
                        .padding(.horizontal, 20)
                        .scaleEffect(isTimePulsing ? 1.2 : 1.0)
                        .onChange(of: drillManager.timeRemaining) { time in
                            //aqui é para configurara o pulsar abaixo de 10s
                            if time <= 10 && time > 0 {
                                if !isTimePulsing {
                                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                        isTimePulsing = true
                                    }
                                }
                            } else if time <= 0 {
                                // Para o pulso quando o tempo acaba
                                withAnimation {
                                    isTimePulsing = false
                                }
                            }
                        }
                    }
                    .frame(height: 55)
                }
                
                Spacer()

                if workoutViewModel.currentPhase == .counting {
                    drillOverlay
                }
            }
        }
    }

    // MARK: - Overlay

    private var drillOverlay: some View {
        VStack(alignment: .center, spacing: 14) {
            if drillManager.lastWasWrongPunch {
                Text("ERROU! REINICIANDO COMBO")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .background(Color.backgroundColorRed)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Golpe errado. O combo foi reiniciado.")
            }

            if drillManager.isComboCompleted {
                Text("EXCELENTE!")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                    .padding()
                    .accessibilityLabel("Excelente! Combo concluído.")

            } else if let combo = drillManager.currentCombo {
                VStack(alignment: .center) {
                    ForEach(Array(combo.sequence.enumerated()), id: \.offset) { index, punch in
                        let isCompleted = index < drillManager.currentStepIndex

                        Text(punchName(for: punch))
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                            .opacity(isCompleted ? 0.4 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: drillManager.currentStepIndex)
                    }
                }
                .padding()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityComboLabel(for: combo))
                .accessibilityValue(accessibilityComboValue(for: combo))
            }
        }
        .background(Color.backgroundColorRed.opacity(0.8))
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 35, topTrailingRadius: 35))
        .frame(width: 240)
        .padding(.bottom, 60)
        .animation(.easeInOut(duration: 0.2), value: drillManager.lastWasWrongPunch)
    }

    // MARK: - Fluxo de resultados

    private func finishDrill() {
        let results = drillManager.makeResults()
        stopCamera()

        withAnimation(.easeInOut(duration: 0.25)) {
            drillResult = results
        }
    }

    private func restartDrill() {
        drillResult = nil
        workoutViewModel.resetWorkout()
        drillManager.stopDrill()
        configureCamera()
    }

    private func closeDrill() {
        drillManager.stopDrill()
        stopCamera()
        dismiss()
    }

    // MARK: - Câmera

    private func configureCamera() {
        let model = workoutViewModel

        cameraManager.frameDelegate = { [weak model] sampleBuffer in
            model?.processFrame(sampleBuffer)
        }

        startCamera()
    }

    private func startCamera() {
        let session = cameraManager.session

        Self.cameraControlQueue.async {
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }

    private func stopCamera() {
        cameraManager.frameDelegate = nil
        let session = cameraManager.session

        Self.cameraControlQueue.async {
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let seconds = max(Int(drillManager.timeRemaining.rounded(.up)), 0)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func punchName(for punch: PunchType) -> String {
        switch punch {
        case .jab: return "JAB"
        case .cross: return "DIRETO"
        default: return ""
        }
    }

    // MARK: - Accessibility Helpers

    private func accessibilityComboLabel(for combo: DrillCombo) -> String {
        let sequenceText = combo.sequence.map { punchName(for: $0) }.joined(separator: ", ")
        return "Sequência de golpes: \(sequenceText)"
    }

    private func accessibilityComboValue(for combo: DrillCombo) -> String {
        guard drillManager.currentStepIndex < combo.sequence.count else { return "Combo concluído" }
        let currentPunch = punchName(for: combo.sequence[drillManager.currentStepIndex])
        return "Aguardando golpe: \(currentPunch)"
    }
}
