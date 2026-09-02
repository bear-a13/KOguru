//
//  TutorialView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 01/09/26.
//

import SwiftUI

struct TutorialView: View {
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.red)
                .frame(width: 286, height: 239)
                .cornerRadius(15)
            
            Text("Hello, world!")
            
            Spacer()
            
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("TUTORIAL")
    }
    
}

#Preview{
    NavigationStack{
        TutorialView()
    }
}
