//
//  HomeView.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct HomeView: View {
    // 1. Variável de estado para controlar a abertura da câmera
    @State private var isShowingWorkoutSession = false
    
    var body: some View {
        ZStack {
            VStack {
                Color(Color.backgroundColorBlue)
                    .ignoresSafeArea()
                Spacer()
                Color(Color.backgroundColorRed)
                    
                    .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    HStack {
                        Text("EAI TA PRONTO?")
                            .padding(.horizontal, 16)
                            .font(Font.custom("Anton", size: 40))
                            .bold()
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    InformationHomeCard()
                        .padding(.top, -26)
                        .padding(.bottom, 40)
                    
                    VStack(spacing: 16) {
                        Text("VAMOS TREINAR!")
                            .font(Font.custom("Anton", size: 28))

                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                            .padding(2)
                        
                        Button(action: {
                            isShowingWorkoutSession = true
                        }) {
                            TrainCard(color: Color(red: 0.18, green: 0.24, blue: 0.4))
                        }
                        .buttonStyle(.plain)
                        
                        TrainCard(color: Color(red: 0.3, green: 0.08, blue: 0.08))
                        TrainCard(color: Color(red: 0.8, green: 0.66, blue: 0))
                    }
                    .padding(.bottom, 100)
                    .padding()
                    .background(Color.backgroundColorRed)
                    .cornerRadius(30)
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingWorkoutSession) {
            WorkoutSessionView()
        }
    }
}

#Preview {
    HomeView()
}
