//
//  KohereTests.swift
//  KohereTests
//
//  Created by 송규섭 on 6/11/26.
//

import XCTest
import ComposableArchitecture
@testable import Kohere

final class QuizAnswerResponseMappingTests: XCTestCase {
    func testCorrectAnswerUsesSelectedChoiceWhenCorrectChoiceIsOmitted() throws {
        let response = QuizAnswerResponseDTO(
            quizId: 1,
            selectedChoice: "B",
            correct: true,
            correctChoice: nil,
            explanation: nil
        )

        let result = try response.toEntity()

        XCTAssertEqual(result.selectedChoiceKey, "B")
        XCTAssertEqual(result.correctChoiceKey, "B")
        XCTAssertTrue(result.isCorrect)
    }

    func testIncorrectAnswerStillRequiresCorrectChoice() {
        let response = QuizAnswerResponseDTO(
            quizId: 1,
            selectedChoice: "A",
            correct: false,
            correctChoice: nil,
            explanation: nil
        )

        XCTAssertThrowsError(try response.toEntity())
    }
}

@MainActor
final class RootAuthRefreshTests: XCTestCase {
    func testTransientRefreshFailurePreservesStoredAuth() async {
        let auth = makeAuth()
        let keychain = KeychainSpy()

        let resolvedAuth = await RootFeature.resolveStoredAuth(
            auth,
            keychainClient: keychain.client,
            reissueToken: { _ in
                throw DataError.underlying(message: "network unavailable")
            }
        )

        XCTAssertEqual(resolvedAuth, auth)
        XCTAssertEqual(keychain.deleteCount, 0)
        XCTAssertEqual(keychain.saveCount, 0)
    }

    func testUnauthorizedRefreshFailureDeletesStoredAuth() async {
        let auth = makeAuth()
        let keychain = KeychainSpy()

        let resolvedAuth = await RootFeature.resolveStoredAuth(
            auth,
            keychainClient: keychain.client,
            reissueToken: { _ in
                throw DataError.httpStatus(code: 401, message: nil)
            }
        )

        XCTAssertNil(resolvedAuth)
        XCTAssertEqual(keychain.deleteCount, 1)
        XCTAssertEqual(keychain.saveCount, 0)
    }

    func testKeychainSaveFailurePreservesStoredAuth() async {
        let auth = makeAuth()
        let keychain = KeychainSpy(saveError: KeychainError.encodingFailed)

        let resolvedAuth = await RootFeature.resolveStoredAuth(
            auth,
            keychainClient: keychain.client,
            reissueToken: { _ in
                AuthToken(
                    tokenType: "Bearer",
                    accessToken: "new-access-token",
                    refreshToken: "new-refresh-token",
                    expiresIn: 3600
                )
            }
        )

        XCTAssertEqual(resolvedAuth, auth)
        XCTAssertEqual(keychain.deleteCount, 0)
        XCTAssertEqual(keychain.saveCount, 1)
    }

    private func makeAuth() -> Auth {
        Auth(
            onboardingRequired: false,
            status: .active,
            tokenType: "Bearer",
            accessToken: "old-access-token",
            refreshToken: "old-refresh-token",
            expiresIn: 0,
            expiresAt: Date(timeIntervalSince1970: 0)
        )
    }

    private final class KeychainSpy: @unchecked Sendable {
        var deleteCount = 0
        var saveCount = 0
        let saveError: Error?

        init(saveError: Error? = nil) {
            self.saveError = saveError
        }

        var client: KeychainClient {
            KeychainClient(
                save: { [self] _, _ in
                    saveCount += 1
                    if let saveError {
                        throw saveError
                    }
                },
                read: { _ in nil },
                delete: { [self] _ in
                    deleteCount += 1
                }
            )
        }
    }
}

@MainActor
final class MapFavoriteSyncTests: XCTestCase {
    func testSynchronizeFavoriteStatusUpdatesVisibleListingAndOverride() {
        var state = MapFeature.State()
        let status = ListingFavoriteStatus(isFavorited: false, favoriteCount: 4)

        state.listings = [
            makeListingItem(id: "listing-1", isLiked: true, favoriteCount: 5),
            makeListingItem(id: "listing-2", isLiked: true, favoriteCount: 8)
        ]

        state.synchronizeFavoriteStatus(status, for: "listing-1")

        XCTAssertEqual(state.favoriteStatusesByListingID["listing-1"], status)
        XCTAssertFalse(state.listings[0].isLiked)
        XCTAssertEqual(state.listings[0].favoriteCount, 4)
        XCTAssertTrue(state.listings[1].isLiked)
        XCTAssertEqual(state.listings[1].favoriteCount, 8)
    }

