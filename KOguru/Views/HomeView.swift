//
//  HomeView.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack{
            Color(Color.backgroundColorBlue)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false){
                VStack{
                    HStack(){
                        Text("EAI TA PRONTO?")
                            .padding(.horizontal, 16)
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    InformationHomeCard()
                        .padding(.bottom, 55)
                   
                        VStack(spacing: 16) {
                            Text("VAMOS TREINAR!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)
                                .padding(2)
                            
                            
                            
                            // Cards
                            TrainCard(color: Color(red: 0.18, green: 0.24, blue: 0.4))
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
    }
}

#Preview {
    HomeView()
}
