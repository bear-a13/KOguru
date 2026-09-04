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
            Image("kaio-card")
                .resizable()
                .scaledToFit()
            
            Text("Sabia que no boxe, os pés são tão importantes quanto as mãos?")
                .font(.custom("SedgwickAveDisplay-Regular", size: 24))
                .tracking(0.23)
                .offset(x: 27)
                .lineSpacing(-6)
                .foregroundStyle(.darkblue)
                .containerRelativeFrame(.horizontal) { length, axis in
                    length * 0.43
                }
        }
        .frame(idealHeight: 148)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 35, topTrailingRadius: 35))
        .shadow(color: .black.opacity(0.13), radius: 20, x: 0, y: 8)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    InformationHomeCard()
}
