//
//  InformationHomeCard.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 03/09/26.
//

import SwiftUI

struct InformationHomeCard: View {
    var body: some View {
        ZStack(alignment: .leading) {
            //TODO: adicionar a imagem do treco
            Image("kaio-texture")
                .resizable()
                .scaledToFit()
            
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                .font(Font.custom("PingFang HK", size: 18))
                .containerRelativeFrame(.horizontal) { length, axis in
                        length * 0.5
                    }
            
        }
        .frame(idealHeight: 148)
        .background(Color(red: 0.96, green: 0.96, blue: 0.96).opacity(1))
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 35, topTrailingRadius: 35))
        .shadow(color: .black.opacity(0.13), radius: 20, x: 0, y: 8)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    InformationHomeCard()
}
