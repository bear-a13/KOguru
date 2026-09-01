//
//  Card.swift
//  KOguru
//
//  Created by Bernardo on 31/08/26.
//

import SwiftUI

struct Card: View {
    var body: some View {
        Rectangle()
            .foregroundStyle(Color.black)
            .cornerRadius(10)
            .frame(width: 370, height: 148)
    }
}

#Preview {
    Card()
}
