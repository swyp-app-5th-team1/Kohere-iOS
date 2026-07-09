//
//  KohereTests.swift
//  KohereTests
//
//  Created by 송규섭 on 6/11/26.
//

import XCTest
import ComposableArchitecture
@testable import Kohere

@MainActor
final class ListingApplicationFeatureTests: XCTestCase {
    func testInitialReviewRequirementsKeepSubmitButtonDisabled() {
        let state = ListingApplicationFeature.State(
            listingID: "listing-1",
            listingTitle: "Hongdae Stay",
            roomOfferID: "room-offer-1",
            roomTypeName: "Single Room",
            roomPricingText: "₩500,000 / month"
        )

        XCTAssertFalse(state.isAgreementChecked)
        XCTAssertFalse(state.isSubmitButtonEnabled)
        XCTAssertEqual(state.roomOfferID, "room-offer-1")
        XCTAssertEqual(state.submitButtonTitle, "동의하고 예약 신청하기")
    }

    func testSubmitButtonRequiresAgreementProfileAndPhoneNumber() {
        var state = ListingApplicationFeature.State(
            listingID: "listing-1",
            listingTitle: "Hongdae Stay",
            roomOfferID: "room-offer-1",
            roomTypeName: "Single Room",
            roomPricingText: "₩500,000 / month"
        )

        state.hasLoadedApplicantProfile = true
        state.phoneNumber = "01012345678"
        XCTAssertFalse(state.isSubmitButtonEnabled)

        state.isAgreementChecked = true
        XCTAssertTrue(state.isSubmitButtonEnabled)

        state.phoneNumber = ""
        XCTAssertFalse(state.isSubmitButtonEnabled)
    }

    func testApplicantSummaryUsesCurrentProfileFields() {
        let profile = makeUserProfile(
            firstName: "Song",
            lastName: "NunSeop",
            nickname: "DreamyPuma",
            gender: "MALE",
            country: "KR",
            countryName: "South Korea"
        )

        XCTAssertEqual(
            ListingApplicationFeature.applicantSummary(from: profile),
            "Song NunSeop · Male · South Korea"
        )
    }

    func testBookingRequestDTOEncodesBackendContract() throws {
        let moveInDate = try XCTUnwrap(
            ListingApplicationFeature.State.calendar.date(
                from: DateComponents(year: 2030, month: 1, day: 1)
            )
        )
        let input = ListingBookingCreateInput(
            roomOfferID: "6858e2000000000000000abc",
            moveInDate: moveInDate,
            contractPeriod: 6
        )

        let data = try JSONEncoder().encode(ListingBookingCreateRequestDTO(input))
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(json["roomOfferId"] as? String, "6858e2000000000000000abc")
        XCTAssertEqual(json["moveInDate"] as? String, "2030-01-01")
        XCTAssertEqual(json["contractPeriod"] as? Int, 6)
    }

    func testBookingCreateInputUsesSelectedRoomMoveInDateAndRentalPeriod() throws {
        let moveInDate = try XCTUnwrap(
            ListingApplicationFeature.State.calendar.date(
                from: DateComponents(year: 2030, month: 1, day: 1)
            )
        )
        var state = ListingApplicationFeature.State(
            listingID: "listing-1",
            listingTitle: "Hongdae Stay",
            roomOfferID: "room-offer-1",
            roomTypeName: "Single Room",
            roomPricingText: "₩500,000 / month"
        )
        state.moveInDate = moveInDate
        state.rentalMonths = 6

        XCTAssertEqual(
            state.bookingCreateInput,
            ListingBookingCreateInput(
                roomOfferID: "room-offer-1",
                moveInDate: moveInDate,
                contractPeriod: 6
            )
        )
    }

    func testPrivacySectionsUseNotionLinks() {
        XCTAssertEqual(
            ListingApplicationPrivacySection.collection.url.absoluteString,
            "https://jewel-humor-b3e.notion.site/39777dadb98580298266c7fa779a5502?source=copy_link"
        )
        XCTAssertEqual(
            ListingApplicationPrivacySection.thirdParty.url.absoluteString,
            "https://jewel-humor-b3e.notion.site/3-39777dadb98580f1ac63ec8ceef52fa4?source=copy_link"
        )
    }

