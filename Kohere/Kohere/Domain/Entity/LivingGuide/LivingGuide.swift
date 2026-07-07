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

extension LivingGuide {
    static let mockLivingGuide: [LivingGuide] = [
        LivingGuide(
            id: 1,
            code: "HOUSING_SCAMS",
            name: "Common Housing Scams\nStay safe from housing scams in Korea",
            iconName: "contractChecklist",
            theme: .housingScams,
            tips: [
                LivingGuideTip(id: "housing-1", title: "Fake listings", content: "The photos may not match the actual room, or the listing may already be unavailable.", imageURL: nil),
                LivingGuideTip(id: "housing-2", title: "Rental Deposit Scam", content: "A landlord may keep your deposit or rent the same room to someone else.", imageURL: nil),
                LivingGuideTip(id: "housing-3", title: "Phishing Texts", content: "Fake delivery or bank messages may try to steal your personal information or money.", imageURL: nil),
                LivingGuideTip(id: "housing-4", title: "Deposit Protection", content: "Register your address and get an official date stamp on your lease contract.", imageURL: nil)
            ]
        ),
        LivingGuide(
            id: 2,
            code: "BANK_ACCOUNT",
            name: "How to Open a Bank Account\nBest within 3 days of getting your ARC",
            iconName: "bankAccountGuide",
            theme: .bankAccount,
            tips: [
                LivingGuideTip(id: "bank-1", title: "Required documents", content: "Bring your ARC and passport to open a bank account.", imageURL: nil),
                LivingGuideTip(id: "bank-2", title: "Recommended Banks", content: "KB, Hana, Shinhan, and Woori offer foreigner-friendly services.", imageURL: nil),
                LivingGuideTip(id: "bank-3", title: "Mobile banking", content: "After opening your account, use Toss or KakaoBank for transfers, bills, and exchange.", imageURL: nil),
                LivingGuideTip(id: "bank-4", title: "Debit Card", content: "Request a debit card when opening your account.", imageURL: nil)
            ]
        ),
        LivingGuide(
            id: 3,
            code: "TRANSPORT",
            name: "Public Transit Guide\nSubways, buses, and transfer tips",
            iconName: "train",
            theme: .publicTransit,
            tips: [
                LivingGuideTip(id: "transport-1", title: "Transit Card", content: "Buy and top up a T-money card at a convenience store. It works on buses, subways, and taxis.", imageURL: nil),
                LivingGuideTip(id: "transport-2", title: "Navigation Apps", content: "Naver Map and KakaoMap support English and provide routes, fares, and transfer information.", imageURL: nil),
                LivingGuideTip(id: "transport-3", title: "Transfer Discount", content: "Transfer between buses and subways within 30 minutes to receive a fare discount.", imageURL: nil),
                LivingGuideTip(id: "transport-4", title: "Bus Colors", content: "Blue (main), green (local), red (express), and yellow (loop) buses.", imageURL: nil)
            ]
        ),
        LivingGuide(
            id: 4,
            code: "HEALTH_INSURANCE",
            name: "Health Insurance Guide\nMandatory for stays of 6+ months",
            iconName: "healthInsurance",
            theme: .healthInsurance,
            tips: [
                LivingGuideTip(id: "health-1", title: "Who Needs It?", content: "If you stay in Korea for 6 months or longer, you must enroll in the National Health Insurance Service (NHIS).", imageURL: nil),
                LivingGuideTip(id: "health-2", title: "How to Apply", content: "Apply at an NHIS office or on the NHIS website.", imageURL: nil),
                LivingGuideTip(id: "health-3", title: "Premiums", content: "Premiums depend on your income. If you're employed, you usually share the cost with your employer.", imageURL: nil),
                LivingGuideTip(id: "health-4", title: "Coverage", content: "You usually pay only 20-30% of covered medical costs when visiting hospitals or pharmacies.", imageURL: nil)
            ]
        )
    ]
}
