//
//  ShareStatCardView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 07/10/26.
//
import SwiftUI

// Cartão 9:16 (vertical, formato Stories) para compartilhar/baixar.
// Usa os templates story do app como fundo ocupando a tela toda e sobrescreve
// os módulos de resultado em HStack na parte inferior da imagem.
struct ShareStatCardView: View {
    enum Kind {
        case workout(ResultsModel)
        case drill(DrillResultsModel)
    }

    let kind: Kind

    static let designWidth: CGFloat = 720
    static let designHeight: CGFloat = 1280

    private static let red = Color(red: 181 / 255, green: 46 / 255, blue: 47 / 255)
    private static let lightRed = Color(
        red: 255 / 255,
        green: 207 / 255,
        blue: 209 / 255
    )
    private static let yellow = Color(red: 221 / 255, green: 157 / 255, blue: 0 / 255)
    private static let lightYellow = Color(
        red: 255 / 255,
        green: 241 / 255,
        blue: 196 / 255
    )
    private static let blue = Color(red: 51 / 255, green: 87 / 255, blue: 148 / 255)
    private static let lightBlue = Color(
        red: 205 / 255,
        green: 220 / 255,
        blue: 255 / 255
    )

    // Template story escolhido pelo tipo de treino:
    // - Jab e Direto (treino livre): sempre InstagramStoryJabeDIRETO
    // - Drill: InstagramStoryCinturao{estrelas} conforme as estrelas do cinturão
    private var storyImageName: String {
        switch kind {
        case .workout:
            return "InstagramStoryJabeDIRETO"
        case .drill(let result):
            return "InstagramStoryCinturao\(result.starTier)"
        }
    }

    var body: some View {
        ZStack {
            Image(storyImageName)
                .resizable()
                .scaledToFill()
                .frame(
                    width: ShareStatCardView.designWidth,
                    height: ShareStatCardView.designHeight
                )
                .clipped()

            VStack {
                Spacer()
                metricsHStack
                    .padding(.horizontal, 24)
                    .padding(.bottom, 270)
            }
        }
        .frame(
            width: ShareStatCardView.designWidth,
            height: ShareStatCardView.designHeight
        )
        
    }

    // MARK: - Módulos de resultado

    @ViewBuilder
    private var metricsHStack: some View {
        switch kind {
        case .workout(let result):
            HStack(spacing: 20) {
                statCard(
                    title: "Nº DE GOLPES",
                    value: "\(result.totalPunches)",
                    unit: result.totalPunches == 1 ? "GOLPE" : "GOLPES",
                    systemImage: "target",
                    accentColor: ShareStatCardView.red,
                    contentColor: ShareStatCardView.lightRed,
                    width: 210
                )

                statCard(
                    title: "VELOCIDADE",
                    value: formattedMaximumSpeed(result.maximumSpeed),
                    unit: result.speedUnit.symbol.uppercased(),
                    systemImage: "wind",
                    accentColor: ShareStatCardView.yellow,
                    contentColor: ShareStatCardView.lightYellow,
                    width: 210
                )
            }

        case .drill(let result):
            HStack(spacing: 16) {
                statCard(
                    title: "ACERTOS",
                    value: "\(result.correctPunches)",
                    unit: "GOLPES",
                    systemImage: "target",
                    accentColor: ShareStatCardView.red,
                    contentColor: ShareStatCardView.lightRed,
                    width: 120
                )

                statCard(
                    title: "COMBOS",
                    value: "\(result.combosCompleted)",
                    unit: "COMPLETOS",
                    systemImage: "star.fill",
                    accentColor: ShareStatCardView.blue,
                    contentColor: ShareStatCardView.lightBlue,
                    width: 210
                )

                statCard(
                    title: "ERRADOS",
                    value: "\(result.wrongPunches)",
                    unit: "GOLPES",
                    systemImage: "xmark",
                    accentColor: ShareStatCardView.yellow,
                    contentColor: ShareStatCardView.lightYellow,
                    width: 210
                )
            }
        }
    }

    private func statCard(
        title: String,
        value: String,
        unit: String,
        systemImage: String,
        accentColor: Color,
        contentColor: Color,
        width: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(Font.custom("Anton", size: 20))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 30)

            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .bold))

                VStack(alignment: .leading, spacing: -6) {
                    Text(value)
                        .font(Font.custom("Anton", size: 34))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(unit)
                        .font(Font.custom("Anton", size: 20))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(contentColor)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .padding(5)
            .padding(.top, -2)
        }
        .frame(width: width, height: 130)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Formatação

    private func formattedMaximumSpeed(_ speed: Double) -> String {
        guard speed > 0 else { return "0" }
        if speed >= 10 {
            return String(format: "%.0f", speed)
        }
        return String(format: "%.1f", speed)
    }
}

#Preview("Treino Livre") {
    ShareStatCardView(
        kind: .workout(
            ResultsModel(
                startedAt: Date().addingTimeInterval(-48),
                endedAt: Date(),
                stance: .orthodox,
                speedUnit: .shoulderWidthsPerSecond,
                punches: [
                    PunchResult(type: .jab, timestamp: 2.4, peakSpeed: 4.1, duration: 0.42),
                    PunchResult(type: .cross, timestamp: 4.1, peakSpeed: 5.3, duration: 0.47)
                ]
            )
        )
    )
    .frame(width: 360, height: 640)
}

#Preview("Modo Drill - 3 estrelas") {
    ShareStatCardView(
        kind: .drill(
            DrillResultsModel(
                startedAt: Date().addingTimeInterval(-60),
                endedAt: Date(),
                combosCompleted: 12,
                correctPunches: 60,
                wrongPunches: 4
            )
        )
    )
    .frame(width: 360, height: 640)
}
