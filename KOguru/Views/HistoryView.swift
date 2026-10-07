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
    @StateObject private var drillResultsStore = DrillResultsStore()

    @State private var hasAppeared = false

    private let topBackground = Color(red: 23 / 255, green: 32 / 255, blue: 51 / 255)
    private let bottomBackground = Color(red: 47 / 255, green: 62 / 255, blue: 102 / 255)

    var body: some View {
        ZStack {
            Color.backgroundColorBlue
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                header

                if resultsStore.sessions.isEmpty && drillResultsStore.sessions.isEmpty {
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
        .onAppear {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.6)) {
                    hasAppeared = true
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hasAppeared)
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

            Text("Complete um treino de Jab e Direto ou um Drill para começar a acompanhar seu progresso aqui.")
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
                title: "COMBOS",
                value: "\(totalCombos)",
                unit: totalCombos == 1 ? "COMBO" : "COMBOS",
                systemImage: "star.fill",
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

            Chart(hasAppeared ? chartSegments : []) { segment in
                BarMark(
                    x: .value("Dia", segment.day, unit: .day),
                    y: .value("Quantidade", segment.value)
                )
                .foregroundStyle(by: .value("Atividade", segment.kind.label))
                .position(by: .value("Atividade", segment.kind.label))
                .cornerRadius(segment.kind == .combos ? 5 : 3)
                .opacity(segment.kind == .combos ? 0.95 : 1)
            }
            .chartForegroundStyleScale([
                ActivityKind.punches.label: Color.amareloCard,
                ActivityKind.combos.label: Color.vermelhoCard
            ])
            .chartLegend(position: .bottom, alignment: .center, spacing: 12)
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

            ForEach(recentSessions) { session in
                historyRow(session)
            }
        }
    }

    private func historyRow(_ session: SessionEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(Font.custom("Anton", size: 20))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(formatDay(session.date)) • \(formatHour(session.date))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.primary)
                    .font(Font.custom("Anton", size: 18))
                    .foregroundStyle(Color.amareloCard)

                Text(session.secondary)
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
        resultsStore.sessions.count + drillResultsStore.sessions.count
    }

    private var totalPunches: Int {
        resultsStore.sessions.reduce(0) { $0 + $1.totalPunches }
            + drillResultsStore.sessions.reduce(0) { $0 + $1.totalPunches }
    }

    private var totalDuration: TimeInterval {
        resultsStore.sessions.reduce(0) { $0 + $1.duration }
            + drillResultsStore.sessions.reduce(0) { $0 + $1.duration }
    }

    private var totalCombos: Int {
        drillResultsStore.sessions.reduce(0) { $0 + $1.combosCompleted }
    }

    // MARK: - Sessões recentes

    private struct SessionEntry: Identifiable {
        let id: UUID
        let name: String
        let date: Date
        let primary: String
        let secondary: String
    }

    private var recentSessions: [SessionEntry] {
        let workoutEntries = resultsStore.sessions.map { session in
            SessionEntry(
                id: session.id,
                name: "JAB E DIRETO",
                date: session.startedAt,
                primary: "\(session.totalPunches) GOLPES",
                secondary: "Vel. máx: \(formatSpeed(session.maximumSpeed)) m/s"
            )
        }

        let drillEntries = drillResultsStore.sessions.map { session in
            SessionEntry(
                id: session.id,
                name: "DRILL",
                date: session.startedAt,
                primary: "\(session.combosCompleted) COMBOS",
                secondary: "Precisão: \(Int(session.accuracy * 100))%"
            )
        }

        return (workoutEntries + drillEntries)
            .sorted { $0.date > $1.date }
    }

    private struct DayPunches: Identifiable {
        let day: Date
        let punches: Int

        var id: Date { day }
    }

    private enum ActivityKind {
        case punches
        case combos

        var label: String {
            switch self {
            case .punches: return "Golpes"
            case .combos: return "Combos"
            }
        }
    }

    private struct DaySegment: Identifiable {
        let id: UUID
        let day: Date
        let value: Int
        let kind: ActivityKind
    }

    private var chartSegments: [DaySegment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()

        return days.flatMap { day -> [DaySegment] in
            let punches = resultsStore.sessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.totalPunches }
            let combos = drillResultsStore.sessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.combosCompleted }

            var segments: [DaySegment] = []
            if punches > 0 {
                segments.append(
                    DaySegment(id: UUID(), day: day, value: punches, kind: .punches)
                )
            }
            if combos > 0 {
                segments.append(
                    DaySegment(id: UUID(), day: day, value: combos, kind: .combos)
                )
            }
            return segments
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
