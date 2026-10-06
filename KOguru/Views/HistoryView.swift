//
//  HistoryView.swift
//  KOguru
//
//  Created by Bernardo on 06/10/26.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var resultsStore = ResultsStore()

    private let topBackground = Color(red: 23 / 255, green: 32 / 255, blue: 51 / 255)
    private let bottomBackground = Color(red: 47 / 255, green: 62 / 255, blue: 102 / 255)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.backgroundColorBlue
                    .ignoresSafeArea()
               
            }
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                header

                if resultsStore.sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            summaryGrid
                            chartSection
                            sessionsList
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Cabeçalho

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "xmark") {
                dismiss()
            }

            Spacer()

            Text("HISTÓRICO")
                .font(Font.custom("Anton", size: 32))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)

            Spacer()

            CircleIconButton(systemName: "trophy") {}
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 8)
    }

    // MARK: - Estado vazio

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "trophy")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))

            Text("NENHUM TREINO AINDA")
                .font(Font.custom("Anton", size: 26))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Complete um treino de Jab e Direto para começar a acompanhar seu progresso aqui.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Resumo

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            HistoryStatCard(
                title: "TREINOS",
                value: "\(totalSessions)",
                unit: totalSessions == 1 ? "SESSÃO" : "SESSÕES",
                systemImage: "figure.boxing",
                accentColor: Color.vermelhoCard,
                contentColor: Color(red: 255 / 255, green: 207 / 255, blue: 209 / 255)
            )
            HistoryStatCard(
                title: "GOLPES",
                value: "\(totalPunches)",
                unit: totalPunches == 1 ? "GOLPE" : "GOLPES",
                systemImage: "target",
                accentColor: Color.amareloCard,
                contentColor: Color(red: 255 / 255, green: 241 / 255, blue: 196 / 255)
            )
            HistoryStatCard(
                title: "TEMPO",
                value: formatDuration(totalDuration),
                unit: "TOTAL",
                systemImage: "clock.fill",
                accentColor: Color.azulCard,
                contentColor: Color(red: 205 / 255, green: 220 / 255, blue: 255 / 255)
            )
            HistoryStatCard(
                title: "RECORDE",
                value: formatSpeed(recordSpeed),
                unit: "m/s",
                systemImage: "bolt.fill",
                accentColor: Color.azulResultadosFora,
                contentColor: Color(red: 205 / 255, green: 220 / 255, blue: 255 / 255)
            )
        }
    }

    // MARK: - Gráfico semanal

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ÚLTIMOS 7 DIAS")
                .font(Font.custom("Anton", size: 20))
                .foregroundStyle(Color.white)

            Chart(last7Days) { entry in
                BarMark(
                    x: .value("Dia", entry.day, unit: .day),
                    y: .value("Golpes", entry.punches)
                )
                .foregroundStyle(Color.amareloCard)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(topBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Lista de sessões

    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ÚLTIMOS TREINOS")
                .font(Font.custom("Anton", size: 20))
                .foregroundStyle(Color.white)

            ForEach(resultsStore.sessions) { session in
                historyRow(session)
            }
        }
    }

    private func historyRow(_ session: ResultsModel) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDay(session.startedAt))
                    .font(Font.custom("Anton", size: 20))
                    .foregroundStyle(Color.white)

                Text(formatHour(session.startedAt))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.totalPunches) GOLPES")
                    .font(Font.custom("Anton", size: 18))
                    .foregroundStyle(Color.amareloCard)

                Text("Vel. máx: \(formatSpeed(session.maximumSpeed)) m/s")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(bottomBackground.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Agregações

    private var totalSessions: Int {
        resultsStore.sessions.count
    }

    private var totalPunches: Int {
        resultsStore.sessions.reduce(0) { $0 + $1.totalPunches }
    }

    private var totalDuration: TimeInterval {
        resultsStore.sessions.reduce(0) { $0 + $1.duration }
    }

    private var recordSpeed: Double {
        resultsStore.sessions.map(\.maximumSpeed).max() ?? 0
    }

    private struct DayPunches: Identifiable {
        let day: Date
        let punches: Int

        var id: Date { day }
    }

    private var last7Days: [DayPunches] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()

        return days.map { day in
            let punches = resultsStore.sessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.totalPunches }
            return DayPunches(day: day, punches: punches)
        }
    }

    // MARK: - Formatação

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatSpeed(_ speed: Double) -> String {
        guard speed > 0 else { return "0" }
        return speed >= 10
            ? String(format: "%.0f", speed)
            : String(format: "%.1f", speed)
    }

    private func formatDay(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle()
                .day().month().year()
                .locale(Locale(identifier: "pt_BR"))
        )
    }

    private func formatHour(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle()
                .hour().minute()
                .locale(Locale(identifier: "pt_BR"))
        )
    }
}

// MARK: - Cartão de estatística

struct HistoryStatCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let accentColor: Color
    let contentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Font.custom("Anton", size: 15))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: -8) {
                    Text(value)
                        .font(Font.custom("Anton", size: 30))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(unit)
                        .font(Font.custom("Anton", size: 11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(contentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(6)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

#Preview {
    HistoryView()
}