    func testSynchronizeFavoriteStatusStoresOverrideWhenListingIsNotCurrentlyLoaded() {
        var state = MapFeature.State()
        let status = ListingFavoriteStatus(isFavorited: false, favoriteCount: 0)

        state.synchronizeFavoriteStatus(status, for: "listing-1")

        XCTAssertEqual(state.favoriteStatusesByListingID["listing-1"], status)
        XCTAssertTrue(state.listings.isEmpty)
    }

    private func makeListingItem(
        id: String,
        isLiked: Bool,
        favoriteCount: Int
    ) -> ListingItemModel {
        ListingItemModel(
            id: id,
            title: "Listing \(id)",
            formattedPrice: "₩500,000 / month",
            formattedUsdPrice: "$360 / month",
            detailsDescription: "Studio",
            locationDescription: "Seoul",
            typeTag: "Apartment",
            period: "6 months",
            isLiked: isLiked,
            favoriteCount: favoriteCount
        )
    }
}

@MainActor
final class MapListingNavigationTests: XCTestCase {
    func testListingCardTappedNavigatesDirectlyToDetail() async {
        let store = TestStore(initialState: MapFeature.State()) {
            MapFeature()
        }

        await store.send(.listingCardTapped("listing-1")) {
            $0.path.append(
                .listingDetail(ListingDetailFeature.State(listingID: "listing-1"))
            )
        }
    }

    func testMarkerTappedStillPresentsSelectedListingSheet() async {
        let store = TestStore(initialState: MapFeature.State()) {
            MapFeature()
        }

        await store.send(.markerTapped("listing-1")) {
            $0.selectedMarkerID = "listing-1"
            $0.sheetMode = .selectedListing
        }
    }

    func testListingMapPreviewPreservesResultsAndPreparesLocationSearch() async {
        let coordinate = MapCoordinate(latitude: 37.5559, longitude: 126.9250)
        let marker = MapMarkerItem(id: "listing-1", coordinate: coordinate)
        let listing = ListingItemModel(
            id: "listing-1",
            formattedPrice: "₩500,000 / month",
            formattedUsdPrice: "$360 / month",
            detailsDescription: "Studio",
            locationDescription: "Seoul",
            typeTag: "Apartment",
            period: "6 months",
            isLiked: false
        )
        var initialState = MapFeature.State()
        initialState.path.append(
            .listingDetail(ListingDetailFeature.State(listingID: "listing-1"))
        )
        initialState.markers = [marker]
        initialState.listings = [listing]
        initialState.selectedMarkerID = marker.id
        initialState.sheetMode = .selectedListing
        initialState.listingSource = .diagnosis
        initialState.activeDiagnosisID = 1
        initialState.appliedFilterSource = .diagnosis
        initialState.isRecommendationsLoading = true
        initialState.recommendationsErrorMessage = "이전 추천 오류"

        let store = TestStore(initialState: initialState) {
            MapFeature()
        }

        await store.send(.listingMapPreviewRequested(coordinate)) {
            $0.path.removeAll()
            $0.selectedMarkerID = nil
            $0.sheetMode = .listingList
            $0.listingSource = .locationSearch
            $0.activeDiagnosisID = nil
            $0.appliedFilterSource = .manual
            $0.isRecommendationsLoading = false
            $0.recommendationsErrorMessage = nil
            $0.placeSearchTarget = MapPlaceSearchTarget(coordinate: coordinate)
            $0.cameraMoveRequest = MapCameraMoveRequest(
                coordinate: coordinate,
                targetPosition: .upper
            )
        }

        XCTAssertEqual(store.state.markers, [marker])
        XCTAssertEqual(store.state.listings, [listing])
    }
}

@MainActor
final class ListingApplicationFeatureTests: XCTestCase {
    func testPreviousButtonOnDateSelectionRequestsNavigationBack() async {
        let store = TestStore(
            initialState: ListingApplicationFeature.State(
                listingID: "listing-1",
                listingTitle: "Hongdae Stay",
                roomOfferID: "room-offer-1",
                roomTypeName: "Single Room",
                roomPricingText: "₩500,000 / month"
            ),
            reducer: { ListingApplicationFeature() }
        )

        await store.send(.previousButtonTapped)
        await store.receive(.backButtonTapped)
    }

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

