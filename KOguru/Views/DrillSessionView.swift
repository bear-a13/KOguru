import SwiftUI

struct DrillSessionView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var drillManager = DrillManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            if workoutViewModel.currentPhase == .counting {
                BodySkeletonView(joints: workoutViewModel.bodyJoints)
            }
            
            if workoutViewModel.currentPhase == .framing {
                FramingOverlayView(isFramed: workoutViewModel.isProperlyFramed)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        drillManager.stopDrill()
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
                    Text("DRILL")
                        .font(Font.custom("Anton", size: 36))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                if workoutViewModel.currentPhase == .counting {
                    VStack(alignment: .center, spacing: 4) {
                        if drillManager.isComboCompleted {
                            Text("EXCELENTE!")
                                .font(.system(size: 48, weight: .black))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.vermelhoCard.opacity(0.6))
                                .cornerRadius(30)

                        } else if let combo = drillManager.currentCombo {
                            VStack(alignment: .center) {
                                ForEach(Array(combo.sequence.enumerated()), id: \.offset) { index, punch in
                                    let isCompleted = index < drillManager.currentStepIndex
                                    let isLast = index == combo.sequence.count - 1
                                    
                                    Text(punchName(for: punch) + (isLast ? "" : ""))
                                        .font(.system(size: 36, weight: .black))
                                        .foregroundColor(isCompleted ? .white : .white)
                                        .opacity(isCompleted ? 0.4 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: drillManager.currentStepIndex)
                                }
                            }.padding()
                                .background(Color.vermelhoCard.opacity(0.6))
                                .cornerRadius(30)
                            .padding(.bottom, 60)
                        }
                    }
                    .padding(.bottom,60)
                    
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
                    // Mantém a tela sempre ligada
                    UIApplication.shared.isIdleTimerDisabled = true
                    
                    cameraManager.frameDelegate = { sampleBuffer in
                        workoutViewModel.processFrame(sampleBuffer)
                    }
                }
                .onDisappear {
                    // Devolve o controle de bloqueio de tela para o iOS ao sair
                    UIApplication.shared.isIdleTimerDisabled = false
    }
        .onChange(of: workoutViewModel.currentPhase) { newPhase in
            if newPhase == .counting {
                drillManager.startDrill()
            }
        }
        .onChange(of: workoutViewModel.lastDetectedPunch) { newPunch in
            drillManager.processPunch(newPunch)
        }
    }
    
    private func punchName(for punch: PunchType) -> String {
        switch punch {
        case .jab: return "JAB"
        case .direto: return "DIRETO"
        default: return ""
        }
    }
}
