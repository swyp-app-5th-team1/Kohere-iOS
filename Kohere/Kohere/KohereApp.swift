//
//  KohereApp.swift
//  Kohere
//
//  Created by 송규섭 on 6/11/26.
//

import ComposableArchitecture
import SwiftUI
import UIKit

@main
struct KohereApp: App {
    init() {
        UITabBar.appearance().tintColor = UIColor(named: "primary50")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "coolNeutral50")
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(initialState: RootFeature.State()) {
                    RootFeature()
                }
            )
        }
    }
}
