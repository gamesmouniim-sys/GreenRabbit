import SwiftUI

@main
struct Dark_Aura_XIT_PanelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // Initialised once at launch; configures RevenueCat and checks entitlement
    @StateObject private var rc = RevenueCatService.shared
    @StateObject private var ads = AdsService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(rc)
                .environmentObject(ads)
        }
    }
}
