//
//  DrillResultsView.swift
//  KOguru
//

import SwiftUI
import Foundation

struct DrillResultsView: View {
    let result: DrillResultsModel
    let onDone: () -> Void
    let onRestart: () -> Void

    @State private var visibleTier: Int = 0

    init(
        result: DrillResultsModel,
        onRestart: @escaping () -> Void = {},
        onDone: @escaping () -> Void = {}
    ) {
        self.result = result
        self.onRestart = onRestart
        self.onDone = onDone
    }

    private let topBackground = Color(red: 23 / 255, green: 32 / 255, blue: 51 / 255)
    private let bottomBackground = Color(red: 47 / 255, green: 62 / 255, blue: 102 / 255)
    private let buttonColor = Color(red: 181 / 255, green: 46 / 255, blue: 47 / 255)

    // aqui coloca como vai querer os niveis para consegui as estrelas 
    private var targetTier: Int {
        if result.combosCompleted >= 15 { return 3 }
        else if result.combosCompleted >= 10 { return 2 }
        else if result.combosCompleted >= 5 { return 1 }
        else { return 0 }
    }

    var body: some View {
        GeometryReader { geometry in
            let imageHeight = geometry.size.height
                * (geometry.size.height < 720 ? 0.48 : 0.56)

            ZStack {
                bottomBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    imageSection(
                        width: geometry.size.width,
                        height: imageHeight
                    )
                    .padding(.top, -4)

                    VStack(spacing: 0) {
                        titleSection

                        metrics
                            .padding(.top, 18)

                        Spacer(minLength: 10)

                        actions
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 18)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .background(bottomBackground)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .top)
            .onAppear {
                triggerBeltAnimation()
            }
        }
    }

    // MARK: - Imagens com Crossfade

    private func imageSection(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            topBackground
            
            // Base: Cinturão apagado sempre no fundo
            Image("cinturao-sem-estrela")
                .resizable()
                .scaledToFill()
            
            // Camada 1 Estrela (Aparece se tier >= 1)
            if visibleTier >= 1 {
                Image("cinturao-uma-estrela")
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
            
            // Camada 2 Estrelas (Aparece se tier >= 2)
            if visibleTier >= 2 {
                Image("cinturao-duas-estrelas")
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
            
            // Camada 3 Estrelas (Aparece se tier >= 3)
            if visibleTier >= 3 {
                Image("cinturao-tres-estrelas")
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    
    private func triggerBeltAnimation() {
        guard targetTier > 0 else { return } // Se for zero estrelas, não precisa animar
        
        // Loop para animar as estrelas progressivamente como um "Level Up"
        for tier in 1...targetTier {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(tier) * 0.7)) {
                withAnimation(.easeIn(duration: 0.5)) {
                    visibleTier = tier
                }
            }
        }
    }

    // MARK: - Textos

    private var titleSection: some View {
        VStack(spacing: 7) {
            Text("FIM DO ROUND!")
                .font(Font.custom("Anton", size: 38))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text("Seus treinos estão dando resultado, hein?")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Indicadores

    private var metrics: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
               
                ResultSummaryCard(
                    title: "ACERTOS",
                    value: "\(result.correctPunches)",
                    unit: "GOLPES",
                    systemImage: "target",
                    accentColor: Color(
                        red: 169 / 255,
                        green: 48 / 255,
                        blue: 52 / 255
                    ),
                    contentColor: Color(
                        red: 255 / 255,
                        green: 207 / 255,
                        blue: 209 / 255
                    )
                )

                ResultSummaryCard(
                    title: "COMBOS",
                    value: "\(result.combosCompleted)",
                    unit: "COMPLETOS",
                    systemImage: "star.fill",
                    accentColor: Color.azulResultadosFora,
                    contentColor: Color(
                        red: 205 / 255,
                        green: 220 / 255,
                        blue: 255 / 255
                    )
                )
                
                ResultSummaryCard(
                    title: "ERRADOS",
                    value: "\(result.wrongPunches)",
                    unit: "GOLPES",
                    systemImage: "xmark",
                    accentColor: Color(
                        red: 221 / 255,
                        green: 157 / 255,
                        blue: 0 / 255
                    ),
                    contentColor: Color(
                        red: 255 / 255,
                        green: 241 / 255,
                        blue: 196 / 255
                    )
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ações

    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryActionButton(
                title: "FINALIZAR",
                systemImage: "checkmark",
                backgroundColor: buttonColor,
                accessibilityHint: "Fecha o resultado e retorna para a tela inicial",
                action: onDone
            )

            PrimaryActionButton(
                title: "TREINAR NOVAMENTE",
                systemImage: "arrow.counterclockwise",
                backgroundColor: topBackground,
                accessibilityHint: "Recomeça o drill do zero",
                action: onRestart
            )
        }
    }
}

#Preview {
    DrillResultsView(
        result: DrillResultsModel(
            startedAt: Date().addingTimeInterval(-60),
            endedAt: Date(),
            combosCompleted: 3, // Forçando acima de 20 para testar a animação completa das 3 estrelas
            correctPunches: 60,
            wrongPunches: 4
        )
    )
}
