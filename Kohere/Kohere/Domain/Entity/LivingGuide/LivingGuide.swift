//
//  LivingGuide.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

struct LivingGuide: Equatable, Identifiable {
    let id: Int
    let code: String
    let title: String
    let subtitle: String
    let iconName: String
    let theme: LivingGuideTheme
    var tips: [LivingGuideTip]
}

struct LivingGuideTip: Equatable, Identifiable {
    let id: String
    let title: String
    let content: String
    let imageURL: String?
}

enum LivingGuideTheme: Equatable {
    case housingScams
    case bankAccount
    case publicTransit
    case healthInsurance
}

extension LivingGuide {
    init(
        id: Int,
        code: String,
        name: String,
        iconName: String,
        theme: LivingGuideTheme,
        tips: [LivingGuideTip] = []
    ) {
        let titleParts = name.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)

        self.id = id
        self.code = code
        self.title = titleParts.first.map(String.init) ?? name
        self.subtitle = titleParts.dropFirst().first.map(String.init) ?? ""
        self.iconName = iconName
        self.theme = theme
        self.tips = tips
    }
}
