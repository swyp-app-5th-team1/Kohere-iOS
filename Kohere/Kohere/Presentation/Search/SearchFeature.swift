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
    @Dependency(\.placeSearchClient)
    var placeSearchClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient

    @ObservableState
    struct State: Equatable {
        var searchText = ""
        var contentState: SearchContentState = .recentSearches
        var recentSearches: [SearchRecentSearch] = []
        var placeResults: [SearchPlaceResult] = []
    }

    enum Action {
        case backButtonTapped
        case searchTextChanged(String)
        case clearButtonTapped
        case searchSubmitted
        case recentSearchTapped(String)
        case recentSearchDeleteButtonTapped(String)
        case clearRecentSearchesButtonTapped
        case bannerTapped
        case placeResultTapped(SearchPlaceResult)
        case placeSearchSucceeded(requestedKeyword: String, results: [SearchPlaceResult])
        case placeSearchFailed(requestedKeyword: String, message: String)
        case popupRequested(AppPopup)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none

            case let .searchTextChanged(text):
                state.searchText = text
                state.placeResults = []
                state.contentState = text.isEmpty ? .recentSearches : .typing
                return .cancel(id: SearchFeatureCancelID.placeSearch)

            case .clearButtonTapped:
                state.searchText = ""
                state.placeResults = []
                state.contentState = .recentSearches
                return .cancel(id: SearchFeatureCancelID.placeSearch)

            case .searchSubmitted:
                let keyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !keyword.isEmpty else { return .none }
                let placeSearchClient = placeSearchClient
                state.placeResults = []
                state.contentState = .searching
                return .run { send in
                    do {
                        let results = try await placeSearchClient.searchPlaces(keyword)
                        await send(.placeSearchSucceeded(
                            requestedKeyword: keyword,
                            results: results.map(SearchPlaceResult.init)
                        ))
                    } catch {
                        guard !Task.isCancelled else { return }
                        await send(.placeSearchFailed(
                            requestedKeyword: keyword,
                            message: placeSearchFailureMessage(for: error)
                        ))
                    }
                }
                .cancellable(id: SearchFeatureCancelID.placeSearch, cancelInFlight: true)

            case let .recentSearchTapped(keyword):
                let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !keyword.isEmpty else { return .none }
                state.searchText = keyword
                return .send(.searchSubmitted)

            case let .recentSearchDeleteButtonTapped(keyword):
                state.recentSearches.removeAll { $0.keyword == keyword }
                saveRecentSearches(state.recentSearches, userDefaultsClient: userDefaultsClient)
                return .none

            case .clearRecentSearchesButtonTapped:
                state.recentSearches.removeAll()
                saveRecentSearches(state.recentSearches, userDefaultsClient: userDefaultsClient)
                return .none

            case .bannerTapped:
                return .none

            case .placeResultTapped:
                return .none

            case let .placeSearchSucceeded(requestedKeyword, results):
                guard state.searchText.trimmingCharacters(in: .whitespacesAndNewlines) == requestedKeyword else {
                    return .none
                }
                state.addRecentSearch(requestedKeyword)
                saveRecentSearches(state.recentSearches, userDefaultsClient: userDefaultsClient)
                state.placeResults = results
                state.contentState = results.isEmpty ? .emptyResult : .placeResults
                return .none

            case let .placeSearchFailed(requestedKeyword, message):
                guard state.searchText.trimmingCharacters(in: .whitespacesAndNewlines) == requestedKeyword else {
                    return .none
                }
                state.placeResults = []
                state.contentState = .typing
                return .send(.popupRequested(placeSearchFailurePopup(message: message)))

            case .popupRequested:
                return .none
            }
        }
    }
}

extension SearchFeature {
    static func initialState(userDefaultsClient: UserDefaultsClient) -> State {
        State(recentSearches: loadRecentSearches(userDefaultsClient: userDefaultsClient))
    }
}

extension SearchFeature.State {
    mutating func addRecentSearch(_ keyword: String) {
        recentSearches.removeAll { $0.keyword == keyword }
        recentSearches.insert(SearchRecentSearch(keyword: keyword), at: 0)
        recentSearches = Array(recentSearches.prefix(SearchFeature.recentSearchLimit))
    }
}

private extension SearchFeature {
    static func loadRecentSearches(userDefaultsClient: UserDefaultsClient) -> [SearchRecentSearch] {
        let keywords = (try? userDefaultsClient.load(for: .recentSearchKeywords)) ?? []
        return Array(
            keywords
                .filter { !$0.isEmpty }
                .uniqued()
                .prefix(recentSearchLimit)
        )
        .map(SearchRecentSearch.init)
    }

    func saveRecentSearches(
        _ recentSearches: [SearchRecentSearch],
        userDefaultsClient: UserDefaultsClient
    ) {
        try? userDefaultsClient.save(
            recentSearches.map(\.keyword),
            for: .recentSearchKeywords
        )
    }

    func placeSearchFailurePopup(message: String) -> AppPopup {
        let fallbackMessage = "장소 검색에 실패했어요.\n다시 시도해주세요."
        let resolvedMessage = message.isEmpty ? fallbackMessage : message
        return .notice(AppPopup.Notice(message: resolvedMessage))
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

private nonisolated enum SearchFeatureCancelID: Hashable, Sendable {
    case placeSearch
}

nonisolated enum SearchContentState: Equatable {
    case recentSearches
    case typing
    case searching
    case placeResults
    case emptyResult
}

nonisolated struct SearchRecentSearch: Equatable, Identifiable, Sendable {
    let keyword: String

    var id: String {
        keyword
    }
}

nonisolated struct SearchPlaceResult: Equatable, Identifiable, Sendable {
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
    nonisolated init(_ placeSearchResult: PlaceSearchResult) {
        self.init(
            id: placeSearchResult.id,
            title: placeSearchResult.title,
            roadAddress: placeSearchResult.roadAddress,
            address: placeSearchResult.address,
            coordinate: placeSearchResult.coordinate
        )
    }
}

private func placeSearchFailureMessage(for error: Error) -> String {
    let dataError = (error as? DataError) ?? .underlying(message: error.localizedDescription)
    switch dataError {
    case .missingNaverSearchCredentials:
        return "장소 검색 설정이 필요해요.\n네이버 검색 API 키를 확인해주세요."

    case let .httpStatus(code, _) where code == 403:
        return "장소 검색 권한을 확인해주세요.\n네이버 개발자센터의 검색 API 설정이 필요해요."

    case let .serverError(code, _):
        switch code {
        case "SE01", "SE06":
            return "검색어를 확인해주세요.\n다시 입력해 주세요."

        case "SE99":
            return "네이버 장소 검색이 잠시 불안정해요.\n조금 뒤 다시 시도해주세요."

        default:
            return "장소 검색에 실패했어요.\n다시 시도해주세요."
        }

    default:
        return "장소 검색에 실패했어요.\n다시 시도해주세요."
    }
}
