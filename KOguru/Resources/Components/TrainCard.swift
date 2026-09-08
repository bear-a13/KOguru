//
//  Card.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct TrainCard: View {
    
    @Environment(\.dismiss) var dismiss
    var color : Color
    var titulo : String = "JAB E DIRETO"
    var subTitulo : String = "Aprenda a execultar os movimentos do boxe Jab e Direto"
    var ImagemBack : String =  "explozãoAzul"
    var body: some View {
       
            ZStack{
                Image("\(ImagemBack)")
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                HStack {
                    //TODO: adicionar a imagem do treco
                    Rectangle()
                        .opacity(0)
                        .frame(width: 100)
                        .frame(height: 180)
                        .clipped()
                    
                    // Nome e pequena descrição do treino
                    VStack (alignment: .leading) {
                        Text("\(titulo)")
                            .font(Font.custom("Anton", size: 25))
                            .fontWeight(.bold)
                            .foregroundStyle(color)
                        
                        Text("\(subTitulo)")
                            .font(Font.custom("PingFang HK", size: 18))
                            .foregroundStyle(color)
                        
                    
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 10)
                    
                    // Botão de play
                    Image(systemName: "play.circle.fill")
                        .font(Font.custom("SF Pro", size: 60))
                        .foregroundColor(color)
                        .padding(.trailing, 10)
                    
                }
                .frame(width: .infinity, height: 148)
                .shadow(color: .black.opacity(0.13), radius: 20, x: 0, y: 8)
                
            }
            
            
        }
    }
    



//#Preview(traits: .sizeThatFitsLayout) {
//    TrainCard(color: Color(red: 0.18, green: 0.24, blue: 0.4))
//}
