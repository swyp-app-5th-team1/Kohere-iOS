//
//  LivingGuideItemView.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

import SwiftUI

struct LivingGuideItemView: View {
    @Environment(\.locale)
    private var locale
    
    // MARK: - Properties
    
    let item: LivingGuide
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(item.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized(item.theme.titleLocalizationKey))
                        .kohereTextStyle(.label2Semibold)
                        .foregroundColor(.labelNormal)
                    
                    Text(localized(item.theme.subtitleLocalizationKey))
                        .kohereTextStyle(.caption1Regular)
                        .foregroundColor(.labelAlternative)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(.chevronRight16)
                    .renderingMode(.template)
                    .foregroundColor(.coolNeutral20)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.backgroundElevatedNormal)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.lineNeutral, lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }

    private func localized(_ key: String) -> String {
        AppLanguage(locale: locale).localized(key)
    }
}

private extension LivingGuideTheme {
    var titleLocalizationKey: String {
        switch self {
        case .housingScams:
            "home.livingGuide.fraud.title"
        case .bankAccount:
            "home.livingGuide.bankAccount.title"
        case .publicTransit:
            "home.livingGuide.transportation.title"
        case .healthInsurance:
            "home.livingGuide.healthInsurance.title"
        }
    }

    var subtitleLocalizationKey: String {
        switch self {
        case .housingScams:
            "home.livingGuide.fraud.subtitle"
        case .bankAccount:
            "home.livingGuide.bankAccount.subtitle"
        case .publicTransit:
            "home.livingGuide.transportation.subtitle"
        case .healthInsurance:
            "home.livingGuide.healthInsurance.subtitle"
        }
    }
}
