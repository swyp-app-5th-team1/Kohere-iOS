//
//  KohereApp.swift
//  Kohere
//
//  Created by 송규섭 on 6/11/26.
//

import ComposableArchitecture
import GoogleSignIn
import SwiftUI

@main
struct KohereApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        TabBarAppearanceConfigurator.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(initialState: makeInitialState()) {
                    RootFeature()
                }
            )
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
    
    private func makeInitialState() -> RootFeature.State {
        return RootFeature.State()
    }
}
