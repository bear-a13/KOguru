//
//  OboardingView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 09/09/26.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    let onFinished: () -> Void

    init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    private let panelColor = Color(
        red: 23 / 255,
        green: 32 / 255,
        blue: 51 / 255
    )

    private let actionColor = Color(
        red: 190 / 255,
        green: 48 / 255,
        blue: 51 / 255
    )

    var body: some View {
        GeometryReader { geometry in
            TabView(
                selection: Binding(
                    get: { viewModel.selectedPageIndex },
                    set: { viewModel.selectPage($0) }
                )
            ) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                    onboardingPage(
                        page,
                        pageIndex: index,
                        geometry: geometry
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.28), value: viewModel.selectedPageIndex)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func onboardingPage(
        _ page: OnboardingPage,
        pageIndex: Int,
        geometry: GeometryProxy
    ) -> some View {
        let isCompactHeight = geometry.size.height < 720
        let panelHeight = geometry.size.height * (isCompactHeight ? 0.42 : 0.35)
        let imageHeight = geometry.size.height - panelHeight + 18

        return ZStack(alignment: .bottom) {
            heroImage(
                named: page.imageName,
                width: geometry.size.width,
                height: imageHeight
            )
            .frame(maxHeight: .infinity, alignment: .top)

            informationPanel(
                page,
                pageIndex: pageIndex,
                height: panelHeight,
                bottomInset: geometry.safeAreaInsets.bottom,
                compact: isCompactHeight
            )
        }
        .background(panelColor)
        .ignoresSafeArea()
    }

    private func heroImage(
        named imageName: String,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func informationPanel(
        _ page: OnboardingPage,
        pageIndex: Int,
        height: CGFloat,
        bottomInset: CGFloat,
        compact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(page.title)
                .font(Font.custom("Anton", size: compact ? 23 : 26))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: compact ? 12 : 20) {
                ForEach(Array(page.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.system(size: compact ? 15 : 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.96))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, compact ? 12 : 20)

            Spacer(minLength: 8)

            HStack(alignment: .center) {
                pageIndicator(selectedIndex: pageIndex)

                Spacer()

                actionButton(for: page)
            }
        }
        .padding(.top, compact ? 16 : 20)
        .padding(.horizontal, 16)
        // Mantém os controles acima do indicador de início mesmo quando o
        // GeometryReader estiver ocupando também as áreas seguras.
        .padding(.bottom, max(bottomInset, 24))
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            TopRoundedRectangle(radius: 18)
                .fill(panelColor)
        )
    }

    private func pageIndicator(selectedIndex: Int) -> some View {
        HStack(spacing: 7) {
            ForEach(viewModel.pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.35))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
        }
        .padding(.leading, 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Página \(selectedIndex + 1) de \(viewModel.pages.count)")
    }

    @ViewBuilder
    private func actionButton(for page: OnboardingPage) -> some View {
        switch page.actionStyle {
        case .arrow:
            Button {
                withAnimation(.easeInOut(duration: 0.28)) {
                    viewModel.advance()
                }
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 29, weight: .black))
                    .foregroundStyle(panelColor)
                    .frame(width: 60, height: 60)
                    .background(actionColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Próxima página")

        case .title(let title):
            Button(action: onFinished) {
                Text(title)
                    .font(Font.custom("Sedgwick Ave Display", size: 19))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 17)
                    .frame(height: 56)
                    .background(actionColor)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Conclui a apresentação e abre o aplicativo")
        }
    }
}

private struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: radius))
        path.addQuadCurve(
            to: CGPoint(x: radius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: radius),
            control: CGPoint(x: rect.maxX, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    OnboardingView()
}
