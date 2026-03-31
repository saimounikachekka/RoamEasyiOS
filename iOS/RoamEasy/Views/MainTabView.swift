import SwiftUI

enum AppTab: Int {
    case search = 0
    case explore = 1
    case saved = 2
}

struct MainTabView: View {
    @Binding var selectedTab: AppTab
    let searchTab: AnyView
    let exploreTab: AnyView
    let savedTab: AnyView

    init(
        selectedTab: Binding<AppTab>,
        @ViewBuilder searchTab: () -> some View,
        @ViewBuilder exploreTab: () -> some View,
        @ViewBuilder savedTab: () -> some View
    ) {
        self._selectedTab = selectedTab

        self.searchTab = AnyView(searchTab())
        self.exploreTab = AnyView(exploreTab())
        self.savedTab = AnyView(savedTab())

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            searchTab
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppTab.search)

            exploreTab
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }
                .tag(AppTab.explore)

            savedTab
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
                .tag(AppTab.saved)
        }
    }
}
