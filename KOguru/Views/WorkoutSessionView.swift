import SwiftUI
import AVFoundation

struct WorkoutSessionView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel = WorkoutViewModel()
    @StateObject private var resultsStore = ResultsStore()
    @Environment(\.dismiss) private var dismiss
    @State private var showTutorial = false

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
        .onAppear {
            // Mantém a tela ligada durante o treino.
            UIApplication.shared.isIdleTimerDisabled = true
            configureCamera()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            stopCamera()
        }
        .alert("Como a velocidade funciona?", isPresented: $isShowingInfo) {
            Button("Entendi", role: .cancel) {}
        } message: {
            Text(
                "A câmera usa pose 2D. Por isso, a velocidade é relativa "
                    + "por conta disso a velocidade é dada em m/s."
                    
            )
        }
    }

    // MARK: - Interface da câmera

    private var cameraContent: some View {
        ZStack {
            // FRAME DA CÂMERA
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            if viewModel.currentPhase == .framing {
                FramingOverlayView(
                    isFramed: viewModel.isProperlyFramed
                )
            }

            if viewModel.currentPhase == .counting {
                BodySkeletonView(joints: viewModel.bodyJoints)
            }

            VStack {
                // CABEÇALHO
                HStack {
                    Button(action: closeWorkout) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("JAB E DIRETO")
                        .font(Font.custom("Anton", size: 36))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        isShowingInfo = true
                    } label: {
                        Image(systemName: "info")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                Spacer()

                // CONTROLE DAS TELAS
                switch viewModel.currentPhase {
                case .framing:
                    EmptyView()

                case .counting:
                    CountingOverlayView(
                        count: viewModel.punchCount,
                        lastPunch: viewModel.lastDetectedPunch
                    )

                case .finished:
                    // O resultado é exibido pelo Group principal.
                    EmptyView()
                }

                Spacer()

                if viewModel.currentPhase == .counting {
                    Button(action: finishWorkout) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 26, weight: .bold))

                            Text("FINALIZAR")
                                .font(Font.custom("Anton", size: 40))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.vermelhoCard)
                        .cornerRadius(16)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }

    // MARK: - Câmera

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

    // MARK: - Fluxo de resultados 

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
        UIApplication.shared.isIdleTimerDisabled = false
        stopCamera()
        dismiss()
    }
}

// MARK: - Overlay de enquadramento

struct FramingOverlayView: View {
    var isFramed: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("frame")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// MARK: - Contador

struct CountingOverlayView: View {
    var count: Int
    var lastPunch: PunchType

    var body: some View {
        ZStack {
            VStack {
                Text(String(format: "%02d", count))
                    .font(Font.custom("Sedgwick Ave Display", size: 110))
                    .foregroundColor(.white)
                    .shadow(radius: 40)

                if lastPunch != .none {
                    Text(lastPunch.rawValue)
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                }

                Spacer()
            }
        }
    }
}

struct FinishedOverlayView: View {
    var totalPunches: Int
    var onRestart: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("TREINO FINALIZADO")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.black)

            Text("\(totalPunches) socos registrados")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black.opacity(0.8))

            Button(action: onRestart) {
                Text("REINICIAR")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(12)
            }
        }
        .padding(30)
        .background(Color.white.opacity(0.95))
        .cornerRadius(24)
        .padding(.horizontal, 40)
    }
}
