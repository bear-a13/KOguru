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
            Color(red: 0.18, green: 0.24, blue: 0.4)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false){
                VStack{
                    InformationHomeCard()
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("VAMOS TREINAR")
                            .font(.title2)
                            .fontWeight(.bold)
                            .tracking(0.5)
                        
                        // Cards
                        TrainCard(color: Color(red: 0.18, green: 0.24, blue: 0.4))
                        TrainCard(color: Color(red: 0.3, green: 0.08, blue: 0.08))
                        TrainCard(color: Color(red: 0.8, green: 0.66, blue: 0))
                        
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
