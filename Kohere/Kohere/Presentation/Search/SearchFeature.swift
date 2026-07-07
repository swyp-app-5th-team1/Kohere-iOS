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
    }

    enum Action {
        case backButtonTapped
        case searchTextChanged(String)
        case clearButtonTapped
        case searchSubmitted
        case recentSearchTapped(String)
        case recentSearchDeleteButtonTapped(String)
        case clearRecentSearchesButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none

            case let .searchTextChanged(text):
                state.searchText = text
                state.contentState = text.isEmpty ? .recentSearches : .typing
                return .none

            case .clearButtonTapped:
                state.searchText = ""
                state.contentState = .recentSearches
                return .none

            case .searchSubmitted:
                let keyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !keyword.isEmpty else { return .none }
                state.addRecentSearch(keyword)
                state.contentState = .emptyResult
                return .none

            case let .recentSearchTapped(keyword):
                state.searchText = keyword
                state.contentState = .typing
                return .none

            case let .recentSearchDeleteButtonTapped(keyword):
                state.recentSearches.removeAll { $0.keyword == keyword }
                return .none

            case .clearRecentSearchesButtonTapped:
                state.recentSearches.removeAll()
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
