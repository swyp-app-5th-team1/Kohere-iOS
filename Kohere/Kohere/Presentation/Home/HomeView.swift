//
//  HomeView.swift
//  Kohere
//
//  Created by soomin on 6/18/26.
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
                    showsHeart: store.showsFavoriteControls,
                    onSearch: { store.send(.navigationSearchTapped) },
                    onHeart: { store.send(.navigationHeartTapped) },
                    onNotice: { store.send(.navigationNoticeTapped) }
                )
            )
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    RoomFinderBannerView(store: store)
                    
                    HomeRecentlyViewedView(
                        store: store.scope(state: \.recentlyViewedSection, action: \.recentlyViewedSection),
                        showsLikeButtons: store.showsFavoriteControls,
                        onSeeAllTapped: { store.send(.seeAllListingsTapped) },
                        onBrowseTapped: { store.send(.browseListingsTapped) },
                        onCardTapped: { id in store.send(.cardTapped(id: id)) }
                    )
                    
                    homeDivider
                    
                    HomeQuizView(store: store.scope(state: \.quizSection, action: \.quizSection))

                    homeDivider

                    HomeLivingGuideView(
                        store: store.scope(state: \.livingGuideSection, action: \.livingGuideSection)
                    )
                }
                .background(.backgroundNormalNormal)
            }
            .background(.backgroundNormalNormal)
        }
        .background(.backgroundNormalNormal)
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Subview
    
    private var homeDivider: some View {
        Rectangle()
            .foregroundStyle(.fillNormal)
            .frame(height: 16)
    }
}
