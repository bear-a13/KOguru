import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel = WorkoutViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            //FRAME DA CAMERA
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            if viewModel.currentPhase == .framing {
                FramingOverlayView(isFramed: viewModel.isProperlyFramed)
            }

            VStack {
                //CABEÇARIO
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("ALinhamento")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: {
                            // COLOCAR AQUI O LINK PARA O INFO
                    }) {
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

                // Conteúdo central
                switch viewModel.currentPhase {
                case .framing:
                    EmptyView()
                case .counting:
                    CountingOverlayView(count: viewModel.punchCount, lastPunch: viewModel.lastDetectedPunch)
                case .finished:
                    HomeView()
                }

                Spacer()

                if viewModel.currentPhase == .counting {
                    Button(action: {
                        withAnimation {
                            viewModel.currentPhase = .finished
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                            Text("FINALIZAR")
                                .font(.system(size: 16, weight: .bold))
                            
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            cameraManager.frameDelegate = { sampleBuffer in
                viewModel.processFrame(sampleBuffer)
            }
        }
    }
}

//
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
                
            // logica para criar uma animação depois
//                .opacity(isFramed ? (1) : (0.5))
            

            Text(isFramed ? "Corpo enquadrado! Iniciando..." : "Enquadre seu corpo na câmera")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.6))
                .cornerRadius(20)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
        
}


struct CountingOverlayView: View {
    var count: Int
    var lastPunch: PunchType

    var body: some View {
        VStack(spacing: 12) {
            Text(String(format: "%02d", count))
                .font(.system(size: 110, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 40)

            if lastPunch != .none {
                Text(lastPunch.rawValue)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
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
