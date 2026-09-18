import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .padding(5)
                
                

        }
        .glassEffect(.regular, in: .rect(cornerRadius: 36))
    }
}
