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
        configureTabBarAppearance()
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

    private func configureTabBarAppearance() {
        let selectedColor = UIColor(named: "primary50") ?? fallbackTabBarColor(
            name: "primary50",
            color: .systemBlue
        )
        let normalColor = UIColor(named: "coolNeutral50") ?? fallbackTabBarColor(
            name: "coolNeutral50",
            color: .secondaryLabel
        )

        let appearance = UITabBarAppearance()

        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear

        configureTabBarItemAppearance(
            appearance.stackedLayoutAppearance,
            selectedColor: selectedColor,
            normalColor: normalColor
        )
        configureTabBarItemAppearance(
            appearance.inlineLayoutAppearance,
            selectedColor: selectedColor,
            normalColor: normalColor
        )
        configureTabBarItemAppearance(
            appearance.compactInlineLayoutAppearance,
            selectedColor: selectedColor,
            normalColor: normalColor
        )

        let tabBar = UITabBar.appearance()
        tabBar.tintColor = selectedColor
        tabBar.unselectedItemTintColor = normalColor
        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    private func configureTabBarItemAppearance(
        _ appearance: UITabBarItemAppearance,
        selectedColor: UIColor,
        normalColor: UIColor
    ) {
        appearance.selected.iconColor = selectedColor
        appearance.normal.iconColor = normalColor
    }

    private func fallbackTabBarColor(name: String, color: UIColor) -> UIColor {
        assertionFailure("\(name) color is missing from the asset catalog.")
        return color
    }
}
