import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .nowPlaying

    enum Tab { case nowPlaying, history, settings }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .nowPlaying: NowPlayingView()
                case .history:   HistoryView()
                case .settings:  SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MemorTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct MemorTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "music.note", label: "playing",  tab: .nowPlaying, selected: $selectedTab)
            TabBarItem(icon: "clock",      label: "history",  tab: .history,    selected: $selectedTab)
            TabBarItem(icon: "slider.horizontal.3", label: "settings", tab: .settings, selected: $selectedTab)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            Color(uiColor: .init(red: 0.93, green: 0.91, blue: 0.88, alpha: 1)) // --cream-dark
                .overlay(alignment: .top) {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.primary.opacity(0.15))
                }
        )
    }
}

private struct TabBarItem: View {
    let icon: String
    let label: String
    let tab: MainTabView.Tab
    @Binding var selected: MainTabView.Tab

    private var isActive: Bool { selected == tab }

    var body: some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .default))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isActive ? Color(red: 0.85, green: 0.29, blue: 0.17) : Color(uiColor: .systemGray))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}
