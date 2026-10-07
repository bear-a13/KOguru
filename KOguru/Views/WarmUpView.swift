//
//  WarmUpView.swift
//  KOguru
//
//  Created by Bernardo on 06/10/26.
//

import SwiftUI
import Combine
import AudioToolbox

struct WarmUpExercise: Identifiable {
    let id: Int
    let name: String
    let duration: Int
    let imageName: String
}

struct WarmUpView: View {
    @Environment(\.dismiss) private var dismiss

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let exercises: [WarmUpExercise] = [
        WarmUpExercise(id: 0, name: "ROTAÇÃO DE OMBROS", duration: 30, imageName: "CardCansado"),
        WarmUpExercise(id: 1, name: "ALONGAMENTO DE PULSOS", duration: 30, imageName: "CardSoco"),
        WarmUpExercise(id: 2, name: "ROTAÇÃO DE TRONCO", duration: 30, imageName: "CardGuarda"),
        WarmUpExercise(id: 3, name: "SALTOS LEVES", duration: 30, imageName: "CardCansado")
    ]

    private let topBackground = Color(red: 23 / 255, green: 32 / 255, blue: 51 / 255)
    private let buttonColor = Color(red: 181 / 255, green: 46 / 255, blue: 47 / 255)

    @State private var currentIndex = 0
    @State private var secondsRemaining = 30

    var body: some View {
        ZStack {
            Color.backgroundColorBlue
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        Image(currentExercise.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut(duration: 0.35), value: currentIndex)
                            .accessibilityHidden(true)

                        exerciseCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }

                PrimaryActionButton(
                    title: "FINALIZAR AQUECIMENTO",
                    systemImage: "checkmark",
                    backgroundColor: buttonColor,
                    accessibilityHint: "Encerra o aquecimento e retorna para a tela inicial",
                    action: { dismiss() }
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            tick()
        }
    }

    // MARK: - Cabeçalho

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "xmark") {
                dismiss()
            }
            .accessibilityLabel("Encerrar aquecimento")
            .accessibilityHint("Toque duas vezes para parar e sair")

            Spacer()

            Text("AQUECIMENTO")
                .font(Font.custom("Anton", size: 32))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)

            Spacer()

            CircleIconButton(systemName: "figure.flexibility") {}
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 8)
    }

    // MARK: - Exercício atual

    private var exerciseCard: some View {
        VStack(spacing: 16) {
            Text("EXERCÍCIO \(currentIndex + 1) DE \(exercises.count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.7))
                .accessibilityLabel("Exercício \(currentIndex + 1) de \(exercises.count)")

            Text(currentExercise.name)
                .font(Font.custom("Anton", size: 32))
                .foregroundStyle(Color.amareloCard)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            // Barra de progresso decrescente
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.3))

                    Capsule()
                        .fill(Color.amareloCard)
                        .frame(width: max(0, geo.size.width * progress))
                        .animation(.linear, value: secondsRemaining)
                }
            }
            .frame(height: 14)
            .frame(maxWidth: .infinity)

            Text(formattedTime)
                .font(Font.custom("Anton", size: 64))
                .foregroundColor(.white)
                .monospacedDigit()
                .accessibilityLabel("Tempo restante: \(secondsRemaining) segundos")
        }
        .padding(20)
        .background(topBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Lógica do ciclo

    private var currentExercise: WarmUpExercise {
        exercises[currentIndex]
    }

    private var progress: CGFloat {
        guard currentExercise.duration > 0 else { return 0 }
        return CGFloat(secondsRemaining) / CGFloat(currentExercise.duration)
    }

    private var formattedTime: String {
        let seconds = max(secondsRemaining, 0)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func tick() {
        guard secondsRemaining > 0 else { return }

        secondsRemaining -= 1

        guard secondsRemaining == 0 else { return }

        AudioServicesPlaySystemSound(1057)

        if currentIndex < exercises.count - 1 {
            currentIndex += 1
            secondsRemaining = currentExercise.duration
        } else {
            dismiss()
        }
    }
}

#Preview {
    WarmUpView()
}
