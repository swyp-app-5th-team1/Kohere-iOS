//
//  MoreProfileCard.swift
//  Kohere
//

import SwiftUI

struct MoreProfileCard: View {
    @Environment(\.locale)
    private var locale

    let userType: UserType?
    let userProfile: UserProfile?
    let onEditTap: () -> Void

    var body: some View {
        Group {
            if userType == .landlord {
                content
            } else {
                Button(action: onEditTap) {
                    content
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var content: some View {
        ZStack {
            Image(userType == .landlord ? "landlordProfileBackground" : "tenantProfileBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 8) {
                Image(userType == .landlord ? "landlordProfileIcon" : "tenantProfileIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 0) {
                    Text(profileName)
                        .kohereTextStyle(.label1Medium)
                        .foregroundStyle(userType == .landlord ? .neutral85 : .neutral5)

                    Text(userProfile?.nickname ?? "")
                        .kohereTextStyle(.caption2Regular)
                        .foregroundStyle(userType == .landlord ? .neutral75 : .primary5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if userType != .landlord {
                    Image("pencil_write_24")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.staticWhite)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 76)
    }

    private var profileName: String {
        guard let userProfile else {
            return userType == .landlord
                ? localized(.moreProfileLandlordNamePlaceholder)
                : localized(.moreProfileNicknamePlaceholder)
        }

        switch userProfile.userType {
        case .tenant:
            let name = userProfile.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? userProfile.nickname : name
        case .landlord:
            return userProfile.name ?? userProfile.nickname
        case .unknown:
            return userProfile.nickname
        }
    }

    private func localized(_ resource: LocalizedStringResource) -> String {
        AppLanguage(locale: locale).localized(resource)
    }
}
