//
//  HomeView.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            HomeContentView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            InstructionsView()
                .tabItem {
                    Label("Instructions", systemImage: "book.pages.fill")
                }
            ConfigurationsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    HomeView()
}
