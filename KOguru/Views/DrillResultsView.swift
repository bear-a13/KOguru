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
        }
    }

    // MARK: - Imagem fixa dos Assets

    private func imageSection(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            topBackground

            Image("ringue")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        }
        .frame(width: width, height: height)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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

            Text("Boa! Você segurou o ritmo até o fim.")
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
                    title: "COMBOS",
                    value: "\(result.combosCompleted)",
                    unit: "COMPLETOS",
                    systemImage: "checkmark.seal.fill",
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
                    title: "GOLPES ERRADOS",
                    value: "\(result.wrongPunches)",
                    unit: "ERROS",
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
                ResultSummaryCard(
                    title: "TOTAL DE GOLPES",
                    value: "\(result.totalPunches)",
                    unit: "GOLPES",
                    systemImage: "target",
                    accentColor: topBackground,
                    contentColor: Color(
                        red: 205 / 255,
                        green: 220 / 255,
                        blue: 255 / 255
                    )
                )

            }

//            HStack(spacing: 14) {
//                ResultSummaryCard(
//                    title: "TAXA DE ACERTO",
//                    value: accuracyPercentage,
//                    unit: "%",
//                    systemImage: "chart.bar.fill",
//                    accentColor: Color(
//                        red: 34 / 255,
//                        green: 139 / 255,
//                        blue: 86 / 255
//                    ),
//                    contentColor: Color(
//                        red: 205 / 255,
//                        green: 245 / 255,
//                        blue: 216 / 255
//                    )
//                )
//
//                ResultSummaryCard(
//                    title: "TOTAL DE GOLPES",
//                    value: "\(result.totalPunches)",
//                    unit: "GOLPES",
//                    systemImage: "target",
//                    accentColor: topBackground,
//                    contentColor: Color(
//                        red: 205 / 255,
//                        green: 220 / 255,
//                        blue: 255 / 255
//                    )
//                )
//            }
        }
        .frame(maxWidth: 228)
    }

    

    // MARK: - Ação

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
            combosCompleted: 7,
            correctPunches: 21,
            wrongPunches: 4
        )
    )
}
