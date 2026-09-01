//
//  HomeView.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack{
            HStack{
                VStack(alignment: .leading){
                    Text("LOREN IPSUM")
                        .font(.largeTitle)
                        .bold()
                    Text("consectetur adipiscing elit, sed do eiusmod tempor ")
                    
                    
                }
                VStack{
                    Rectangle()
                        .foregroundColor(.black)
                      .frame(width: 177, height: 148)
                      .cornerRadius(15)
                }
            }
            .padding()
        }
        
        
        VStack(spacing: 16) {
            Text("LOREM IPSUM DOLOR SIT AMET?")
                .font(.title2)
                .bold()
                .foregroundColor(.black)
                .padding(.vertical, 28)
            Card()
            Card()
            Card()
            
            
        }
        .frame(width: 402, height: .infinity)
        .background(Color(red: 0.82, green: 0.82, blue: 0.82).opacity(0.3))
        .cornerRadius(30)
        
    }
    
}

#Preview {
    HomeView()
}
