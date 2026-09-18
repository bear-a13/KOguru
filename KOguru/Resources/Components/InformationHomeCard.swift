//
//  InformationHomeCard.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 03/09/26.
//

import SwiftUI
import Foundation

struct InformationHomeCard: View {
    @StateObject var viewModel = PhraseViewModel()
    
    var body: some View {
        ZStack(alignment: .leading) {
            Image(viewModel.currentImage)
                .resizable()
                .scaledToFit()
            
            if let frase = viewModel.currentPhrase{
                Text(frase.text)
                    .font(.custom("SedgwickAveDisplay-Regular", size: 24))
                    .tracking(0.23)
                    .offset(x: 27)
                    .lineSpacing(-6)
                    .foregroundStyle(.darkblue)
                    .containerRelativeFrame(.horizontal) { length, axis in
                        length * 0.43
                    }
            } else {
                Text("Carregando frase...")
                    .font(.custom("SedgwickAveDisplay-Regular", size: 24))
                    .tracking(0.23)
                    .offset(x: 27)
                    .lineSpacing(-6)
                    .foregroundStyle(.darkblue)
                    .containerRelativeFrame(.horizontal) { length, axis in
                        length * 0.43
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 35, topTrailingRadius: 35))
        .shadow(color: .black.opacity(0.13), radius: 20, x: 0, y: 8)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    InformationHomeCard()
}
