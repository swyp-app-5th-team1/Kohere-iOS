//
//  ListingApplicationComponents.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import SwiftUI

struct ListingApplicationBottomButton: View {
    enum Style {
        case primary
        case secondary
        case icon
    }

    let title: String?
    let icon: ImageResource?
    let style: Style
    let isEnabled: Bool
    let action: () -> Void

    init(
        title: String,
        style: Style,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        icon = nil
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }

    init(
        icon: ImageResource,
        style: Style = .icon,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        title = nil
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: title == nil ? nil : .infinity)
                .frame(width: title == nil ? 48 : nil, height: 48)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    @ViewBuilder private var content: some View {
        if let title {
            Text(title)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(foregroundColor)
                .lineLimit(1)
        } else if let icon {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(foregroundColor)
        }
    }

    private var backgroundColor: Color {
        guard isEnabled else { return .interactionDisable }

        switch style {
        case .primary: return Color.primaryNormal
        case .secondary: return Color.statusRed5
        case .icon: return Color.common0
        }
    }

    private var foregroundColor: Color {
        guard isEnabled else { return .labelDisable }

        switch style {
        case .primary: return Color.staticWhite
        case .secondary: return Color.primaryNormal
        case .icon: return Color.labelNeutral
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .secondary: return Color.lineAlternative
        case .icon: return Color.lineNormal
        }
    }
}

struct ListingApplicationSummaryCard: View {
    let language: AppLanguage
    let title: String
    let roomTypeName: String
    let moveInDateText: String
    let moveOutDateText: String
    let rentalPeriodText: String
    let priceText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .kohereTextStyle(.heading3Semibold)
                .foregroundStyle(.coolNeutral90)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 12) {
                    badgeRow(title: language.localized(.listingApplicationReviewFieldRoomType), value: roomTypeName)
                    badgeRow(title: language.localized(.listingApplicationReviewFieldMoveInDate), value: moveInDateText)
                    badgeRow(title: language.localized(.listingApplicationReviewFieldMoveOutDate), value: moveOutDateText)
                }

                plainRow(title: language.localized(.listingApplicationReviewFieldLeaseTerm), value: rentalPeriodText)
                plainRow(title: language.localized(.listingApplicationReviewFieldCost), value: priceText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.common0)
                .shadow(color: .primary10, radius: 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary30, lineWidth: 1.5)
        }
    }

    private func badgeRow(title: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            rowTitle(title)

            Spacer(minLength: 12)

            Text(value)
                .kohereTextStyle(.label3Semibold)
                .foregroundStyle(.coolNeutral80)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.coolNeutral6)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    private func plainRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            rowTitle(title)

            Spacer(minLength: 12)

            Text(value)
                .kohereTextStyle(.label3Semibold)
                .foregroundStyle(.coolNeutral80)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rowTitle(_ title: String) -> some View {
        Text(title)
            .kohereTextStyle(.body3Regular)
            .foregroundStyle(.labelAlternative)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

struct ListingApplicationApplicantCard: View {
    let applicantSummary: String
    let profileErrorMessage: String?
    @Binding var phoneNumber: String
    var isPhoneNumberFocused: FocusState<Bool>.Binding
    let showsPhoneNumberError: Bool
    let onBackgroundTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.listingApplicationApplicantTitle)
                .kohereTextStyle(.heading3Semibold)
                .foregroundStyle(.neutral80)

            VStack(alignment: .leading, spacing: 20) {
                Text(applicantSummary)
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(profileErrorMessage == nil ? .neutral40 : .statusDanger)

                phoneField
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.common0
                .contentShape(Rectangle())
                .onTapGesture(perform: onBackgroundTap)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.lineNormal, lineWidth: 1)
        }
    }

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                TextField(
                    "",
                    text: $phoneNumber,
                    prompt: Text(.listingApplicationApplicantPhonePlaceholder)
                        .foregroundColor(.coolNeutral20)
                )
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.coolNeutral80)
                    .keyboardType(.phonePad)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused(isPhoneNumberFocused)

                Text(verbatim: "*")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.statusDanger)
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(phoneFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(phoneFieldBorderColor, lineWidth: phoneFieldBorderWidth)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isPhoneNumberFocused.wrappedValue = true
            }

            if showsPhoneNumberError {
                Text(.listingApplicationApplicantPhoneRequired)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundStyle(.statusDanger)
                    .padding(.horizontal, 8)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showsPhoneNumberError)
    }

    private var phoneFieldBackground: Color {
        phoneNumber.isEmpty ? .neutral5 : .common0
    }

    private var phoneFieldBorderColor: Color {
        if showsPhoneNumberError {
            return .statusDanger
        }

        if isPhoneNumberFocused.wrappedValue {
            return .statusInfo
        }

        return .lineNormal
    }

    private var phoneFieldBorderWidth: CGFloat {
        showsPhoneNumberError || isPhoneNumberFocused.wrappedValue || !phoneNumber.isEmpty ? 1 : 0
    }
}

struct ListingApplicationPrivacySectionView: View {
    @Environment(\.locale)
    private var locale
    let onSectionTap: (ListingApplicationPrivacySection) -> Void

    var body: some View {
        let sections = ListingApplicationPrivacySection.allCases

        VStack(spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                privacyRow(section, isLast: index == sections.count - 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.lineNormal, lineWidth: 1)
        }
    }

    private func privacyRow(_ section: ListingApplicationPrivacySection, isLast: Bool) -> some View {
        Button {
            onSectionTap(section)
        } label: {
            HStack(spacing: 12) {
                Text(section.title(language: AppLanguage(locale: locale)))
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.neutral70)

                Spacer()

                Image(.chevronRight16)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.neutral70)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.common0)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(.lineNormal)
                    .frame(height: 1)
            }
        }
    }
}

struct ListingApplicationAgreementCard: View {
    let isChecked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 8) {
                Image(isChecked ? .check24 : .circle24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isChecked ? .statusInfo : .labelAssistive)

                Text(.listingApplicationPrivacyThirdPartyAgreement)
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.neutral70)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(.common0)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.lineNormal, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ListingApplicationConfirmationNotice: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(.circleCheckFill24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.statusInfo)

                Text(.listingApplicationNoticeTitle)
                    .kohereTextStyle(.caption2Semibold)
                    .foregroundStyle(.statusInfo)
            }

            Text(.listingApplicationNoticeMessage)
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.labelAlternative)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.statusBlue5)
    }
}
