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
    @State private var isShowingDrillSession = false
    
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
                            TrainCard(color: .vermelhoCard,
                                      titulo: "JAB E DIRETO",
                                      subTitulo: "Aprenda a execultar os movimentos do boxe Jab e Direto",
                                      ImagemBack: "explozaoVermelho"
                            )
                        }
                        .buttonStyle(.plain)
                        Button(action: {
                                                    isShowingDrillSession = true
                                                }) {
                                                    TrainCard(color: .azulCard,
                                                              titulo: "DRILS",
                                                              subTitulo: "Aprenda na pratica com movimentos realizdos em lutas reais.",
                                                              ImagemBack: "explozaoAzul"
                                                    )
                                                }
                                                .buttonStyle(.plain)
                        TrainCard(color: .amareloCard,
                                  titulo: "MARIA LUIZA",
                                  subTitulo: "Aprenda a fazer o verdadeiro design com amestre.",
                                  ImagemBack: "explozaoAmarelo")
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
//
#Preview {
    HomeView()
}
