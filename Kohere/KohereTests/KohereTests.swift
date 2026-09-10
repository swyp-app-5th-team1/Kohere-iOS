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

final class LanguageUpdateRequestDTOTests: XCTestCase {
    func testLanguageOnlyUpdateEncodesOnlyLangField() throws {
        let request = UpdateProfileRequestDTO(
            UserProfileUpdate(lang: AppLanguage.english.apiCode)
        )

        let data = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(json.count, 1)
        XCTAssertEqual(json["lang"] as? String, "en")
    }
}

final class AppLanguageTests: XCTestCase {
    func testAPICodeRestoresLanguage() {
        XCTAssertEqual(AppLanguage(apiCode: "ko"), .korean)
        XCTAssertEqual(AppLanguage(apiCode: "en"), .english)
        XCTAssertNil(AppLanguage(apiCode: "ja"))
    }

    func testCodableKeepsExistingLanguageCodeFormat() throws {
        let data = try JSONEncoder().encode(AppLanguage.korean)
        XCTAssertEqual(String(data: data, encoding: .utf8), "\"ko\"")
        XCTAssertEqual(try JSONDecoder().decode(AppLanguage.self, from: data), .korean)
    }

    func testLocaleResolutionFallsBackToEnglish() {
        XCTAssertEqual(AppLanguageResolver.resolve(from: Locale(identifier: "ko-KR")), .korean)
        XCTAssertEqual(AppLanguageResolver.resolve(from: Locale(identifier: "en-US")), .english)
        XCTAssertEqual(AppLanguageResolver.resolve(from: Locale(identifier: "ja-JP")), .english)
    }
}

final class OnboardingLocalizationTests: XCTestCase {
    func testKoreanEmailVerificationCopyIsLocalized() {
        XCTAssertEqual(
            AppLanguage.korean.localizedString(forKey: "onboarding.email.placeholder"),
            "이메일을 입력해주세요"
        )
        XCTAssertEqual(
            AppLanguage.korean.localizedString(forKey: "onboarding.verification.emailSent"),
            "이메일로 인증번호를 전송했어요"
        )
        XCTAssertEqual(
            AppLanguage.korean.localizedString(forKey: "onboarding.verification.email.placeholder"),
            "전송된 6자리 코드를 입력해주세요"
        )
    }
}

