import Foundation
import AVFoundation
import Combine

class DrillManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var isDrillActive = false
    @Published var currentCombo: DrillCombo?
    @Published var currentStepIndex: Int = 0
    @Published var isComboCompleted = false
    
    private let combos: [DrillCombo] = [
        // SE QUISER COLOCAR MAIS COMBOS Ë SO COLOCAR AQUI
      
                DrillCombo(textToSpeak: "Jab", sequence: [.jab]),
                DrillCombo(textToSpeak: "Direto", sequence: [.direto]),
                // Duplas de Volume e Entrada
                DrillCombo(textToSpeak: "Jab, Jab", sequence: [.jab, .jab]),
                DrillCombo(textToSpeak: "Jab, Direto", sequence: [.jab, .direto]),
                DrillCombo(textToSpeak: "Direto, Jab", sequence: [.direto, .jab]),
                DrillCombo(textToSpeak: "Direto, Direto", sequence: [.direto, .direto]),
                
                // Trios Clássicos
                DrillCombo(textToSpeak: "Jab, Jab, Direto", sequence: [.jab, .jab, .direto]),
                DrillCombo(textToSpeak: "Jab, Direto, Jab", sequence: [.jab, .direto, .jab]),
                DrillCombo(textToSpeak: "Direto, Jab, Direto", sequence: [.direto, .jab, .direto]),
                DrillCombo(textToSpeak: "Jab, Direto, Direto", sequence: [.jab, .direto, .direto]),
                DrillCombo(textToSpeak: "Jab, Jab, Jab", sequence: [.jab, .jab, .jab]),
                
                // Sequências Longas e Volume Avançado
                DrillCombo(textToSpeak: "Jab, Jab, Jab, Direto", sequence: [.jab, .jab, .jab, .direto]),
                DrillCombo(textToSpeak: "Jab, Direto, Jab, Direto", sequence: [.jab, .direto, .jab, .direto]),
                DrillCombo(textToSpeak: "Direto, Jab, Jab, Direto", sequence: [.direto, .jab, .jab, .direto]),
                DrillCombo(textToSpeak: "Jab, Jab, Direto, Direto", sequence: [.jab, .jab, .direto, .direto]),
                DrillCombo(textToSpeak: "Jab, Direto, Jab, Direto, Jab", sequence: [.jab, .direto, .jab, .direto, .jab])
            ]
    
    func startDrill() {
        isDrillActive = true
        nextCommand()
    }
    
    func stopDrill() {
        isDrillActive = false
        synthesizer.stopSpeaking(at: .immediate)
        currentCombo = nil
    }
    
    func processPunch(_ detectedPunch: PunchType) {
        guard isDrillActive, !isComboCompleted, let combo = currentCombo else { return }
        guard detectedPunch != .none else { return }
        
        let expectedPunch = combo.sequence[currentStepIndex]
        
        
        if detectedPunch == expectedPunch {
            currentStepIndex += 1
            
            if currentStepIndex >= combo.sequence.count {
                isComboCompleted = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.nextCommand()
                }
            }
        }
    }
    
    private func nextCommand() {
        guard isDrillActive else { return }
        
        let nextCombo = combos.randomElement() ?? combos[0]
        
        currentCombo = nextCombo
        currentStepIndex = 0
        isComboCompleted = false
        
        let utterance = AVSpeechUtterance(string: nextCombo.textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
    }
}
