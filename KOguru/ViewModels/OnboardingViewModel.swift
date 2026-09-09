//
//  OnboardingViewModel.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 09/09/26.
//

import Foundation
import Combine

final class OnboardingViewModel: ObservableObject {
    @Published private(set) var selectedPageIndex = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            imageName: "onboarding_ringue",
            title: "TUDO PRONTO PARA ENTRAR NO RINGUE?",
            paragraphs: [
                "O KOguru foi feito para acompanhar enquanto você aprende, pratica e evolui.",
                "E eu, Kaio, vou estar aqui para entrar nessa com você."
            ],
            actionStyle: .arrow
        ),
        OnboardingPage(
            id: 1,
            imageName: "onboarding_saco",
            title: "ROUND ONE, FIGHT!",
            paragraphs: [
                "É só colocar o celular numa superfície firme e ajustar sua posição.",
                "Eu fico de olho em cada jab e direto pra te dar aquele feedback na hora!"
            ],
            actionStyle: .title("BORA TREINAR")
        )
    ]

    var isLastPage: Bool {
        selectedPageIndex == pages.count - 1
    }

    func selectPage(_ index: Int) {
        guard pages.indices.contains(index) else { return }
        selectedPageIndex = index
    }

    func advance() {
        guard !isLastPage else { return }
        selectedPageIndex += 1
    }

    func reset() {
        selectedPageIndex = 0
    }
}
