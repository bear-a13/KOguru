//
//  ResultsView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 08/09/26.
//
import SwiftUI
import Foundation

struct ResultsView: View {
    let result: ResultsModel
    let onDone: () -> Void

    init(
        result: ResultsModel,
        onRestart _: @escaping () -> Void = {},
        onDone: @escaping () -> Void = {}
    ) {
        self.result = result
        self.onDone = onDone
    }

    private let topBackground = Color( red: 23 / 255, green: 32 / 255, blue: 51 / 255)

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

                        finishButton
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
            Text("EI, MANDOU BEM!")
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
        HStack(spacing: 14) {
            ResultSummaryCard(
                title: "Nº DE GOLPES",
                value: "\(result.totalPunches)",
                unit: result.totalPunches == 1 ? "GOLPE" : "GOLPES",
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
                title: "VELOCIDADE",
                value: formattedMaximumSpeed,
                
                unit: result.speedUnit.symbol.uppercased(),
                systemImage: "wind",
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
        .frame(maxWidth: 228)
    }

    private var formattedMaximumSpeed: String {
        guard result.maximumSpeed > 0 else { return "0" }

        if result.maximumSpeed >= 10 {
            return String(format: "%.0f", result.maximumSpeed)
        }

        return String(format: "%.1f", result.maximumSpeed)
    }

    // MARK: - Ação

    private var finishButton: some View {
        Button(action: onDone) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .bold))

                Text("FINALIZAR")
                    .font(Font.custom("Anton", size: 40))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 57)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Fecha o resultado e retorna para a tela inicial")
    }
}

private struct ResultSummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let accentColor: Color
    let contentColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(Font.custom("Anton", size: 14))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 28)

            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 23, weight: .bold))

                VStack(alignment: .leading, spacing: -3) {
                    Text(value)

                        .font(Font.custom("Anton", size: 31))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Text(unit)
                        .accessibilityLabel("metros por segundo")

                        .font(Font.custom("Anton", size: 13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(contentColor)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .padding(5)
            .padding(.top, -3)
        }
        .frame(width: 107, height: 116)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

#Preview {
    ResultsView(
        result: ResultsModel(
            startedAt: Date().addingTimeInterval(-48),
            endedAt: Date(),
            stance: .orthodox,
            speedUnit: .shoulderWidthsPerSecond,
            punches: [
                PunchResult(
                    type: .jab,
                    timestamp: 2.4,
                    peakSpeed: 4.1,
                    duration: 0.42
                ),
                PunchResult(
                    type: .cross,
                    timestamp: 4.1,
                    peakSpeed: 5.3,
                    duration: 0.47
                ),
                PunchResult(
                    type: .jab,
                    timestamp: 6.3,
                    peakSpeed: 4.8,
                    duration: 0.39
                )
            ]
        )
    )
}
