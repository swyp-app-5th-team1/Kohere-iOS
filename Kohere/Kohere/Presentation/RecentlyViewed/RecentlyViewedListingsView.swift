//
//  RecentlyViewedListingsView.swift
//  Kohere
//
//  Created by soomin on 6/24/26.
//

import ComposableArchitecture
import SwiftUI

struct RecentlyViewedListingsView: View {
    
    // MARK: - Property
    
    let store: StoreOf<RecentlyViewedFeature>
    @Environment(\.locale)
    private var locale
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton({ store.send(.backButtonTapped) }),
                center: .text(AppLanguage(locale: locale).localized(.recentListingsTitle)),
                right: .none
            )
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)
            
            if store.items.isEmpty {
                KohereEmptyView(
                    title: AppLanguage(locale: locale).localized(.recentListingsEmptyTitle)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.items) { item in
                            ListingCardView(
                                item: item,
                                showsLikeButton: store.canUseFavoriteFeatures,
                                onCardTapped: { store.send(.cardTapped(id: item.id)) },
                                onLikeTapped: { store.send(.likeButtonTapped(id: item.id)) }
                            )
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(.backgroundNormalNormal)
        .onAppear {
            store.send(.onAppear)
        }
        .interactivePopGestureEnabled()
    }
}
