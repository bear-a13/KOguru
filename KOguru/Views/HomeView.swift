//
//  HomeView.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack{
                VStack{
                    VStack(alignment: .leading){
                        Text("LOREN IPSUM")
                            .font(.largeTitle)
                            .bold()
                        Text("consectetur adipiscing elit, sed do eiusmod tempor ")
                        
                        
                        
                        Rectangle()
                            .foregroundColor(.black)
                            .frame(width: 177, height: 148)
                            .cornerRadius(15)
                        
                    }
                    .padding()
                }
                
                VStack(spacing: 16) {
    //                Text("LOREM IPSUM DOLOR SIT AMET?")
    //                    .font(.title2)
    //                    .bold()
    //                    .foregroundColor(.black)
    //                    .padding(.vertical, 28)
                    
                    // Cards
                    Card(color: Color(red: 0.18, green: 0.24, blue: 0.4))
                    Card(color: Color(red: 0.3, green: 0.08, blue: 0.08))
                    Card(color: Color(red: 0.8, green: 0.66, blue: 0))
                    
                    
                }
                .frame(width: .infinity, height: .infinity)
                .padding(.horizontal, 16)
                
                
            }
            .frame(width: .infinity, height: .infinity)
            .background(Color(red: 0.18, green: 0.24, blue: 0.4))
            
        }
    }
}

#Preview {
    HomeView()
}
