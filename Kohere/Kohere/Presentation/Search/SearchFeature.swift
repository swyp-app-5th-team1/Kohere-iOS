//
//  SearchFeature.swift
//  Kohere
//
//  Created by Codex on 7/7/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SearchFeature {
    private static let recentSearchLimit = 10

    @ObservableState
    struct State: Equatable {
        var searchText = ""
        var contentState: SearchContentState = .recentSearches
        var recentSearches: [SearchRecentSearch] = []
        var placeResults: [SearchPlaceResult] = []
        var searchErrorMessage: String?
    }

    enum Action {
        case backButtonTapped
        case searchTextChanged(String)
        case clearButtonTapped
        case searchSubmitted
        case recentSearchTapped(String)
        case recentSearchDeleteButtonTapped(String)
        case clearRecentSearchesButtonTapped
        case placeResultTapped(SearchPlaceResult)
        case placeSearchSucceeded(requestedKeyword: String, results: [SearchPlaceResult])
        case placeSearchFailed(requestedKeyword: String, message: String)
        case searchErrorDismissed
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none

            case let .searchTextChanged(text):
                state.searchText = text
                state.placeResults = []
                state.searchErrorMessage = nil
                state.contentState = text.isEmpty ? .recentSearches : .typing
                return .none

            case .clearButtonTapped:
                state.searchText = ""
                state.placeResults = []
                state.searchErrorMessage = nil
                state.contentState = .recentSearches
                return .none

            case .searchSubmitted:
                let keyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !keyword.isEmpty else { return .none }
                state.searchErrorMessage = nil
                state.contentState = .searching
                return .send(.placeSearchSucceeded(
                    requestedKeyword: keyword,
                    results: SearchPlaceResult.mockResults(for: keyword)
                ))

            case let .recentSearchTapped(keyword):
                state.searchText = keyword
                state.placeResults = []
                state.searchErrorMessage = nil
                state.contentState = .typing
                return .none

            case let .recentSearchDeleteButtonTapped(keyword):
                state.recentSearches.removeAll { $0.keyword == keyword }
                return .none

            case .clearRecentSearchesButtonTapped:
                state.recentSearches.removeAll()
                return .none

            case .placeResultTapped:
                return .none

            case let .placeSearchSucceeded(requestedKeyword, results):
                guard state.searchText.trimmingCharacters(in: .whitespacesAndNewlines) == requestedKeyword else {
                    return .none
                }
                state.addRecentSearch(requestedKeyword)
                state.placeResults = results
                state.searchErrorMessage = nil
                state.contentState = results.isEmpty ? .emptyResult : .placeResults
                return .none

            case let .placeSearchFailed(requestedKeyword, message):
                guard state.searchText.trimmingCharacters(in: .whitespacesAndNewlines) == requestedKeyword else {
                    return .none
                }
                state.placeResults = []
                state.searchErrorMessage = message
                state.contentState = .typing
                return .none

            case .searchErrorDismissed:
                state.searchErrorMessage = nil
                return .none
            }
        }
    }
}

extension SearchFeature.State {
    mutating func addRecentSearch(_ keyword: String) {
        recentSearches.removeAll { $0.keyword == keyword }
        recentSearches.insert(SearchRecentSearch(keyword: keyword), at: 0)
        recentSearches = Array(recentSearches.prefix(SearchFeature.recentSearchLimit))
    }
}

enum SearchContentState: Equatable {
    case recentSearches
    case typing
    case searching
    case placeResults
    case emptyResult
}

struct SearchRecentSearch: Equatable, Identifiable {
    let keyword: String

    var id: String {
        keyword
    }
}

struct SearchPlaceResult: Equatable, Identifiable {
    let id: String
    let title: String
    let roadAddress: String
    let address: String
    let coordinate: MapCoordinate

    var displayAddress: String {
        roadAddress.isEmpty ? address : roadAddress
    }
}

extension SearchPlaceResult {
    static func mockResults(for keyword: String) -> [Self] {
        let normalizedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedKeyword.isEmpty else { return [] }

        return mockPlaces.filter { place in
            place.searchableText.contains(normalizedKeyword)
        }
    }

    private static let mockPlaces: [Self] = [
        Self(
            id: "hongdae-station-line-2",
            title: "홍대입구역 2호선",
            roadAddress: "서울 마포구 양화로 160",
            address: "서울 마포구 동교동 165",
            coordinate: MapCoordinate(latitude: 37.5572, longitude: 126.9254)
        ),
        Self(
            id: "yonsei-university",
            title: "연세대학교",
            roadAddress: "서울 서대문구 연세로 50",
            address: "서울 서대문구 신촌동 134",
            coordinate: MapCoordinate(latitude: 37.5658, longitude: 126.9386)
        ),
        Self(
            id: "korea-university",
            title: "고려대학교",
            roadAddress: "서울 성북구 안암로 145",
            address: "서울 성북구 안암동5가 1-2",
            coordinate: MapCoordinate(latitude: 37.5894, longitude: 127.0323)
        ),
        Self(
            id: "sinchon-station",
            title: "신촌역",
            roadAddress: "서울 서대문구 신촌로 90",
            address: "서울 서대문구 창천동 30-16",
            coordinate: MapCoordinate(latitude: 37.5552, longitude: 126.9369)
        )
    ]

    private var searchableText: String {
        "\(title) \(roadAddress) \(address)".lowercased()
    }
}
