//
//  ListingApplicationView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import SwiftUI

struct ListingApplicationView: View {
    @Bindable var store: StoreOf<ListingApplicationFeature>
    @FocusState private var isPhoneNumberFocused: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                navigationBar

                switch store.step {
                case .dateSelection:
                    dateSelectionView
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            dateSelectionBottomBar
                        }

                case .review:
                    reviewView
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            reviewBottomBar
                        }
                }
            }
            .background(.backgroundNormalAlternative)

            if store.isCompletionPopupPresented {
                completionOverlay
            }
        }
        .background(.backgroundNormalAlternative)
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: isPhoneNumberFocused) { _, isFocused in
            store.send(.phoneNumberFocusChanged(isFocused))
        }
    }

    private var navigationBar: some View {
        KohereNavigationBar(
            left: .backButton {
                store.send(.backButtonTapped)
            },
            center: .text(store.navigationTitle),
            backgroundColor: .common0,
            height: 48
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.lineNeutral)
                .frame(height: 1)
        }
    }

    private var dateSelectionView: some View {
        ListingApplicationDateSelectionView(
            moveInDate: store.moveInDate,
            displayedMonth: store.displayedMonth,
            displayedMonthTitle: store.displayedMonthTitle,
            minimumMoveInDate: store.minimumMoveInDate,
            maximumMoveInDate: store.maximumMoveInDate,
            moveInDateText: store.moveInCompactText,
            moveOutDateText: store.moveOutCompactText,
            rentalPeriodText: store.rentalPeriodText,
            rentalMonths: store.rentalMonths,
            isMonthPickerPresented: store.isMonthPickerPresented,
            canMoveToPreviousMonth: store.canMoveToPreviousMonth,
            canMoveToNextMonth: store.canMoveToNextMonth,
            onPreviousMonthTap: { store.send(.previousMonthButtonTapped) },
            onNextMonthTap: { store.send(.nextMonthButtonTapped) },
            onMonthTitleTap: { store.send(.monthTitleTapped) },
            onMonthYearSelect: { year, month in
                store.send(.monthYearSelected(year: year, month: month))
            },
            onDateTap: { date in
                store.send(.dateTapped(date))
            },
            onRentalMonthsDecrease: { store.send(.rentalMonthsDecrementTapped) },
            onRentalMonthsIncrease: { store.send(.rentalMonthsIncrementTapped) }
        )
    }

    private var dateSelectionBottomBar: some View {
        HStack(spacing: 8) {
            ListingApplicationBottomButton(
                title: "이전",
                style: .secondary
            ) {
                store.send(.previousButtonTapped)
            }

            ListingApplicationBottomButton(
                title: "신청하기",
                style: .primary
            ) {
                store.send(.dateSelectionApplyButtonTapped)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.common0)
    }

    private var reviewView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("아래 내용이 맞는지 확인해 주세요")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.labelNormal)

                ListingApplicationSummaryCard(
                    title: store.applicationTitle,
                    roomTypeName: store.roomTypeName,
                    moveInDateText: store.moveInKoreanText,
                    moveOutDateText: store.moveOutKoreanText,
                    rentalPeriodText: store.rentalPeriodText,
                    priceText: store.roomPricingText
                )

                ListingApplicationApplicantCard(
                    applicantSummary: store.applicantSummary,
                    profileErrorMessage: store.applicantProfileErrorMessage,
                    phoneNumber: $store.phoneNumber,
                    isPhoneNumberFocused: $isPhoneNumberFocused,
                    showsPhoneNumberError: store.shouldShowPhoneNumberError
                )

                ListingApplicationPrivacySectionView(
                    onSectionTap: { section in
                        store.send(.privacySectionTapped(section))
                    }
                )

                ListingApplicationAgreementCard(
                    isChecked: store.isAgreementChecked,
                    onTap: { store.send(.agreementTapped) }
                )

                if let submitErrorMessage = store.submitErrorMessage {
                    Text(submitErrorMessage)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundStyle(.statusDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .background {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPhoneNumberFocused = false
                    }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background {
            Color.backgroundNormalAlternative
                .contentShape(Rectangle())
                .onTapGesture {
                    isPhoneNumberFocused = false
                }
        }
    }

    private var reviewBottomBar: some View {
        VStack(spacing: 0) {
            ListingApplicationConfirmationNotice()

            HStack(spacing: 8) {
                ListingApplicationBottomButton(icon: .arrowLeft24) {
                    isPhoneNumberFocused = false
                    store.send(.previousButtonTapped)
                }

                ListingApplicationBottomButton(
                    title: store.submitButtonTitle,
                    style: .primary,
                    isEnabled: store.isSubmitButtonEnabled
                ) {
                    isPhoneNumberFocused = false
                    store.send(.submitButtonTapped)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(.common0)
        }
        .background(.common0)
    }

    private var completionOverlay: some View {
        ZStack {
            Color.materialDimmer
                .ignoresSafeArea()

            ListingApplicationCompletionPopup(
                applicationTitle: store.applicationTitle,
                moveInDateText: store.moveInKoreanText,
                moveOutDateText: store.moveOutKoreanText,
                rentalPeriodText: store.rentalPeriodText,
                priceText: store.roomPricingText,
                onCloseTap: { store.send(.completionCloseButtonTapped) },
                onConfirmTap: { store.send(.completionConfirmButtonTapped) }
            )
            .padding(.horizontal, 42)
        }
        .transition(.opacity)
        .zIndex(3)
    }
}

private struct ListingApplicationCompletionPopup: View {
    let applicationTitle: String
    let moveInDateText: String
    let moveOutDateText: String
    let rentalPeriodText: String
    let priceText: String
    let onCloseTap: () -> Void
    let onConfirmTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            header
            summary
            buttons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .kohereElevation(.normalXSmall, shape: .roundedRectangle(cornerRadius: 16))
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.primary10, .primary20],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(.checkThick24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.staticWhite)
            }
            .frame(width: 48, height: 48)

            VStack(spacing: 8) {
                Text("신청을 완료했어요!")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.coolNeutral90)

                Text("임대인이 신청 내용을 확인한 후\n등록된 이메일로 연락드릴 예정입니다")
                    .kohereTextStyle(.caption1Regular)
                    .foregroundStyle(.coolNeutral50)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("신청 요약 정보")
                .kohereTextStyle(.label3Semibold)
                .foregroundStyle(.coolNeutral80)

            VStack(spacing: 12) {
                summaryRow(title: "입주 희망일", value: moveInDateText)
                summaryRow(title: "종료일", value: moveOutDateText)
                summaryRow(title: "계약 기간", value: rentalPeriodText)
                summaryRow(title: "금액", value: priceText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.coolNeutral5)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.coolNeutral60)
                .frame(width: 82, alignment: .leading)

            Text(value)
                .kohereTextStyle(.label3Semibold)
                .foregroundStyle(.coolNeutral80)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            popupButton(
                title: "닫기",
                style: .secondary,
                action: onCloseTap
            )

            popupButton(
                title: "확인하기",
                style: .primary,
                action: onConfirmTap
            )
        }
    }

    private func popupButton(
        title: String,
        style: ListingApplicationBottomButton.Style,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .kohereTextStyle(.label2Semibold)
                .foregroundStyle(popupButtonForeground(for: style))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(popupButtonBackground(for: style))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.lineAlternative, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func popupButtonForeground(for style: ListingApplicationBottomButton.Style) -> Color {
        switch style {
        case .primary: return .staticWhite
        case .secondary: return .primaryNormal
        case .icon: return .labelNeutral
        }
    }

    private func popupButtonBackground(for style: ListingApplicationBottomButton.Style) -> Color {
        switch style {
        case .primary: return .primaryNormal
        case .secondary: return .statusRed5
        case .icon: return .common0
        }
    }
}
