//
//  LivingGuide.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

struct LivingGuide: Equatable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let iconName: String
}

extension LivingGuide {
    static let mockLivingGuide: [LivingGuide] = [
        LivingGuide(id: 1, title: "How to Open a Bank Account", subtitle: "Best within 3 days of getting your ARC", iconName: "bankAccountGuide"),
        LivingGuide(id: 2, title: "Top 3 Seoul Subway Apps", subtitle: "Highly Rated by Foreigners", iconName: "train"),
        LivingGuide(id: 3, title: "Goshiwon Checklist", subtitle: "What to check before you sign", iconName: "contractChecklist"),
        LivingGuide(id: 4, title: "Health Insurance Guide", subtitle: "Mandatory for stays of 6+ months", iconName: "healthInsurance")
    ]
}
