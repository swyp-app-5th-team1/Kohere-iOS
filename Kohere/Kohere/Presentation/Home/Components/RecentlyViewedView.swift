//
//  RecentlyViewedView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import SwiftUI

struct RecentlyViewedView: View {
    
    // MARK: - Properties
    
    let items: [ListingItemModel]
    let showsLikeButtons: Bool
    
    let onSeeAllTapped: () -> Void
    let onBrowseTapped: () -> Void
    let onCardTapped: (String) -> Void
    let onLikeTapped: (String) -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("home.recentListings.title")
                    .kohereTextStyle(.heading3Semibold)
                    .foregroundColor(.neutral90)
                
                Spacer()
                
                Button(action: onSeeAllTapped) {
                    Text("common.seeAll")
                        .kohereTextStyle(.body3Regular)
                        .foregroundColor(.labelNeutral)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
            
            if items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .background(.backgroundNormalNormal)
    }
    
    // MARK: - Subviews
    
    private var emptyView: some View {
        VStack(spacing: 0) {
            Image(.homeEmpty)
                .resizable()
                .frame(width: 152, height: 152)
            
            Text("home.recentListings.empty.message")
                .kohereTextStyle(.caption1Regular)
                .foregroundColor(.labelAlternative)
                .multilineTextAlignment(.center)
            
            Button(action: onBrowseTapped) {
                Text("common.browseListings")
                    .kohereTextStyle(.label3Semibold)
                    .foregroundColor(.common0)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.coolNeutral90)
                    .cornerRadius(8)
            }
            .padding(.top, 16)
            Spacer(minLength: 62)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var listView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items) { item in
                    HomeListingCardView(
                        item: item,
                        showsLikeButton: showsLikeButtons,
                        onCardTapped: onCardTapped,
                        onLikeTapped: onLikeTapped
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
    }
}
