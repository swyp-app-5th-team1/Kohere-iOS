//
//  SavedListingsView.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import ComposableArchitecture
import SwiftUI

struct SavedListingsView: View {
    
    // MARK: - Property
    
    let store: StoreOf<SavedListingsFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(left: .backButton({ store.send(.backButtonTapped) }), center: .text("Saved listings"), right: .none)
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)

            if store.isLoading && store.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = store.errorMessage, store.items.isEmpty {
                KohereEmptyView(title: errorMessage)
            } else if store.items.isEmpty {
                KohereEmptyView(title: "No saved listings yet")
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
        .onAppear {
            store.send(.onAppear)
        }
    }
}
