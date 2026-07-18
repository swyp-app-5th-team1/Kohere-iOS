//
//  ListingApplicationFeature.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ListingApplicationFeature {
    @Dependency(\.fetchCurrentUserUseCase)
    var fetchCurrentUserUseCase
    @Dependency(\.createListingBookingUseCase)
    var createListingBookingUseCase

    @ObservableState
    struct State: Equatable {
        var step: ListingApplicationStep = .dateSelection
        let listingID: String
        let listingTitle: String
        let roomOfferID: String
        let roomTypeName: String
        let roomPricingText: String
        let minimumMoveInDate: Date
        let appLanguage: AppLanguage

        var moveInDate: Date
        var displayedMonth: Date
        var rentalMonths = 1
        var isMonthPickerPresented = false
        var applicantSummary = ""
        var isApplicantProfileLoading = false
        var hasLoadedApplicantProfile = false
        var applicantProfileErrorMessage: String?
        var phoneNumber = ""
        var hasInteractedWithPhoneNumber = false
        var isPhoneNumberFocused = false
        var isAgreementChecked = false
        var isSubmitting = false
        var submitErrorMessage: String?
        var booking: ListingBooking?
        var isCompletionPopupPresented = false

        var navigationTitle: String {
            switch step {
            case .dateSelection:
                appLanguage.localized("listingApplication.navigation.dateSelection")
            case .review:
                appLanguage.localized("listingApplication.navigation.review")
            }
        }

        var applicationTitle: String {
            String(
                format: appLanguage.localized("listingApplication.format.applicationTitle"),
                locale: displayLocale,
                listingTitle
            )
        }

        var moveOutDate: Date {
            Self.expiryDate(startDate: moveInDate, months: rentalMonths)
        }

        var displayedMonthTitle: String {
            monthFormatter.string(from: displayedMonth)
        }

        var moveInCompactText: String {
            compactDateFormatter.string(from: moveInDate)
        }

        var moveOutCompactText: String {
            compactDateFormatter.string(from: moveOutDate)
        }

        var moveInReviewText: String {
            reviewDateFormatter.string(from: moveInDate)
        }

        var moveOutReviewText: String {
            reviewDateFormatter.string(from: moveOutDate)
        }

        var rentalPeriodText: String {
            let format = rentalMonths == 1
                ? appLanguage.localized("listingApplication.format.rentalPeriod.one")
                : appLanguage.localized("listingApplication.format.rentalPeriod.other")
            return String(format: format, locale: displayLocale, String(rentalMonths))
        }

        var isSubmitButtonEnabled: Bool {
            isAgreementChecked
            && isPhoneNumberValid
            && hasLoadedApplicantProfile
            && !isApplicantProfileLoading
            && !isSubmitting
        }

        var submitButtonTitle: String {
            appLanguage.localized("listingApplication.action.submit")
        }

        var normalizedPhoneNumber: String {
            phoneNumber.filter(\.isNumber)
        }

        var isPhoneNumberValid: Bool {
            !normalizedPhoneNumber.isEmpty
        }

        var bookingCreateInput: ListingBookingCreateInput {
            ListingBookingCreateInput(
                roomOfferID: roomOfferID,
                moveInDate: moveInDate,
                contractPeriod: rentalMonths
            )
        }

        var shouldShowPhoneNumberError: Bool {
            !isPhoneNumberFocused
            && hasInteractedWithPhoneNumber
            && !isPhoneNumberValid
        }

        var maximumSelectableYear: Int {
            Self.calendar.component(.year, from: minimumMoveInDate) + 4
        }

        var maximumMoveInDate: Date {
            Self.calendar.date(
                from: DateComponents(
                    year: maximumSelectableYear,
                    month: 12,
                    day: 31
                )
            ) ?? minimumMoveInDate
        }

        var canMoveToPreviousMonth: Bool {
            displayedMonth > Self.monthStart(for: minimumMoveInDate)
        }

        var canMoveToNextMonth: Bool {
            displayedMonth < Self.monthStart(for: maximumMoveInDate)
        }

        init(
            listingID: String,
            listingTitle: String,
            roomOfferID: String,
            roomTypeName: String,
            roomPricingText: String,
            appLanguage: AppLanguage = .systemDefault
        ) {
            self.listingID = listingID
            self.listingTitle = listingTitle
            self.roomOfferID = roomOfferID
            self.roomTypeName = roomTypeName
            self.roomPricingText = roomPricingText
            self.appLanguage = appLanguage

            let today = Self.calendar.startOfDay(for: Date())
            minimumMoveInDate = today
            moveInDate = today
            displayedMonth = Self.monthStart(for: today)
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case applicantProfileResponse(Result<UserProfile, DataError>)
        case backButtonTapped
        case previousButtonTapped
        case previousMonthButtonTapped
        case nextMonthButtonTapped
        case monthTitleTapped
        case monthYearSelected(year: Int, month: Int)
        case dateTapped(Date)
        case rentalMonthsDecrementTapped
        case rentalMonthsIncrementTapped
        case dateSelectionApplyButtonTapped
        case phoneNumberFocusChanged(Bool)
        case privacySectionTapped(ListingApplicationPrivacySection)
        case agreementTapped
        case submitButtonTapped
        case bookingResponse(Result<ListingBooking, DataError>)
        case completionCloseButtonTapped
        case completionConfirmButtonTapped
        case delegate(ListingApplicationDelegate)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(let action):
                if action.keyPath == \.phoneNumber {
                    state.phoneNumber = state.normalizedPhoneNumber
                    state.submitErrorMessage = nil

                    if !state.phoneNumber.isEmpty {
                        state.hasInteractedWithPhoneNumber = true
                    }
                }
                return .none

            case .onAppear:
                guard !state.isApplicantProfileLoading,
                      !state.hasLoadedApplicantProfile
                else { return .none }

                state.isApplicantProfileLoading = true
                state.applicantProfileErrorMessage = nil

                return .run { [fetchCurrentUserUseCase] send in
                    do {
                        let profile = try await fetchCurrentUserUseCase.execute()
                        await send(.applicantProfileResponse(.success(profile)))
                    } catch {
                        await send(.applicantProfileResponse(.failure(.from(error))))
                    }
                }
                .cancellable(id: "ListingApplication.fetchApplicantProfile", cancelInFlight: true)

            case let .applicantProfileResponse(.success(profile)):
                state.isApplicantProfileLoading = false
                state.hasLoadedApplicantProfile = true
                state.applicantProfileErrorMessage = nil
                state.applicantSummary = Self.applicantSummary(
                    from: profile,
                    locale: state.displayLocale
                )

                if state.phoneNumber.isEmpty,
                   let phoneNumber = profile.phoneNumber?.filter(\.isNumber),
                   !phoneNumber.isEmpty {
                    state.phoneNumber = phoneNumber
                }
                return .none

            case let .applicantProfileResponse(.failure(error)):
                state.isApplicantProfileLoading = false
                state.hasLoadedApplicantProfile = false
                state.applicantProfileErrorMessage = error.localizedDescription
                state.applicantSummary = state.appLanguage.localized(
                    "listingApplication.applicant.profile.loadFailed"
                )
                return .none

            case .backButtonTapped:
                return .none

            case .previousButtonTapped:
                switch state.step {
                case .dateSelection:
                    return .send(.backButtonTapped)

                case .review:
                    state.step = .dateSelection
                    state.isCompletionPopupPresented = false
                    return .none
                }

            case .previousMonthButtonTapped:
                let previousMonth = Self.shiftMonth(state.displayedMonth, by: -1)
                state.displayedMonth = Self.clampedDisplayedMonth(
                    previousMonth,
                    minimumDate: state.minimumMoveInDate
                )
                return .none

            case .nextMonthButtonTapped:
                let nextMonth = Self.shiftMonth(state.displayedMonth, by: 1)
                state.displayedMonth = Self.clampedDisplayedMonth(
                    nextMonth,
                    minimumDate: state.minimumMoveInDate
                )
                return .none

            case .monthTitleTapped:
                state.isMonthPickerPresented.toggle()
                return .none

            case let .monthYearSelected(year, month):
                state.displayedMonth = Self.clampedDisplayedMonth(
                    Self.monthDate(year: year, month: month),
                    minimumDate: state.minimumMoveInDate
                )
                return .none

            case let .dateTapped(date):
                let selectedDate = State.calendar.startOfDay(for: date)
                guard Self.isSelectableDate(
                    selectedDate,
                    minimumDate: state.minimumMoveInDate
                ) else {
                    return .none
                }

                state.moveInDate = selectedDate
                state.displayedMonth = State.monthStart(for: selectedDate)
                return .none

            case .rentalMonthsDecrementTapped:
                state.rentalMonths = max(1, state.rentalMonths - 1)
                return .none

            case .rentalMonthsIncrementTapped:
                state.rentalMonths = min(12, state.rentalMonths + 1)
                return .none

            case .dateSelectionApplyButtonTapped:
                state.step = .review
                state.isMonthPickerPresented = false
                return .none

            case let .phoneNumberFocusChanged(isFocused):
                state.isPhoneNumberFocused = isFocused

                if isFocused {
                    state.hasInteractedWithPhoneNumber = true
                }
                return .none

            case let .privacySectionTapped(section):
                return .send(.delegate(.privacyDocumentRequested(section)))

            case .agreementTapped:
                state.isAgreementChecked.toggle()
                state.submitErrorMessage = nil
                return .none

            case .submitButtonTapped:
                state.hasInteractedWithPhoneNumber = true
                guard state.isSubmitButtonEnabled else { return .none }

                state.isSubmitting = true
                state.submitErrorMessage = nil
                state.booking = nil

                let input = state.bookingCreateInput

                return .run { [createListingBookingUseCase, listingID = state.listingID] send in
                    do {
                        let booking = try await createListingBookingUseCase.execute(listingID, input)
                        await send(.bookingResponse(.success(booking)))
                    } catch {
                        await send(.bookingResponse(.failure(.from(error))))
                    }
                }
                .cancellable(id: "ListingApplication.createBooking", cancelInFlight: true)

            case let .bookingResponse(.success(booking)):
                state.isSubmitting = false
                state.booking = booking
                state.isCompletionPopupPresented = true
                return .none

            case let .bookingResponse(.failure(error)):
                state.isSubmitting = false
                state.submitErrorMessage = error.localizedDescription
                return .none

            case .completionCloseButtonTapped:
                state.isCompletionPopupPresented = false
                return .send(.delegate(.listingDetailRequested(listingID: state.listingID)))

            case .completionConfirmButtonTapped:
                state.isCompletionPopupPresented = false
                return .send(.delegate(.chatTabRequested))

            case .delegate:
                return .none
            }
        }
    }

}
