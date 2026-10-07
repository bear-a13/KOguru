import SwiftUI

// Visual do botão circular (glass) usado como label do ShareLink,
// sem ser um Button para não aninhar controles.
struct ShareIconButtonLabel: View {
    var body: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .padding(5)
            .glassEffect(.regular, in: .rect(cornerRadius: 36))
            .padding(.top, 40)
    }
}
