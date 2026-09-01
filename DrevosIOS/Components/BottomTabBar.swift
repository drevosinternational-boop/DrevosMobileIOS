import SwiftUI

struct BottomTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selected = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 15, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(selected == tab ? DrevosTheme.orange : DrevosTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
            }
        }
        .background(DrevosTheme.panel2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .background(DrevosTheme.background)
    }
}
