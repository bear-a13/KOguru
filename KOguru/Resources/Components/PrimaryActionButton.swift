import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    var systemImage: String?
    var foregroundColor: Color = .white
    var backgroundColor: Color = Color.vermelhoCard
    var maximize: Bool = true
    var accessibilityHint: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .black))
                }

                Text(title)
                    .font(Font.custom("Anton", size: 27))
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: maximize ? .infinity : nil)
            .frame(height: 57)
            .padding(.horizontal, maximize ? 0 : 32)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(accessibilityHint ?? "")
    }
}