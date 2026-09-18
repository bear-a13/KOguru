//
//  AppEntryView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 09/09/26.
//

import SwiftUI

struct AppEntryView<MainContent: View>: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let mainContent: MainContent

    init(@ViewBuilder mainContent: () -> MainContent) {
        self.mainContent = mainContent()
    }

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                mainContent
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.30)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    AppEntryView {
        Text("Conteúdo principal")
    }
}
