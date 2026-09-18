import Foundation
import AVFoundation
import Combine

class DrillManager: ObservableObject {
    static let roundDuration: TimeInterval = 60

    private let synthesizer = AVSpeechSynthesizer()

    @Published var isDrillActive = false
    @Published var currentCombo: DrillCombo?
    @Published var currentStepIndex: Int = 0
    @Published var isComboCompleted = false
    @Published var lastWasWrongPunch = false
    @Published var timeRemaining: TimeInterval = DrillManager.roundDuration
    @Published var isRoundOver = false

    private(set) var combosCompleted = 0
    private(set) var correctPunches = 0
    private(set) var wrongPunches = 0

    private var drillStartedAt: Date?
    private var roundTimer: Timer?

    private let combos: [DrillCombo] = [
        // SE QUISER COLOCAR MAIS COMBOS Ë SO COLOCAR AQUI

        DrillCombo(textToSpeak: "Jeb", sequence: [.jab]),
        DrillCombo(textToSpeak: "Direto", sequence: [.cross]),
        // Duplas de Volume e Entrada
        DrillCombo(textToSpeak: "Jeb, Jeb", sequence: [.jab, .jab]),
        DrillCombo(textToSpeak: "Jeb, Direto", sequence: [.jab, .cross]),
        DrillCombo(textToSpeak: "Direto, Jeb", sequence: [.cross, .jab]),
        DrillCombo(textToSpeak: "Direto, Direto", sequence: [.cross, .cross]),

        // Trios Clássicos
        DrillCombo(textToSpeak: "Jeb, Jeb, Direto", sequence: [.jab, .jab, .cross]),
        DrillCombo(textToSpeak: "Jeb, Direto, Jeb", sequence: [.jab, .cross, .jab]),
        DrillCombo(textToSpeak: "Direto, Jeb, Direto", sequence: [.cross, .jab, .cross]),
        DrillCombo(textToSpeak: "Jeb, Direto, Direto", sequence: [.jab, .cross, .cross]),
        DrillCombo(textToSpeak: "Jeb, Jeb, Jeb", sequence: [.jab, .jab, .jab]),

        // Sequências Longas e Volume Avançado
        DrillCombo(textToSpeak: "Jeb, Jeb, Jeb, Direto", sequence: [.jab, .jab, .jab, .cross]),
        DrillCombo(textToSpeak: "Jeb, Direto, Jeb, Direto", sequence: [.jab, .cross, .jab, .cross]),
        DrillCombo(textToSpeak: "Direto, Jeb, Jeb, Direto", sequence: [.cross, .jab, .jab, .cross]),
        DrillCombo(textToSpeak: "Jeb, Jeb, Direto, Direto", sequence: [.jab, .jab, .cross, .cross]),
        DrillCombo(textToSpeak: "Jeb, Direto, Jeb, Direto, Jeb", sequence: [.jab, .cross, .jab, .cross, .jab])
    ]

    // MARK: - Controle do drill

    func startDrill() {
        isDrillActive = true
        combosCompleted = 0
        correctPunches = 0
        wrongPunches = 0
        isRoundOver = false
        isComboCompleted = false
        lastWasWrongPunch = false
        timeRemaining = Self.roundDuration
        drillStartedAt = Date()

        startRoundTimer()
        nextCommand()
    }

    func stopDrill() {
        isDrillActive = false
        isRoundOver = false
        isComboCompleted = false
        roundTimer?.invalidate()
        roundTimer = nil
        synthesizer.stopSpeaking(at: .immediate)
        currentCombo = nil
    }

    func makeResults() -> DrillResultsModel {
        DrillResultsModel(
            startedAt: drillStartedAt ?? Date(),
            endedAt: Date(),
            combosCompleted: combosCompleted,
            correctPunches: correctPunches,
            wrongPunches: wrongPunches
        )
    }

    // MARK: - Processamento de golpes

    func processPunch(_ detectedPunch: PunchType) {
        guard isDrillActive, !isComboCompleted, let combo = currentCombo else { return }
        guard detectedPunch != .none else { return }

        let expectedPunch = combo.sequence[currentStepIndex]

        if detectedPunch == expectedPunch {
            correctPunches += 1
            currentStepIndex += 1

            if currentStepIndex >= combo.sequence.count {
                combosCompleted += 1
                isComboCompleted = true
                lastWasWrongPunch = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.nextCommand()
                }
            }
        } else {
            wrongPunches += 1
            lastWasWrongPunch = true
            currentStepIndex = 0

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.lastWasWrongPunch = false
            }
        }
    }

    // MARK: - Round

    private func startRoundTimer() {
        roundTimer?.invalidate()
        roundTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard isDrillActive else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1
        }

        if timeRemaining <= 0 {
            endRound()
        }
    }

    private func endRound() {
        roundTimer?.invalidate()
        roundTimer = nil
        isDrillActive = false
        isComboCompleted = false
        isRoundOver = true
        synthesizer.stopSpeaking(at: .immediate)
        currentCombo = nil
    }

    // MARK: - Comandos

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
