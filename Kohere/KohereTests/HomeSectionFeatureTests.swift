//
//  HomeSectionFeatureTests.swift
//  KohereTests
//

import ComposableArchitecture
import XCTest
@testable import Kohere

@MainActor
final class HomeQuizFeatureTests: XCTestCase {
    func testOnAppearLoadsRandomQuiz() async {
        let quiz = makeQuiz(id: 2)
        let store = TestStore(initialState: HomeQuizFeature.State()) {
            HomeQuizFeature()
        } withDependencies: {
            $0.fetchRandomQuizUseCase = FetchRandomQuizUseCase { quiz }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.randomQuizResponse) {
            $0.quiz = quiz
            $0.selectedChoiceKey = nil
            $0.answerResult = nil
            $0.isLoading = false
            $0.isLoaded = true
            $0.errorMessage = nil
        }
    }

    func testOptionTapSubmitsAndAppliesAnswer() async {
        let result = QuizAnswerResult(
            quizID: 1,
            selectedChoiceKey: "A",
            isCorrect: false,
            correctChoiceKey: "B",
            explanation: "정답은 B입니다."
        )
        var initialState = HomeQuizFeature.State(quiz: makeQuiz(id: 1))
        initialState.isLoaded = true
        let store = TestStore(initialState: initialState) {
            HomeQuizFeature()
        } withDependencies: {
            $0.submitQuizAnswerUseCase = SubmitQuizAnswerUseCase { quizID, selectedChoiceKey in
                XCTAssertEqual(quizID, 1)
                XCTAssertEqual(selectedChoiceKey, "A")
                return result
            }
        }

        await store.send(.optionTapped(index: 0)) {
            $0.selectedChoiceKey = "A"
            $0.isAnswerSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(\.answerResponse) {
            $0.selectedChoiceKey = "A"
            $0.answerResult = result
            $0.isAnswerSubmitting = false
            $0.errorMessage = nil
        }
    }

    private func makeQuiz(id: Int) -> Quiz {
        Quiz(
            id: id,
            question: "질문",
            choices: [
                QuizChoice(key: "A", text: "선택 A"),
                QuizChoice(key: "B", text: "선택 B")
            ],
            correctChoiceKey: nil,
            explanation: nil
        )
    }
}

@MainActor
final class HomeLivingGuideFeatureTests: XCTestCase {
    func testOnAppearLoadsLivingGuides() async {
        let guide = makeLivingGuide()
        let store = TestStore(initialState: HomeLivingGuideFeature.State()) {
            HomeLivingGuideFeature()
        } withDependencies: {
            $0.fetchLivingGuideTopicsUseCase = FetchLivingGuideTopicsUseCase { [guide] }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.topicsResponse) {
            $0.guides = [guide]
            $0.isLoading = false
            $0.isLoaded = true
            $0.errorMessage = nil
        }
    }

    func testLoadFailureExposesErrorAndAllowsRetry() async {
        let store = TestStore(initialState: HomeLivingGuideFeature.State()) {
            HomeLivingGuideFeature()
        } withDependencies: {
            $0.fetchLivingGuideTopicsUseCase = FetchLivingGuideTopicsUseCase {
                throw DataError.emptyResponse
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.topicsResponse) {
            $0.isLoading = false
            $0.isLoaded = false
            $0.errorMessage = DataError.emptyResponse.localizedDescription
        }
    }

    private func makeLivingGuide() -> LivingGuide {
        LivingGuide(
            id: 1,
            code: "BANK",
            name: "Banking",
            shortDescription: "Short",
            longDescription: "Long",
            iconName: "bankAccountGuide",
            theme: .bankAccount
        )
    }
}

@MainActor
final class HomeRecentlyViewedFeatureTests: XCTestCase {
    func testOnAppearLoadsRecentListings() async {
        let listing = makeListing()
        let exchangeRate = KRWToUSDExchangeRate(usdPerKRW: 0.0007)
        let convertCurrency = ConvertMonthlyRentCurrencyUseCase { monthlyRent, _ in
            Decimal(monthlyRent) * Decimal(7) / Decimal(10_000)
        }
        var initialState = HomeRecentlyViewedFeature.State(userType: .tenant)
        initialState.exchangeRate = exchangeRate
        let store = TestStore(initialState: initialState) {
            HomeRecentlyViewedFeature()
        } withDependencies: {
            $0.fetchRecentListingsUseCase = FetchRecentListingsUseCase { [listing] }
            $0.convertMonthlyRentCurrencyUseCase = convertCurrency
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.recentListingsResponse) {
            $0.recentListings = [listing]
            $0.items = [
                ListingItemModel(
                    listing: listing,
                    exchangeRate: exchangeRate,
                    convertMonthlyRentCurrencyUseCase: convertCurrency,
                    language: .english
                )
            ]
            $0.isLoading = false
            $0.isLoaded = true
            $0.errorMessage = nil
        }
    }

    func testLikeTapIsIgnoredWhileSameListingIsUpdating() async {
        let item = ListingItemModel(
            id: "listing-1",
            formattedPrice: "",
            formattedUsdPrice: "",
            detailsDescription: "",
            locationDescription: "",
            typeTag: "",
            period: "",
            isLiked: false
        )
        var initialState = HomeRecentlyViewedFeature.State(userType: .tenant, items: [item])
        initialState.favoriteUpdatingIDs = [item.id]
        let store = TestStore(initialState: initialState) {
            HomeRecentlyViewedFeature()
        } withDependencies: {
            $0.updateListingFavoriteUseCase = UpdateListingFavoriteUseCase { _, _ in
                XCTFail("이미 처리 중인 매물에 좋아요 요청이 다시 실행되면 안 됩니다.")
                return ListingFavoriteStatus(isFavorited: true, favoriteCount: 1)
            }
        }

        await store.send(.likeButtonTapped(id: item.id))
    }

    private func makeListing() -> Listing {
        Listing(
            listingID: "listing-1",
            title: "Listing",
            type: "ONE_ROOM",
            minMonthlyRent: 500_000,
            maxMonthlyRent: 500_000,
            minDeposit: 10_000_000,
            maxDeposit: 10_000_000,
            minMaintenanceFee: 50_000,
            maxMaintenanceFee: 50_000,
            minStayMonths: 12,
            maxStayMonths: 12,
            thumbnailURL: nil,
            coordinate: nil,
            address: "Seoul",
            nearestTransit: nil,
            distanceMeters: nil,
            isFavorited: false,
            favoriteCount: 0
        )
    }
}
