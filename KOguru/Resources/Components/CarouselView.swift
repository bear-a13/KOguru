//
//  CarouselView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 03/09/26.
//

import SwiftUI

struct CarouselView: View {
    
    let carouselItems = carregarTutorial()
    
    var body: some View {
        TabView {
            ForEach(carouselItems) { item in
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .font(.custom("SedgwickAveDisplay-Regular", size: 24))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 33)
                            .background(Color(red: 0.55, green: 0.14, blue: 0.15))
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 16
                                )
                            )
                        Image(item.image)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 16,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 16
                                )
                            )
                            .compositingGroup()
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                            .padding(.bottom, 10)
                            
                        
                        Text(item.description)
                            .foregroundColor(.white)
                            .font(.system(size: 19))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 5)
                            .padding(.bottom, 30)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .tabViewStyle(.page)
        .frame(height: 400)
    }
}

#Preview {
    CarouselView()
}
