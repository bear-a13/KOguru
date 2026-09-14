//
//  HomeView.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct HomeView: View {
    @State private var isShowingWorkoutSession = false
    @State private var isShowingDrillSession = false
    
    var body: some View {
        ZStack {
            VStack {
                Color(Color.backgroundColorBlue)
                    .ignoresSafeArea()
                Color(Color.backgroundColorRed)
                    .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    HStack {
                        Text("EAI, TA PRONTO?")
                            .padding(.horizontal, 16)
                            .font(.custom("Anton", size: 40, relativeTo: .largeTitle))
                            .bold()
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h1)
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    
                    InformationHomeCard()
                        .padding(.horizontal, 16)
                        .padding(.top, -26)
                        .padding(.bottom, 40)
                    
                    VStack(spacing: 16) {
                        Text("VAMOS TREINAR!")
                            .font(.custom("Anton", size: 28, relativeTo: .title))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                            .padding(2)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
                        
                        Button(action: {
                            isShowingWorkoutSession = true
                        }) {
                            TrainCard(
                                color: .vermelhoCard,
                                titulo: "JAB E DIRETO",
                                subTitulo: "Aprenda a execultar os movimentos do boxe Jab e Direto.",
                                ImagemBack: "explozaoVermelho"
                            )
                            .accessibilityHidden(true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Treino Jab e Direto. Aprenda a executar os movimentos do boxe.")
                        .accessibilityHint("Toque duas vezes para iniciar este treino")
                        .accessibilityAddTraits(.isButton)
                        
                        // Botão 2: Drills
                        Button(action: {
                            isShowingDrillSession = true
                        }) {
                            TrainCard(
                                color: .azulCard,
                                titulo: "DRILS",
                                subTitulo: "Aprenda na pratica com movimentos realizdos em lutas reais.",
                                ImagemBack: "explozaoAzul"
                            )
                            .accessibilityHidden(true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Treino de Drills. Aprenda na prática com movimentos realizados em lutas reais.")
                        .accessibilityHint("Toque duas vezes para iniciar esta sessão")
                        .accessibilityAddTraits(.isButton)
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
        .fullScreenCover(isPresented: $isShowingDrillSession) {
            DrillSessionView()
        }
    }
}

#Preview {
    HomeView()
}
