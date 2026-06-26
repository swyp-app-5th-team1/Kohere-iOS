//
//  TabBarAppearanceConfigurator.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import UIKit

enum TabBarAppearanceConfigurator {
    static func configure() {
        let selectedColor = tabBarColor(
            name: "primary50",
            fallback: .systemBlue
        )
        let normalColor = tabBarColor(
            name: "coolNeutral50",
            fallback: .secondaryLabel
        )
        let backgroundColor = tabBarColor(
            name: "backgroundNormalNormal",
            fallback: .white
        )

        let appearance = UITabBarAppearance()

        if #available(iOS 26.0, *) {
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.backgroundEffect = nil
        } else {
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = backgroundColor
        }
        appearance.shadowColor = .clear

        configureItemAppearance(
            appearance.stackedLayoutAppearance,
            selectedColor: selectedColor,
            normalColor: normalColor
        )
        configureItemAppearance(
            appearance.inlineLayoutAppearance,
            selectedColor: selectedColor,
            normalColor: normalColor
        )
        configureItemAppearance(
            appearance.compactInlineLayoutAppearance,
            selectedColor: selectedColor,
            normalColor: normalColor
        )

        let tabBar = UITabBar.appearance()
        tabBar.tintColor = selectedColor
        tabBar.unselectedItemTintColor = normalColor
        tabBar.isTranslucent = true
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    private static func configureItemAppearance(
        _ appearance: UITabBarItemAppearance,
        selectedColor: UIColor,
        normalColor: UIColor
    ) {
        appearance.selected.iconColor = selectedColor
        appearance.normal.iconColor = normalColor
    }

    private static func tabBarColor(name: String, fallback: UIColor) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("\(name) color is missing from the asset catalog.")
            return fallback
        }
        return color
    }
}
