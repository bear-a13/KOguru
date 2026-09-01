//
//  Card.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct Card: View {
    
    @Environment(\.dismiss) var dismiss
    
    var color : Color
    
    var body: some View {
        HStack {
            //TODO: adicionar a imagem do treco
            Rectangle()
                .frame(width: 100)
                .frame(height: 180)
                .clipped()
            
            // Nome e pequena descrição do treino
            VStack (alignment: .leading) {
                Text("TREINO")
                    .font(Font.custom("Anton", size: 25))
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                    .font(Font.custom("PingFang HK", size: 18))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 20)
            .padding(.horizontal, 10)
            
            // Botão de play
            Image(systemName: "play.circle.fill")
                .font(Font.custom("SF Pro", size: 60))
                .foregroundColor(color)
                .padding(.trailing, 10)
            
        }
        .frame(maxWidth: .infinity, idealHeight: 148)
        .background(Color(red: 0.96, green: 0.96, blue: 0.96).opacity(1))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.13), radius: 20, x: 0, y: 8)
        
    }
}


#Preview(traits: .sizeThatFitsLayout) {
    Card(color: Color(red: 0.18, green: 0.24, blue: 0.4))
}
