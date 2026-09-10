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
                                .accessibilityLabel("Excelente! Combo concluído.")

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
                            }
                            .padding()
                            .background(Color.vermelhoCard.opacity(0.6))
                            .cornerRadius(30)
                            .padding(.bottom, 60)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(accessibilityComboLabel(for: combo))
                            .accessibilityValue(accessibilityComboValue(for: combo))
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            
            cameraManager.frameDelegate = { sampleBuffer in
                workoutViewModel.processFrame(sampleBuffer)
            }
        }
        .onDisappear {
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
