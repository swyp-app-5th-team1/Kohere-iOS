//
//  SearchView.swift
//  Kohere
//
//  Created by Codex on 7/7/26.
//

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    let store: StoreOf<SearchFeature>
    @Environment(\.locale)
    private var locale
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            searchBanner
                .padding(.top, 20)
            ScrollView(.vertical, showsIndicators: false) {
                searchContent
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .background(.coolNeutral5)
        .navigationBarHidden(true)
        .onAppear {
            isSearchFocused = true
        }
        .onDisappear {
            isSearchFocused = false
        }
        .interactivePopGestureEnabled()
    }

    private var searchHeader: some View {
        ZStack(alignment: .leading) {
            searchField
                .padding(.leading, 44)

            backButton
        }
        .padding(.leading, 10)
        .padding(.trailing, 20)
        .frame(height: 48)
    }

    private var backButton: some View {
        Button {
            store.send(.backButtonTapped)
        } label: {
            Image(.chevronLeft24)
                .renderingMode(.template)
                .foregroundStyle(.coolNeutral70)
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("search.accessibility.back"))
    }

    private var searchField: some View {
        HStack(spacing: 0) {
            TextField(
                "search.placeholder",
                text: Binding(
                    get: { store.searchText },
                    set: { text in
                        guard store.searchText != text else { return }
                        store.send(.searchTextChanged(text))
                    }
                )
            )
                .kohereTextStyle(.label1Medium)
                .foregroundStyle(.coolNeutral80)
                .tint(.blue100)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    store.send(.searchSubmitted)
                }

            Button {
                store.send(.clearButtonTapped)
                isSearchFocused = true
            } label: {
                Image(.closeThick16)
                    .renderingMode(.template)
                    .foregroundStyle(.labelAlternative)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("search.accessibility.clearInput"))
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .kohereSurface(
            background: .common0,
            shape: .roundedRectangle(cornerRadius: 16),
            elevation: .normalXSmall
        )
    }

    private var searchBanner: some View {
        Button {
            isSearchFocused = false
            store.send(.bannerTapped)
        } label: {
            ZStack(alignment: .trailing) {
                Image(.searchBannerBackground)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("common.roomFinderBanner.title")
                    .kohereTextStyle(.heading3Semibold)
                    .foregroundStyle(.neutral5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)

                Image(.searchBannerIcon)
                    .resizable()
                    .frame(width: 145.4, height: 80)
            }
            .frame(height: 80)
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("common.roomFinderBanner.accessibility"))
    }

    @ViewBuilder private var searchContent: some View {
        switch store.contentState {
        case .recentSearches:
            recentSearchSection
                .padding(.top, 20)
            Spacer(minLength: 0)

        case .typing, .searching:
            Spacer(minLength: 0)

        case .placeResults:
            placeResultList
            Spacer(minLength: 0)

        case .emptyResult:
            emptyResultView
                .padding(.top, 20)
            Spacer(minLength: 0)
        }
    }

    private var recentSearchSection: some View {
        VStack(spacing: 6) {
            recentSearchHeader
            recentSearchList
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var recentSearchHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("search.recent.title")
                .kohereTextStyle(.label3Semibold)
                .foregroundStyle(.labelNeutral)

            Spacer(minLength: 0)

            if !store.recentSearches.isEmpty {
                Button {
                    store.send(.clearRecentSearchesButtonTapped)
                } label: {
                    Text("search.recent.clearAll")
                        .kohereTextStyle(.body3Regular)
                        .foregroundStyle(.neutral50)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private var recentSearchList: some View {
        VStack(spacing: 4) {
            ForEach(store.recentSearches) { recentSearch in
                recentSearchRow(recentSearch)
                    .overlay(alignment: .bottom) {
                        if recentSearch.id != store.recentSearches.last?.id {
                            Divider()
                                .overlay(.lineAlternative)
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func recentSearchRow(_ recentSearch: SearchRecentSearch) -> some View {
        HStack(spacing: 0) {
            Button {
                store.send(.recentSearchTapped(recentSearch.keyword))
                isSearchFocused = false
            } label: {
                HStack(spacing: 8) {
                    Image(.searchRecentMarker16)
                        .frame(width: 16, height: 16)

                    Text(recentSearch.keyword)
                        .kohereTextStyle(.label2Medium)
                        .foregroundStyle(.labelNormal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                store.send(.recentSearchDeleteButtonTapped(recentSearch.keyword))
            } label: {
                Image(.close16)
                    .renderingMode(.template)
                    .foregroundStyle(.coolNeutral40)
                    .frame(width: 16, height: 16)
                    .frame(width: 44, height: 36, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    String(
                        format: String(localized: "search.recent.delete.accessibility", locale: locale),
                        recentSearch.keyword
                    )
                )
            )
        }
        .frame(height: 36)
    }

    private var placeResultList: some View {
        VStack(spacing: 4) {
            ForEach(store.placeResults) { placeResult in
                placeResultRow(placeResult)
                    .overlay(alignment: .bottom) {
                        if placeResult.id != store.placeResults.last?.id {
                            Divider()
                                .overlay(.lineNormal)
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func placeResultRow(_ placeResult: SearchPlaceResult) -> some View {
        Button {
            isSearchFocused = false
            store.send(.placeResultTapped(placeResult))
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(.location16)
                    .renderingMode(.template)
                    .foregroundStyle(.labelAlternative)
                    .frame(width: 16, height: 16)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(placeResult.title)
                        .kohereTextStyle(.label2Medium)
                        .foregroundStyle(.labelNormal)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(placeResult.displayAddress)
                        .kohereTextStyle(.body3Regular)
                        .foregroundStyle(.labelAlternative)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyResultView: some View {
        VStack(spacing: 8) {
            Image(.search24)
                .renderingMode(.template)
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(.labelAssistive)

            Text("search.empty.noResults")
                .kohereTextStyle(.label2Medium)
                .foregroundStyle(.labelAlternative)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.horizontal, 20)
    }
}