    func testOnAppearLoadsApplicantProfileAndPrefillsPhoneNumber() async {
        let profile = makeUserProfile(
            firstName: "Song",
            lastName: "NunSeop",
            nickname: "DreamyPuma",
            gender: "MALE",
            country: "KR",
            countryName: "South Korea",
            phoneNumber: "+82 10-1234-5678"
        )
        let store = TestStore(
            initialState: ListingApplicationFeature.State(
                listingID: "listing-1",
                listingTitle: "Hongdae Stay",
                roomOfferID: "room-offer-1",
                roomTypeName: "Single Room",
                roomPricingText: "₩500,000 / month"
            ),
            reducer: { ListingApplicationFeature() },
            withDependencies: {
                $0.fetchCurrentUserUseCase.execute = { profile }
            }
        )

        await store.send(.onAppear) {
            $0.isApplicantProfileLoading = true
            $0.applicantProfileErrorMessage = nil
        }

        await store.receive(.applicantProfileResponse(.success(profile))) {
            $0.isApplicantProfileLoading = false
            $0.hasLoadedApplicantProfile = true
            $0.applicantProfileErrorMessage = nil
            $0.applicantSummary = "Song NunSeop · Male · South Korea"
            $0.phoneNumber = "821012345678"
        }
    }

    func testSubmitCreatesBookingAndShowsCompletionPopupAfterSuccess() async throws {
        let moveInDate = try XCTUnwrap(
            ListingApplicationFeature.State.calendar.date(
                from: DateComponents(year: 2030, month: 1, day: 1)
            )
        )
        let booking = ListingBooking(
            bookingID: 2,
            status: "REQUESTED",
            listingID: "listing-1",
            roomOfferID: "room-offer-1",
            moveInDate: "2030-01-01",
            contractPeriod: 6,
            createdAt: "2026-07-07T05:54:21.642652351Z"
        )
        var state = ListingApplicationFeature.State(
            listingID: "listing-1",
            listingTitle: "Hongdae Stay",
            roomOfferID: "room-offer-1",
            roomTypeName: "Single Room",
            roomPricingText: "₩500,000 / month"
        )
        state.moveInDate = moveInDate
        state.rentalMonths = 6
        state.hasLoadedApplicantProfile = true
        state.phoneNumber = "01012345678"
        state.isAgreementChecked = true

        let store = TestStore(
            initialState: state,
            reducer: { ListingApplicationFeature() },
            withDependencies: {
                $0.createListingBookingUseCase.execute = { _, _ in
                    return booking
                }
            }
        )

        await store.send(.submitButtonTapped) {
            $0.hasInteractedWithPhoneNumber = true
            $0.isSubmitting = true
            $0.submitErrorMessage = nil
            $0.booking = nil
        }

        await store.receive(.bookingResponse(.success(booking))) {
            $0.isSubmitting = false
            $0.booking = booking
            $0.isCompletionPopupPresented = true
        }
    }

    func testSubmitFailureKeepsCompletionPopupHiddenAndShowsErrorMessage() async throws {
        let error = DataError.serverError(
            code: "BOOKING_INVALID_MOVE_IN_DATE",
            message: "Invalid move-in date."
        )
        var state = ListingApplicationFeature.State(
            listingID: "listing-1",
            listingTitle: "Hongdae Stay",
            roomOfferID: "room-offer-1",
            roomTypeName: "Single Room",
            roomPricingText: "₩500,000 / month"
        )
        state.hasLoadedApplicantProfile = true
        state.phoneNumber = "01012345678"
        state.isAgreementChecked = true

        let store = TestStore(
            initialState: state,
            reducer: { ListingApplicationFeature() },
            withDependencies: {
                $0.createListingBookingUseCase.execute = { _, _ in
                    throw error
                }
            }
        )

        await store.send(.submitButtonTapped) {
            $0.hasInteractedWithPhoneNumber = true
            $0.isSubmitting = true
            $0.submitErrorMessage = nil
            $0.booking = nil
        }

        await store.receive(.bookingResponse(.failure(error))) {
            $0.isSubmitting = false
            $0.submitErrorMessage = "Invalid move-in date."
            $0.isCompletionPopupPresented = false
        }
    }

    private func makeUserProfile(
        firstName: String?,
        lastName: String?,
        nickname: String,
        gender: String?,
        country: String?,
        countryName: String?,
        phoneNumber: String? = nil
    ) -> UserProfile {
        UserProfile(
            id: 13,
            userType: .tenant,
            firstName: firstName,
            lastName: lastName,
            name: nil,
            nickname: nickname,
            gender: gender,
            birthDate: nil,
            country: country,
            countryName: countryName,
            countryFlag: nil,
            occupation: nil,
            email: nil,
            visaType: nil,
            phoneNumber: phoneNumber,
            businessRegistrationNumber: nil,
            status: .active,
            termsOfServiceAgreed: true,
            privacyPolicyAgreed: true,
            marketingAgreed: false,
            createdAt: "2026-07-04T14:19:29.645714Z"
        )
    }
}
