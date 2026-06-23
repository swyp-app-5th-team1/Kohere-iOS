//
//  RecentlyViewedListngsView.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import ComposableArchitecture
import SwiftUI

struct RecentlyViewedListngsView: View {
    
    // MARK: - Property
    
    let store: StoreOf<RecentlyViewedFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(left: .backButton({ store.send(.backButtonTapped) }), center: .text("Recently Viewed"), right: .none)
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)
            
            if store.items.isEmpty {
                KohereEmptyView(title: "No viewed listings yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.items) { item in
                            ListingCardView(
                                item: item,
                                onCardTapped: { store.send(.cardTapped(id: item.id)) },
                                onLikeTapped: { store.send(.likeButtonTapped(id: item.id)) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}
