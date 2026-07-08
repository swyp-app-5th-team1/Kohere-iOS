//
//  HomeListingCardView.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import SwiftUI

struct HomeListingCardView: View {
    
    // MARK: - Properties
    
    let item: ListingItemModel
    let showsLikeButton: Bool
    
    let onCardTapped: (String) -> Void
    let onLikeTapped: (String) -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(.roomPlaceholder)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 156, height: 120)
                    .cornerRadius(16)
                
                if showsLikeButton {
                    Button {
                        onLikeTapped(item.id)
                    } label: {
                        Image(item.isLiked ? .heartFill24 : .heart24)
                            .renderingMode(.template)
                            .foregroundColor(item.isLiked ? .primary50 : .white)
                            .padding(8)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.formattedPrice)
                    .kohereTextStyle(.label1Semibold)
                    .foregroundColor(.neutral80)
                
                Text(item.formattedUsdPrice)
                    .kohereTextStyle(.body2Regular)
                    .foregroundColor(.labelNormal)
                    .padding(.top, 4)
                
                Text(item.detailsDescription)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.labelAlternative)
                    .padding(.top, 8)
                
                Text(item.locationDescription)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.labelAlternative)
                    .padding(.top, 2)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(item.typeTag)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundColor(.labelNormal)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.fillAlternative)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.lineAlternative, lineWidth: 1)
                        )
                    
                    Text(item.period)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundColor(.labelAlternative)
                }
                .padding(.top, 5)
            }
            .padding(.top, 16)
            .padding(.leading, 8)
        }
        .frame(width: 156)
        .contentShape(Rectangle())
        .onTapGesture { onCardTapped(item.id) }
    }
}