    func testSettingDocumentsUseNotionLinks() {
        XCTAssertEqual(
            SettingDocument.termsOfService.url.absoluteString,
            "https://jewel-humor-b3e.notion.site/39777dadb98580ad9a47eda58626c047?source=copy_link"
        )
        XCTAssertEqual(
            SettingDocument.privacyPolicy.url.absoluteString,
            "https://jewel-humor-b3e.notion.site/39777dadb9858039b2aedef03251cdf4?source=copy_link"
        )
        XCTAssertEqual(
            SettingDocument.marketingAgreement.url.absoluteString,
            "https://jewel-humor-b3e.notion.site/39077dadb985802ba1a8ffb0472238e4?source=copy_link"
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

@MainActor
final class ListingRecentResponseDTOTests: XCTestCase {
    func testNestedRecentListingResponseDecodesUsingListingListItemShape() throws {
        let data = Data(
            #"""
            {
              "success": true,
              "data": {
                "content": [
                  {
                    "listingId": "listing-1",
                    "title": "회기 고시원",
                    "type": "GOSHIWON",
                    "contract": {
                      "minStayMonths": 1,
                      "maxStayMonths": 3
                    },
                    "location": {
                      "lat": 37.604268,
                      "lng": 127.046761
                    },
                    "address": {
                      "city": "SEOUL",
                      "district": "DONGDAEMUN_GU",
                      "fullAddress": "서울특별시 동대문구 회기동",
                      "detail": null
                    },
                    "roomOffers": [
                      {
                        "roomOfferId": "room-1",
                        "name": "스탠다드 1인실",
                        "status": "ACTIVE",
                        "pricing": {
                          "monthlyRent": 200000,
                          "deposit": 0,
                          "maintenanceFee": 0,
                          "currency": "KRW"
                        },
                        "inventory": null,
                        "filterTags": [],
                        "roomImageUrls": []
                      }
                    ],
                    "imageUrls": [],
                    "favorited": true,
                    "favoriteCount": 3,
                    "viewedAt": "2026-07-11T14:30:10.882Z"
                  }
                ]
              },
              "error": null
            }
            """#.utf8
        )

        let response = try JSONDecoder().decode(
            BaseResponseDTO<ListingRecentListResponseDTO>.self,
            from: data
        )
        let listing = try XCTUnwrap(response.data?.content?.first)

        XCTAssertEqual(listing.address?.fullAddress, "서울특별시 동대문구 회기동")
        XCTAssertEqual(listing.location?.lat, 37.604268)
        XCTAssertEqual(listing.roomOffers?.first?.pricing?.monthlyRent, 200000)
        XCTAssertEqual(listing.favorited, true)
    }
}

@MainActor
final class RootFavoritePropagationTests: XCTestCase {
    func testMapDetailFavoriteSuccessUpdatesMapCardAndHomeCard() async throws {
        let status = ListingFavoriteStatus(isFavorited: true, favoriteCount: 7)
        var state = RootFeature.State(isAuthLoading: false)
        state.home.recentlyViewedItems = [makeListingItem(isLiked: false, favoriteCount: 6)]
        state.map.listings = [makeListingItem(isLiked: false, favoriteCount: 6)]
        state.map.path.append(
            .listingDetail(
                ListingDetailFeature.State(
                    listingID: "listing-1",
                    userType: .tenant
                )
            )
        )
        let detailID = try XCTUnwrap(state.map.path.ids.last)

        let store = TestStore(
            initialState: state,
            reducer: { RootFeature() }
        )

        await store.send(
            .map(
                .path(
                    .element(
                        id: detailID,
                        action: .listingDetail(.favoriteStatusResponse(.success(status)))
                    )
                )
            )
        ) {
            $0.map.path[id: detailID, case: \.listingDetail]?.detail.overview.isLiked = true
            $0.map.path[id: detailID, case: \.listingDetail]?.detail.overview.favoriteCount = 7
            $0.home.recentlyViewedItems[0].isLiked = true
            $0.home.recentlyViewedItems[0].favoriteCount = 7
            $0.map.listings[0].isLiked = true
            $0.map.listings[0].favoriteCount = 7
            $0.map.favoriteStatusesByListingID["listing-1"] = status
        }
    }

    private func makeListingItem(
        isLiked: Bool,
        favoriteCount: Int
    ) -> ListingItemModel {
        ListingItemModel(
            id: "listing-1",
            title: "Listing",
            formattedPrice: "₩500,000 / month",
            formattedUsdPrice: "$360 / month",
            detailsDescription: "Studio",
            locationDescription: "Seoul",
            typeTag: "Apartment",
            period: "6 months",
            isLiked: isLiked,
            favoriteCount: favoriteCount
        )
    }
}