@MainActor
final class UserProfileLanguageResponseDTOTests: XCTestCase {
    func testProfileResponseDecodesLanguage() throws {
        let data = Data(
            """
            {
              "id": 13,
              "userType": "LANDLORD",
              "name": "Kohere Host",
              "nickname": null,
              "gender": null,
              "birthDate": null,
              "country": "KR",
              "countryName": "대한민국",
              "countryFlag": null,
              "occupation": null,
              "email": "host@kohere.app",
              "visaType": null,
              "phoneNumber": null,
              "businessRegistrationNumber": null,
              "status": "ACTIVE",
              "termsOfServiceAgreed": true,
              "privacyPolicyAgreed": true,
              "marketingAgreed": false,
              "lang": "ko",
              "createdAt": "2026-07-18T00:00:00"
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(UserProfileResponseDTO.self, from: data)

        XCTAssertEqual(response.lang, "ko")
    }
}

final class ListingCardLocalizationTests: XCTestCase {
    func testEnglishListingCardUsesCompactKoreanWonAndEnglishLabels() {
        let item = ListingItemModel(listing: makeListing(), language: .english)

        XCTAssertEqual(item.formattedPrice, "₩380~400K/mo")
        XCTAssertEqual(item.detailsDescription, "Dep. ₩200K · Maint. ₩20K")
        XCTAssertEqual(item.locationDescription, "8-min walk Hongdae Station")
        XCTAssertEqual(item.period, "1 mo~")
    }

    func testKoreanListingCardKeepsKoreanPriceAndLabels() {
        let item = ListingItemModel(listing: makeListing(), language: .korean)

        XCTAssertEqual(item.formattedPrice, "월세 38~40만원")
        XCTAssertEqual(item.detailsDescription, "보증금 20만원 · 관리비 2만원")
        XCTAssertEqual(item.locationDescription, "Hongdae Station 도보 8분")
        XCTAssertEqual(item.period, "한달 이상")
    }

    func testMapFilterAmountUsesRuntimeLocale() {
        XCTAssertEqual(
            MapFilterPriceFormatter.amountText(50, locale: AppLanguage.english.locale),
            "₩500K"
        )
        XCTAssertEqual(
            MapFilterPriceFormatter.amountText(50, locale: AppLanguage.korean.locale),
            "50만 원"
        )
    }

    private func makeListing() -> Listing {
        Listing(
            listingID: "listing-1",
            title: "Hongdae House",
            type: "Goshiwon",
            minMonthlyRent: 380_000,
            maxMonthlyRent: 400_000,
            minDeposit: 200_000,
            maxDeposit: 200_000,
            minMaintenanceFee: 20_000,
            maxMaintenanceFee: 20_000,
            minStayMonths: 1,
            maxStayMonths: nil,
            thumbnailURL: nil,
            coordinate: nil,
            address: nil,
            nearestTransit: ListingNearestTransit(
                type: "SUBWAY",
                name: "Hongdae Station",
                walkMinutes: 8
            ),
            distanceMeters: nil,
            isFavorited: false,
            favoriteCount: 0
        )
    }
}

final class ListingDetailValueFormatterLocalizationTests: XCTestCase {
    func testDepositRangeUsesSingleWonSymbolAcrossDifferentUnits() {
        XCTAssertEqual(
            ListingDetailValueFormatter.priceRowValue(
                min: 0,
                max: 3_000_000,
                language: .english
            ),
            "₩0~3M"
        )
    }

    func testMonthlyRentUsesExplicitAppLanguage() {
        XCTAssertEqual(
            ListingDetailValueFormatter.monthlyRentTitle(
                min: 380_000,
                max: 400_000,
                language: .english
            ),
            "₩380~400K/mo"
        )
        XCTAssertEqual(
            ListingDetailValueFormatter.monthlyRentTitle(
                min: 380_000,
                max: 400_000,
                language: .korean
            ),
            "월세 38~40만 원"
        )
    }

    /// 서버는 `name`에 "Anguk Station"처럼 완성된 역명을 내려준다.
    /// 앱 포맷은 소요 시간만 조합하고 역/정류장 접미사를 덧붙이지 않아야 한다.
    func testTransitDoesNotAppendStationSuffixToServerName() {
        let transit = ListingDetailNearestTransit(
            type: "SUBWAY",
            name: "Anguk Station",
            walkMinutes: 8,
            nearbyPlacesDescription: nil
        )

        XCTAssertEqual(
            ListingDetailValueFormatter.transitTitle(transit, language: .english),
            "8-min walk Anguk Station"
        )
        XCTAssertEqual(
            ListingDetailValueFormatter.transitTitle(transit, includesFrom: true, language: .english),
            "8-min walk from Anguk Station"
        )
        XCTAssertEqual(
            ListingDetailValueFormatter.transitTitle(transit, language: .korean),
            "Anguk Station 도보 8분"
        )
    }
}

final class ChatApplicationCardFormatterTests: XCTestCase {
    func testChatRoomDetailDoesNotFabricateMissingApplicantDetails() {
        let model = makeChatRoomModel(deposit: 0)

        XCTAssertEqual(model.applicantGenderCode, "")
        XCTAssertEqual(model.applicantCountryCode, "")
        XCTAssertEqual(model.applicantCountryName, "")
        XCTAssertEqual(model.applicantEmail, "N/A")
        XCTAssertEqual(model.roomType, "N/A")
    }

    func testZeroDepositIsDisplayedAsValidAmount() {
        let formatter = ChatApplicationCardFormatter(
            item: makeChatRoomModel(deposit: 0),
            language: .english
        )

        XCTAssertEqual(formatter.deposit, "₩ 0")
    }

    private func makeChatRoomModel(deposit: Int) -> ChatRoomModel {
        return ChatRoomModel(
            roomID: 1,
            listingID: "listing-1",
            listingName: "Listing",
            location: "Seoul",
            createdAt: Date(timeIntervalSince1970: 0),
            applicantName: "Applicant",
            roomType: "N/A",
            moveInDate: Date(timeIntervalSince1970: 0),
            leaseTermMonths: 1,
            depositAmount: deposit,
            totalCostAmount: 0
        )
    }
}

@MainActor
final class LanguageSelectionTests: XCTestCase {
    func testSelectingDifferentLanguageRequestsLocalizedResetConfirmation() async {
        var initialState = MoreFeature.State()
        initialState.isLanguagePopoverPresented = true
        initialState.selectedLanguage = .korean
        let store = TestStore(initialState: initialState) {
            MoreFeature()
        }

        await store.send(.languageSelected(.english)) {
            $0.isLanguagePopoverPresented = false
        }

        await store.receive(
            \.popupRequested,
            .action(
                AppPopup.Action(
                    message: "언어를 변경하면 진행 중인 화면과 검색 설정이 초기화됩니다. 변경할까요?",
                    primaryTitle: "변경하기",
                    secondaryTitle: "취소",
                    route: .confirmLanguageChange(.english)
                )
            )
        )
    }

    func testSelectingCurrentLanguageOnlyClosesPopover() async {
        var initialState = MoreFeature.State()
        initialState.isLanguagePopoverPresented = true
        initialState.selectedLanguage = .korean
        let store = TestStore(initialState: initialState) {
            MoreFeature()
        }

        await store.send(.languageSelected(.korean)) {
            $0.isLanguagePopoverPresented = false
        }
    }
}

@MainActor
final class LanguageResetTests: XCTestCase {
    func testLanguageResetPreservesSessionAndRecreatesMainTabState() {
        let auth = Auth(
            onboardingRequired: false,
            status: .active,
            tokenType: "Bearer",
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let profile = UserProfile(
            id: 13,
            userType: .tenant,
            name: "Hong Gildong",
            nickname: "tester",
            gender: nil,
            birthDate: nil,
            country: "KR",
            countryName: "대한민국",
            countryFlag: nil,
            occupation: nil,
            email: nil,
            visaType: nil,
            phoneNumber: nil,
            businessRegistrationNumber: nil,
            status: .active,
            termsOfServiceAgreed: true,
            privacyPolicyAgreed: true,
            marketingAgreed: false,
            lang: "ko",
            createdAt: "2026-07-18T00:00:00"
        )
        var state = RootFeature.State(
            authInfo: auth,
            currentUser: profile,
            isAuthLoading: false,
            selectedTab: .map
        )
        state.home.isQuizLoaded = true
        state.map.isFilterPresented = true
        state.more.path.append(.setting(SettingFeature.State()))
        state.popup = .notice(AppPopup.Notice(message: "popup", confirmTitle: "confirm"))

        RootFeature().resetMainContent(
            language: .english,
            userProfile: profile,
            state: &state
        )

        XCTAssertEqual(state.authInfo, auth)
        XCTAssertEqual(state.currentUser, profile)
        XCTAssertEqual(state.appLanguage, .english)
        XCTAssertEqual(state.selectedTab, .more)
        XCTAssertNil(state.popup)
        XCTAssertFalse(state.home.isQuizLoaded)
        XCTAssertFalse(state.map.isFilterPresented)
        XCTAssertTrue(state.more.path.isEmpty)
        XCTAssertEqual(state.home.userType, .tenant)
        XCTAssertEqual(state.home.appLanguage, .english)
        XCTAssertEqual(state.map.userType, .tenant)
        XCTAssertEqual(state.map.appLanguage, .english)
        XCTAssertEqual(state.more.userProfile, profile)
        XCTAssertEqual(state.more.selectedLanguage, .english)
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
                throw DataError.transport(message: "network unavailable")
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

    func testDocumentedInvalidRefreshTokenCodeDeletesStoredAuth() async {
        let auth = makeAuth()
        let keychain = KeychainSpy()

        let resolvedAuth = await RootFeature.resolveStoredAuth(
            auth,
            keychainClient: keychain.client,
            reissueToken: { _ in
                throw DataError.serverError(
                    code: "AUTH_INVALID_REFRESH_TOKEN",
                    message: "Invalid refresh token."
                )
            }
        )

        XCTAssertNil(resolvedAuth)
        XCTAssertEqual(keychain.deleteCount, 1)
        XCTAssertEqual(keychain.saveCount, 0)
    }

    func testDocumentedInvalidReissueInputCodeDeletesStoredAuth() async {
        let auth = makeAuth()
        let keychain = KeychainSpy()

        let resolvedAuth = await RootFeature.resolveStoredAuth(
            auth,
            keychainClient: keychain.client,
            reissueToken: { _ in
                throw DataError.serverError(
                    code: "INVALID_INPUT",
                    message: "Invalid input."
                )
            }
        )

        XCTAssertNil(resolvedAuth)
        XCTAssertEqual(keychain.deleteCount, 1)
        XCTAssertEqual(keychain.saveCount, 0)
    }

    func testKeychainSaveFailureDeletesStoredAuth() async {
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

        XCTAssertNil(resolvedAuth)
        XCTAssertEqual(keychain.deleteCount, 1)
        XCTAssertEqual(keychain.saveCount, 1)
    }

    func testRuntimeRefreshTransportFailurePreservesSession() {
        XCTAssertTrue(
            AuthInterceptor.shouldPreserveAuthAfterRefreshFailure(
                DataError.transport(message: "network unavailable")
            )
        )
    }

    func testRuntimeRefreshNonTransportFailuresExpireSession() {
        XCTAssertFalse(
            AuthInterceptor.shouldPreserveAuthAfterRefreshFailure(
                DataError.httpStatus(code: 500, message: nil)
            )
        )
        XCTAssertFalse(
            AuthInterceptor.shouldPreserveAuthAfterRefreshFailure(
                DataError.decodingFailed
            )
        )
        XCTAssertFalse(
            AuthInterceptor.shouldPreserveAuthAfterRefreshFailure(
                KeychainError.encodingFailed
            )
        )
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
final class LoginAuthPersistenceTests: XCTestCase {
    func testExistingUserLoginCompletesAfterAuthIsStored() async {
        let auth = Auth(
            onboardingRequired: false,
            status: .active,
            tokenType: "Bearer",
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600,
            expiresAt: Date().addingTimeInterval(3600)
        )
        let keychain = LoginKeychainSpy()
        let store = TestStore(
            initialState: LoginFeature.State(isLoginRequesting: true)
        ) {
            LoginFeature()
        } withDependencies: {
            $0.keychainClient = keychain.client
        }

        await store.send(.loginSuccess(auth)) {
            $0.authInfo = auth
            $0.loginErrorMessage = nil
            $0.currentSheet = nil
        }
        await store.receive(.loginAuthStored(auth)) {
            $0.isLoginRequesting = false
        }

        XCTAssertEqual(keychain.saveCount, 1)
    }

    private final class LoginKeychainSpy: @unchecked Sendable {
        var saveCount = 0

        var client: KeychainClient {
            KeychainClient(
                save: { [self] _, _ in saveCount += 1 },
                read: { _ in nil },
                delete: { _ in }
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
        initialState.isListingSearchLoading = true
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
            $0.isListingSearchLoading = false
            $0.isRecommendationsLoading = false
            $0.recommendationsErrorMessage = nil
            $0.pendingViewportSearchTarget = MapPendingViewportSearchTarget(coordinate: coordinate)
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
final class MapDiagnosisRecommendationTests: XCTestCase {
    func testDiagnosisPaginationPreservesAllMarkers() {
        let firstCoordinate = MapCoordinate(latitude: 37.604268, longitude: 127.046761)
        let nextCoordinate = MapCoordinate(latitude: 37.595316, longitude: 127.051202)
        var state = MapFeature.State()
        let allMarkers = [
            MapMarkerItem(id: "listing-1", coordinate: firstCoordinate),
            MapMarkerItem(id: "listing-2", coordinate: nextCoordinate),
            MapMarkerItem(id: "outside-loaded-pages", coordinate: firstCoordinate)
        ]
        state.markers = allMarkers
        let feature = withDependencies {
            $0.fetchKRWToUSDExchangeRateUseCase = FetchKRWToUSDExchangeRateUseCase {
                KRWToUSDExchangeRate(usdPerKRW: 0)
            }
        } operation: {
            MapFeature()
        }

        feature.applyDiagnosisRecommendations(
            makeRecommendations(
                listing: makeRecommendation(id: "listing-1", coordinate: firstCoordinate),
                pageNumber: 0
            ),
            isFirstPage: true,
            to: &state
        )
        feature.applyDiagnosisRecommendations(
            makeRecommendations(
                listing: makeRecommendation(id: "listing-2", coordinate: nextCoordinate),
                pageNumber: 1
            ),
            isFirstPage: false,
            to: &state
        )

        XCTAssertEqual(state.markers, allMarkers)
        XCTAssertEqual(state.diagnosisRecommendedListings.map(\.listingID), ["listing-1", "listing-2"])
    }

    private func makeRecommendations(
        listing: DiagnosisRecommendedListing,
        pageNumber: Int
    ) -> DiagnosisRecommendations {
        DiagnosisRecommendations(
            listings: [listing],
            page: PageInfo(
                number: pageNumber,
                size: 1,
                totalElements: 2,
                totalPages: 2,
                hasNext: pageNumber == 0
            ),
            suggestions: nil
        )
    }

    private func makeRecommendation(
        id: String,
        coordinate: MapCoordinate
    ) -> DiagnosisRecommendedListing {
        DiagnosisRecommendedListing(
            listingID: id,
            title: "Listing \(id)",
            type: "Goshiwon",
            minMonthlyRent: 200_000,
            maxMonthlyRent: 300_000,
            minDeposit: 0,
            maxDeposit: 100_000,
            thumbnailURL: nil,
            coordinate: coordinate,
            nearestTransit: nil
        )
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
        XCTAssertEqual(
            state.submitButtonTitle,
            String(localized: "listingApplication.action.submit")
        )
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
            name: "Song NunSeop",
            nickname: "DreamyPuma",
            gender: "MALE",
            country: "KR",
            countryName: "South Korea"
        )

        XCTAssertEqual(
            ListingApplicationFeature.applicantSummary(
                from: profile,
                locale: Locale(identifier: "en_US")
            ),
            "Song NunSeop · Male · South Korea"
        )
    }

    func testApplicantSummaryOmitsMissingName() {
        let profile = makeUserProfile(
            name: nil,
            nickname: "",
            gender: "MALE",
            country: "KR",
            countryName: "South Korea"
        )

        XCTAssertEqual(
            ListingApplicationFeature.applicantSummary(
                from: profile,
                locale: Locale(identifier: "ko_KR")
            ),
            "남성 · 대한민국"
        )
    }

    func testSubmittingKeepsDefaultSubmitButtonTitle() {
        var state = ListingApplicationFeature.State(
            listingID: "listing-1",
            listingTitle: "Hongdae Stay",
            roomOfferID: "room-offer-1",
            roomTypeName: "Single Room",
            roomPricingText: "₩500,000 / month"
        )
        let defaultTitle = state.submitButtonTitle

        state.isSubmitting = true

        XCTAssertEqual(state.submitButtonTitle, defaultTitle)
        XCTAssertFalse(state.isSubmitButtonEnabled)
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
            name: "Song NunSeop",
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
                roomPricingText: "₩500,000 / month",
                appLanguage: .english
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
            $0.applicantSummary = ListingApplicationFeature.applicantSummary(from: profile)
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
        name: String?,
        nickname: String,
        gender: String?,
        country: String?,
        countryName: String?,
        phoneNumber: String? = nil
    ) -> UserProfile {
        UserProfile(
            id: 13,
            userType: .tenant,
            name: name,
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
            lang: "en",
            createdAt: "2026-07-04T14:19:29.645714Z"
        )
    }
}

@MainActor
final class ListingRecentResponseDTOTests: XCTestCase {
    func testRecentListingV2ResponseDecodesSharedItemShapeWithViewedAt() throws {
        let data = Data(
            #"""
            {
              "success": true,
              "data": {
                "content": [
                  {
                    "listingId": "68e0000000000000000000a1",
                    "title": "Sillim Stay",
                    "type": { "code": "GOSHIWON", "label": "Goshiwon" },
                    "status": "PUBLISHED",
                    "rentalType": { "code": "MONTHLY_RENT", "label": "Monthly Rent" },
                    "genderPolicy": { "code": "FEMALE_ONLY", "label": "Female Only" },
                    "location": { "lat": 37.459471, "lng": 126.951422 },
                    "address": {
                      "city": { "code": "SEOUL", "label": "Seoul" },
                      "district": { "code": "GWANAK_GU", "label": "Gwanak-gu" },
                      "fullAddress": "56-15 Na-ro, Sillim-dong, Gwanak-gu, Seoul",
                      "detail": null
                    },
                    "nearestTransit": {
                      "type": { "code": "SUBWAY", "label": "Subway" },
                      "name": "Seoul Nat'l Univ. Sta.",
                      "walkMinutes": 5
                    },
                    "roomOffers": [
                      {
                        "roomOfferId": "68e0000000000000000001a1",
                        "name": "Standard Single Room",
                        "status": "ACTIVE",
                        "contract": { "minStayMonths": 1, "maxStayMonths": 12 },
                        "pricing": {
                          "monthlyRent": 380000,
                          "deposit": 300000,
                          "maintenanceFee": 0,
                          "currency": "KRW"
                        },
                        "filterTags": [],
                        "roomImageUrls": []
                      }
                    ],
                    "imageUrls": [
                      "https://cdn.kohere.app/listings/68e0000000000000000000a1/1.jpg"
                    ],
                    "favorited": true,
                    "favoriteCount": 1,
                    "createdAt": "2026-08-01T00:00:00Z",
                    "updatedAt": "2026-08-01T00:00:00Z",
                    "viewedAt": "2026-08-24T15:30:49.240Z"
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

        XCTAssertEqual(listing.listingId, "68e0000000000000000000a1")
        XCTAssertEqual(listing.address?.city?.label, "Seoul")
        XCTAssertEqual(listing.address?.fullAddress, "56-15 Na-ro, Sillim-dong, Gwanak-gu, Seoul")
        XCTAssertEqual(listing.location?.lat, 37.459471)
        XCTAssertEqual(listing.roomOffers?.first?.contract?.maxStayMonths, 12)
        XCTAssertEqual(listing.roomOffers?.first?.pricing?.monthlyRent, 380000)
        XCTAssertEqual(listing.favorited, true)
        XCTAssertEqual(listing.viewedAt, "2026-08-24T15:30:49.240Z")
        XCTAssertNil(listing.favoritedAt)
    }
}

@MainActor
final class ListingFavoriteListResponseDTOTests: XCTestCase {
    func testFavoriteListV2ResponseDecodesCodeLabelAddressAndRoomOfferContract() throws {
        let data = Data(
            #"""
            {
              "success": true,
              "data": {
                "content": [
                  {
                    "listingId": "68e0000000000000000000a1",
                    "title": "Sillim Stay",
                    "type": { "code": "GOSHIWON", "label": "Goshiwon" },
                    "status": "PUBLISHED",
                    "rentalType": { "code": "MONTHLY_RENT", "label": "Monthly Rent" },
                    "refundPolicy": "Full refund if cancelled at least 7 days before move-in; 50% afterwards.",
                    "genderPolicy": { "code": "FEMALE_ONLY", "label": "Female Only" },
                    "arcRequired": { "code": "NOT_REQUIRED", "label": "ARC Not Required" },
                    "ageMin": 20,
                    "ageMax": 35,
                    "languagesSupported": [
                      { "code": "ENGLISH", "label": "English" }
                    ],
                    "contact": { "managerName": "김운영", "phone": "+82) 10-1234-5678" },
                    "blogUrl": "https://blog.naver.com/kohere-goshiwon",
                    "location": { "lat": 37.459471, "lng": 126.951422 },
                    "address": {
                      "city": { "code": "SEOUL", "label": "Seoul" },
                      "district": { "code": "GWANAK_GU", "label": "Gwanak-gu" },
                      "fullAddress": "56-15 Na-ro, Sillim-dong, Gwanak-gu, Seoul",
                      "detail": null
                    },
                    "nearestTransit": {
                      "type": { "code": "SUBWAY", "label": "Subway" },
                      "name": "Seoul Nat'l Univ. Sta.",
                      "walkMinutes": 5
                    },
                    "nearbyFacilities": [
                      { "code": "CONVENIENCE_STORE", "label": "Convenience Store" }
                    ],
                    "nearbyUniversityCodes": ["SNU", "CAU", "SOONGSIL"],
                    "building": {
                      "type": { "code": "VILLA", "label": "Villa" },
                      "usedFloorMin": 1,
                      "usedFloorMax": 2,
                      "totalFloors": 4,
                      "parkingAvailable": true,
                      "elevatorAvailable": true
                    },
                    "facilities": {
                      "heatingSystem": [ { "code": "CENTRAL", "label": "Central Heating" } ],
                      "commonSpaces": [ { "code": "SHARED_KITCHEN", "label": "Shared Kitchen" } ]
                    },
                    "conditions": [
                      { "code": "MOVE_IN_NOW", "label": "Move-in Now" }
                    ],
                    "roomOffers": [
                      {
                        "roomOfferId": "68e0000000000000000001a1",
                        "name": "Standard Single Room",
                        "status": "ACTIVE",
                        "contract": { "minStayMonths": 1, "maxStayMonths": 12 },
                        "pricing": {
                          "monthlyRent": 380000,
                          "deposit": 300000,
                          "maintenanceFee": 0,
                          "currency": "KRW"
                        },
                        "filterTags": [ { "code": "MOVE_IN_NOW", "label": "Move-in Now" } ],
                        "roomImageUrls": [
                          "https://cdn.kohere.app/listings/68e0000000000000000000a1/room/1.jpg"
                        ]
                      },
                      {
                        "roomOfferId": "68e0000000000000000001a2",
                        "name": "Premium Single Room",
                        "status": "ACTIVE",
                        "contract": { "minStayMonths": 3, "maxStayMonths": 24 },
                        "pricing": {
                          "monthlyRent": 520000,
                          "deposit": 500000,
                          "maintenanceFee": 20000,
                          "currency": "KRW"
                        },
                        "filterTags": [],
                        "roomImageUrls": []
                      }
                    ],
                    "description": "A female-only goshiwon near Sillim Station, five minutes on foot.",
                    "extraNotes": "No cooking inside rooms. Quiet hours after 11 PM.",
                    "imageUrls": [
                      "https://cdn.kohere.app/listings/68e0000000000000000000a1/1.jpg"
                    ],
                    "favorited": true,
                    "favoriteCount": 1,
                    "createdAt": "2026-08-01T00:00:00Z",
                    "updatedAt": "2026-08-01T00:00:00Z",
                    "favoritedAt": "2026-08-24T15:30:49.173Z"
                  }
                ],
                "page": {
                  "number": 0,
                  "size": 20,
                  "totalElements": 1,
                  "totalPages": 1,
                  "hasNext": false
                }
              },
              "error": null
            }
            """#.utf8
        )

        let response = try JSONDecoder().decode(
            BaseResponseDTO<ListingFavoriteListResponseDTO>.self,
            from: data
        )
        let listing = try XCTUnwrap(response.data?.content?.first)

        XCTAssertEqual(listing.listingId, "68e0000000000000000000a1")
        XCTAssertEqual(listing.type?.label, "Goshiwon")
        XCTAssertEqual(listing.address?.city?.code, "SEOUL")
        XCTAssertEqual(listing.address?.district?.label, "Gwanak-gu")
        XCTAssertEqual(listing.address?.fullAddress, "56-15 Na-ro, Sillim-dong, Gwanak-gu, Seoul")
        XCTAssertEqual(listing.nearestTransit?.name, "Seoul Nat'l Univ. Sta.")
        XCTAssertEqual(listing.nearestTransit?.walkMinutes, 5)
        XCTAssertEqual(listing.roomOffers?.count, 2)
        XCTAssertEqual(listing.roomOffers?.first?.contract?.minStayMonths, 1)
        XCTAssertEqual(listing.roomOffers?.last?.contract?.maxStayMonths, 24)
        XCTAssertEqual(listing.roomOffers?.first?.pricing?.monthlyRent, 380000)
        XCTAssertEqual(listing.imageUrls?.first, "https://cdn.kohere.app/listings/68e0000000000000000000a1/1.jpg")
        XCTAssertEqual(listing.favorited, true)
        XCTAssertEqual(listing.favoriteCount, 1)
        XCTAssertEqual(listing.favoritedAt, "2026-08-24T15:30:49.173Z")
        XCTAssertEqual(response.data?.page?.totalElements, 1)
        XCTAssertEqual(response.data?.page?.hasNext, false)
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
        state.map.path[id: detailID, case: \.listingDetail]?.detail = makeListingDetailModel()

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
            $0.map.path[id: detailID, case: \.listingDetail]?.detail?.overview.isLiked = true
            $0.map.path[id: detailID, case: \.listingDetail]?.detail?.overview.favoriteCount = 7
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

    private func makeListingDetailModel() -> ListingDetailModel {
        ListingDetailModel(
            id: "listing-1",
            overview: ListingDetailOverviewModel(
                id: "listing-1",
                title: "Listing",
                typeTag: "Goshiwon",
                monthlyRentText: "₩500,000",
                convertedMonthlyRentText: "$360",
                depositText: "₩1,000,000",
                maintenanceFeeText: "₩50,000",
                transitText: "",
                imageCountText: "0/0",
                reviewCount: 0,
                isLiked: false,
                favoriteCount: 6
            ),
            tabs: [],
            roomOffers: [],
            priceInfo: [],
            propertyInfo: [],
            propertyFeatures: [],
            buildingInfo: [],
            facilityInfo: [],
            locationInfo: ListingLocationInfoModel(
                sectionTitle: "",
                addressText: "",
                transits: [],
                coordinate: nil,
                nearbyPlacesTitle: "",
                nearbyPlacesText: ""
            )
        )
    }
}

@MainActor
final class ListingDetailLoadFailureTests: XCTestCase {
    func testLoadFailureRequestsNoticePopup() async {
        var initialState = ListingDetailFeature.State(listingID: "listing-1")
        initialState.isDetailLoading = true
        let popup = AppPopup.notice(
            AppPopup.Notice(
                message: initialState.appLanguage.localized(.listingDetailErrorLoadFailed),
                confirmTitle: initialState.appLanguage.localized(.commonConfirm),
                confirmRoute: .dismissListingDetail
            )
        )
        let store = TestStore(initialState: initialState) {
            ListingDetailFeature()
        }

        await store.send(.detailResponse(.failure(.emptyResponse))) {
            $0.isDetailLoading = false
        }
        await store.receive(.popupRequested(popup))
    }

    func testNoticeConfirmationClosesMapListingDetail() async {
        var initialState = RootFeature.State(isAuthLoading: false)
        initialState.selectedTab = .map
        initialState.map.path.append(
            .listingDetail(ListingDetailFeature.State(listingID: "listing-1"))
        )
        initialState.popup = .notice(
            AppPopup.Notice(
                message: "load failed",
                confirmTitle: "confirm",
                confirmRoute: .dismissListingDetail
            )
        )
        let store = TestStore(initialState: initialState) {
            RootFeature()
        }

        await store.send(.popupNoticeConfirmButtonTapped) {
            $0.popup = nil
            _ = $0.map.path.popLast()
        }
    }
}

@MainActor
final class OnboardingRequestSafetyTests: XCTestCase {
    func testLandlordIgnoresVerificationResponseForPreviousPhoneNumber() async {
        var initialState = LandlordOnboardingFeature.State(appLanguage: .korean)
        initialState.phoneNumber = "01099998888"
        initialState.phoneVerificationCode = "654321"

        let store = TestStore(initialState: initialState) {
            LandlordOnboardingFeature()
        }

        await store.send(
            .confirmPhoneVerificationCodeResponse(
                requestedPhoneNumber: "01011112222",
                requestedCode: "123456",
                .success(
                    PhoneVerification(
                        phoneNumber: "01011112222",
                        verified: true
                    )
                )
            )
        )

        XCTAssertFalse(store.state.isPhoneVerified)
    }

    func testLandlordAppliesVerificationResponseForCurrentInput() async {
        var initialState = LandlordOnboardingFeature.State(appLanguage: .korean)
        initialState.phoneNumber = "01011112222"
        initialState.phoneVerificationCode = "123456"
        initialState.isPhoneVerificationRequesting = true

        let store = TestStore(initialState: initialState) {
            LandlordOnboardingFeature()
        }

        await store.send(
            .confirmPhoneVerificationCodeResponse(
                requestedPhoneNumber: "01011112222",
                requestedCode: "123456",
                .success(
                    PhoneVerification(
                        phoneNumber: "01011112222",
                        verified: true
                    )
                )
            )
        ) {
            $0.isPhoneVerificationRequesting = false
            $0.isPhoneVerified = true
        }
    }

    func testTenantDoesNotSubmitOnboardingWhileRequestIsInFlight() async {
        var initialState = TenantOnboardingFeature.State()
        initialState.currentStep = .details
        initialState.selectedMonth = DropdownMenuOption(option: "JAN")
        initialState.selectedDay = DropdownMenuOption(option: "1")
        initialState.selectedYear = DropdownMenuOption(option: "2000")
        initialState.selectedVisa = .studentsTrainees
        initialState.selectedNationality = DropdownMenuOption(option: "United States")
        initialState.selectedGender = .female
        initialState.isOnboardingSubmitting = true

        let store = TestStore(initialState: initialState) {
            TenantOnboardingFeature()
        }

        XCTAssertFalse(store.state.isNextButtonEnabled)
        await store.send(.onboardingCompleted)
    }

    func testLandlordDoesNotSubmitOnboardingWhileRequestIsInFlight() async {
        var initialState = LandlordOnboardingFeature.State(appLanguage: .korean)
        initialState.currentStep = .phoneVerification
        initialState.selectedMonth = DropdownMenuOption(option: "JAN")
        initialState.selectedDay = DropdownMenuOption(option: "1")
        initialState.selectedYear = DropdownMenuOption(option: "2000")
        initialState.phoneNumber = "01011112222"
        initialState.isPhoneVerified = true
        initialState.isOnboardingSubmitting = true

        let store = TestStore(initialState: initialState) {
            LandlordOnboardingFeature()
        }

        XCTAssertFalse(store.state.isNextButtonEnabled)
        await store.send(.onboardingCompleted)
    }
}

@MainActor
final class OnboardingErrorPopupTests: XCTestCase {
    func testOnboardingForwardsChildPopupAsDelegate() async {
        let popup = OnboardingErrorPopup.make(
            context: .completeProfile,
            language: .english
        )
        let store = TestStore(
            initialState: OnboardingFeature.State(
                userType: .tenant,
                appLanguage: .english
            )
        ) {
            OnboardingFeature()
        }

        await store.send(.tenant(.popupRequested(popup)))
        await store.receive(.delegate(.popupRequested(popup)))
    }

    func testTenantCompletionFailureRequestsLocalizedPopup() async {
        var initialState = TenantOnboardingFeature.State(appLanguage: .english)
        initialState.isOnboardingSubmitting = true
        let popup = OnboardingErrorPopup.make(
            context: .completeProfile,
            language: .english
        )
        let store = TestStore(initialState: initialState) {
            TenantOnboardingFeature()
        }

        await store.send(.onboardingResponse(.failure(.emptyResponse))) {
            $0.isOnboardingSubmitting = false
        }
        await store.receive(.popupRequested(popup))
    }

    func testLandlordPhoneSendFailureRequestsLocalizedPopup() async {
        var initialState = LandlordOnboardingFeature.State(appLanguage: .korean)
        initialState.phoneNumber = "01011112222"
        initialState.isPhoneVerificationCodeRequesting = true
        let popup = OnboardingErrorPopup.make(
            context: .sendPhoneVerificationCode,
            language: .korean
        )
        let store = TestStore(initialState: initialState) {
            LandlordOnboardingFeature()
        }

        await store.send(
            .sendPhoneVerificationCodeResponse(
                "01011112222",
                .failure(.transport(message: "offline"))
            )
        ) {
            $0.isPhoneVerificationCodeRequesting = false
        }
        await store.receive(.popupRequested(popup))
    }

    func testInvalidPhoneCodeKeepsInlineErrorWithoutPopup() async {
        var initialState = LandlordOnboardingFeature.State(appLanguage: .korean)
        initialState.phoneNumber = "01011112222"
        initialState.phoneVerificationCode = "123456"
        initialState.isPhoneVerificationRequesting = true
        let store = TestStore(initialState: initialState) {
            LandlordOnboardingFeature()
        }

        await store.send(
            .confirmPhoneVerificationCodeResponse(
                requestedPhoneNumber: "01011112222",
                requestedCode: "123456",
                .failure(
                    .serverError(
                        code: "AUTH_PHONE_VERIFICATION_FAILED",
                        message: "invalid code"
                    )
                )
            )
        ) {
            $0.isPhoneVerificationRequesting = false
            $0.phoneVerificationCodeErrorMessage = "인증 코드가 올바르지 않거나 만료됐어요. 다시 시도해주세요."
        }
    }

    func testOnboardingPopupRequestIsForwardedToRoot() async {
        let popup = OnboardingErrorPopup.make(
            context: .completeProfile,
            language: .english
        )
        let store = TestStore(
            initialState: RootFeature.State(
                appLanguage: .english,
                isAuthLoading: false
            )
        ) {
            RootFeature()
        }

        await store.send(.onboarding(.delegate(.popupRequested(popup)))) {
            $0.popup = popup
        }
    }

    func testAuthenticationSaveFailureRequestsLocalizedPopup() async {
        let popup = OnboardingErrorPopup.make(
            context: .saveAuthentication,
            language: .english
        )
        let store = TestStore(
            initialState: RootFeature.State(
                appLanguage: .english,
                isAuthLoading: false
            )
        ) {
            RootFeature()
        }

        await store.send(.saveAuthResponse(.failure(DataError.emptyResponse))) {
            $0.popup = popup
        }
    }
}

@MainActor
final class HomeEffectCancellationTests: XCTestCase {
    func testGuestFavoriteNavigationRequestsAuthenticationThroughDelegate() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }

        await store.send(.navigationHeartTapped)
        await store.receive(\.delegate.authenticationRequired)
    }

    func testCancelEffectsStopsInFlightRecentListingsRequest() async {
        let spy = HomeCancellationSpy()
        var initialState = HomeFeature.State(userType: .tenant)
        initialState.krwToUSDExchangeRate = KRWToUSDExchangeRate(usdPerKRW: 0.0007)
        initialState.isQuizLoaded = true
        initialState.isLivingGuidesLoaded = true
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.listingClient = ListingClient(
                fetchListings: { _ in fatalError("Unexpected fetchListings") },
                fetchDetail: { _ in fatalError("Unexpected fetchDetail") },
                fetchFavoriteListings: { _, _ in fatalError("Unexpected fetchFavoriteListings") },
                fetchRecentListings: { try await spy.fetchRecentListings() },
                addFavorite: { _ in fatalError("Unexpected addFavorite") },
                removeFavorite: { _ in fatalError("Unexpected removeFavorite") },
                createBooking: { _, _ in fatalError("Unexpected createBooking") }
            )
        }

        await store.send(.onAppear)
        await store.receive(\.recentlyViewed.onAppear) {
            $0.isRecentlyViewedLoading = true
            $0.recentlyViewedErrorMessage = nil
        }
        await store.receive(\.quiz.onAppear)
        await store.receive(\.livingGuide.onAppear)
        await fulfillment(of: [spy.started], timeout: 1)

        await store.send(.cancelEffects)
        await store.receive(\.recentlyViewed.cancelEffects)
        await store.receive(\.quiz.cancelEffects)
        await store.receive(\.livingGuide.cancelEffects)
        await fulfillment(of: [spy.cancelled], timeout: 1)
        await store.finish()
    }
}

private final class HomeCancellationSpy: @unchecked Sendable {
    let started = XCTestExpectation(description: "Home request started")
    let cancelled = XCTestExpectation(description: "Home request cancelled")

    func fetchRecentListings() async throws -> [Listing] {
        started.fulfill()

        return try await withTaskCancellationHandler {
            try await Task.sleep(nanoseconds: UInt64.max)
            return []
        } onCancel: {
            self.cancelled.fulfill()
        }
    }
}
