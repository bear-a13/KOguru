import SwiftUI
import AVFoundation

struct WorkoutSessionView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel = WorkoutViewModel()
    @StateObject private var resultsStore = ResultsStore()
    @Environment(\.dismiss) private var dismiss

    @State private var result: ResultsModel?
    @State private var isShowingInfo = false

    private static let cameraControlQueue = DispatchQueue(
        label: "br.com.koguru.camera-control",
        qos: .userInitiated
    )

    var body: some View {
        Group {
            if let result {
                ResultsView(
                    result: result,
                    onRestart: restartWorkout,
                    onDone: closeWorkout
                )
                .transition(.opacity)
            } else {
                cameraContent
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: configureCamera)
        .onDisappear(perform: stopCamera)
        .alert("Como a velocidade funciona?", isPresented: $isShowingInfo) {
            Button("Entendi", role: .cancel) {}
        } message: {
            Text("A câmera usa pose 2D. Por isso, a velocidade é relativa e aparece em larguras de ombro por segundo (LO/s), não em metros por segundo.")
        }
    }

    private var cameraContent: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            Color.black.opacity(0.08)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if viewModel.currentPhase == .framing {
                FramingOverlayView(
                    isFramed: viewModel.isProperlyFramed,
                    progress: viewModel.framingProgress
                )
            }

            // Mantém a visualização do esqueleto que foi adicionada na develop.
            if viewModel.currentPhase == .counting {
                BodySkeletonView(joints: viewModel.bodyJoints)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 16) {
                header

                if viewModel.currentPhase == .framing {
                    stancePicker
                }

                Spacer()

                if viewModel.currentPhase == .counting {
                    CountingOverlayView(
                        count: viewModel.punchCount,
                        lastPunch: viewModel.lastDetectedPunch,
                        lastSpeed: viewModel.lastPunchSpeed
                    )
                }

                Spacer()

                if viewModel.currentPhase == .counting {
                    finishButton
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: closeWorkout) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(Circle())
            }

            Spacer()

            Text(viewModel.currentPhase == .framing ? "ALINHAMENTO" : "TREINO")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(.white)

            Spacer()

            Button {
                isShowingInfo = true
            } label: {
                Image(systemName: "info")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var stancePicker: some View {
        VStack(spacing: 8) {
            Text("SUA BASE")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)

            Picker(
                "Base",
                selection: Binding(
                    get: { viewModel.userStance },
                    set: { viewModel.setStance($0) }
                )
            ) {
                ForEach(Stance.allCases, id: \.self) { stance in
                    Text(stance.displayName).tag(stance)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 24)
    }

    private var finishButton: some View {
        Button(action: finishWorkout) {
            Label("FINALIZAR", systemImage: "checkmark")
                .font(.headline.weight(.black))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }

    private func configureCamera() {
        let model = viewModel
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

    private func finishWorkout() {
        let generatedResult = viewModel.finishWorkout()
        resultsStore.add(generatedResult)
        stopCamera()

        withAnimation(.easeInOut(duration: 0.25)) {
            result = generatedResult
        }
    }

    private func restartWorkout() {
        viewModel.resetWorkout()
        result = nil
        configureCamera()
    }

    private func closeWorkout() {
        stopCamera()
        dismiss()
    }
}

struct FramingOverlayView: View {
    let isFramed: Bool
    let progress: Double

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 10) {
                Text(isFramed ? "MANTENHA A POSIÇÃO" : "ENQUADRE TODO O CORPO")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.black)

                ProgressView(value: progress)
                    .tint(isFramed ? .green : .orange)

                Text("Cabeça, mãos e tornozelos precisam aparecer na câmera.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black.opacity(0.70))
            }
            .padding(18)
            .background(.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 28)
            .padding(.bottom, 34)
        }
        .allowsHitTesting(false)
    }
}

struct CountingOverlayView: View {
    let count: Int
    let lastPunch: PunchType
    let lastSpeed: Double?

    var body: some View {
        VStack(spacing: 10) {
            Text(String(format: "%02d", count))
                .font(.system(size: 104, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.65), radius: 22)

            if lastPunch != .none {
                Text(lastPunch.rawValue)
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let lastSpeed {
                Text(String(format: "Último: %.2f LO/s", lastSpeed))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.58))
                    .clipShape(Capsule())
            }
        }
    }
}
