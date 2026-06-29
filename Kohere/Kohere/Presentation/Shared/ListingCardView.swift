//
//  ListingCardView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import SwiftUI

struct ListingCardView: View {
    
    // MARK: - Properties
    
    let item: ListingItemModel
    let showsLikeButton: Bool
    
    var onCardTapped: () -> Void
    var onLikeTapped: () -> Void

    init(
        item: ListingItemModel,
        showsLikeButton: Bool = true,
        onCardTapped: @escaping () -> Void,
        onLikeTapped: @escaping () -> Void
    ) {
        self.item = item
        self.showsLikeButton = showsLikeButton
        self.onCardTapped = onCardTapped
        self.onLikeTapped = onLikeTapped
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(.roomPlaceholder)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 156, height: 120)
                .cornerRadius(16)
                .clipped()
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(item.formattedPrice)
                            .kohereTextStyle(.label1Semibold)
                            .foregroundColor(.neutral80)
                        
                        Text(item.formattedUsdPrice)
                            .kohereTextStyle(.body2Regular)
                            .foregroundColor(.labelNormal)
                    }
                    
                    Spacer()
                    
                    if showsLikeButton {
                        Button {
                            onLikeTapped()
                        } label: {
                            Image(item.isLiked ? .heartFill24 : .heart24)
                                .renderingMode(.template)
                                .foregroundColor(item.isLiked ? .primary50 : .labelAlternative)
                        }
                    }
                }
                
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
                .padding(.top, 4)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .onTapGesture {
            onCardTapped()
        }
    }
}
