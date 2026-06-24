//
//  HomeView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    
    // MARK: - Property
    
    let store: StoreOf<HomeFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .bigLogo, center: .none,
                right: .homeTab(
                    onSearch: { store.send(.navigationSearchTapped) },
                    onHeart: { store.send(.navigationHeartTapped) },
                    onNotice: { store.send(.navigationNoticeTapped) }
                )
            )
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RoomFinderBannerView(store: store)
                    
                    RecentlyViewedView(
                        items: store.recentlyViewedItems,
                        onSeeAllTapped: { store.send(.seeAllListingsTapped) },
                        onBrowseTapped: { store.send(.browseListingsTapped) },
                        onCardTapped: { id in store.send(.cardTapped(id: id)) },
                        onLikeTapped: { id in store.send(.likeButtonTapped(id: id)) }
                    )
                    
                    homeDivider
                }
            }
        }
    }
    
    // MARK: - Subview
    
    private var homeDivider: some View {
        Rectangle()
            .foregroundStyle(.fillNormal)
            .frame(height: 16)
    }
}
