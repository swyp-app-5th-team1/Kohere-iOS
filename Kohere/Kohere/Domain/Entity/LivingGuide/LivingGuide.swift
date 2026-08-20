//
//  LivingGuide.swift
//  Kohere
//
//  Created by soomin on 6/25/26.
//

struct LivingGuide: Equatable, Identifiable {
    let id: Int
    let code: String
    let title: String
    let shortDescription: String
    let longDescription: String
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
        shortDescription: String,
        longDescription: String,
        iconName: String,
        theme: LivingGuideTheme,
        tips: [LivingGuideTip] = []
    ) {
        self.id = id
        self.code = code
        self.title = name
        self.shortDescription = shortDescription
        self.longDescription = longDescription
        self.iconName = iconName
        self.theme = theme
        self.tips = tips
    }
}
