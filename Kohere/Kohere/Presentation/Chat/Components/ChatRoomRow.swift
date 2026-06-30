//
//  ChatRoomRow.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import SwiftUI

struct ChatRoomRowCell: View {
    
    // MARK: - Properties
    
    let item: ChatRoomModel
    let onTap: (Int) -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(.profilePlaceholder)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Text(item.listingName)
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.neutral60)
                    
                    Spacer()
                    
                    Text(item.timeText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundColor(.neutral20)
                }
                
                Text(item.statusText)
                    .kohereTextStyle(.body2Regular)
                    .foregroundColor(.neutral40)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .onTapGesture {
            onTap(item.id)
        }
    }
}
