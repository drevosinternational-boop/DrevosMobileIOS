import SwiftUI

struct InstructionsView: View {
    var body: some View {
        ZStack {
            DrevosTheme.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "book.closed").font(.system(size: 38)).foregroundStyle(DrevosTheme.orange)
                Text("Instructions").font(.system(size: 24, weight: .semibold)).foregroundStyle(DrevosTheme.text)
                Text("Instruction content is still a placeholder in the current Android build as well.")
                    .font(.system(size: 13)).foregroundStyle(DrevosTheme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)
            }
        }
    }
}
