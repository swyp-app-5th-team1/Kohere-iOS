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
    let participantRole: ChatParticipantRole
    let onTap: (Int) -> Void
    
    private var statusText: String {
        switch participantRole {
        case .tenant:
            return "신청서가 전송되었어요!"
        case .landlord:
            return "새로운 입주 신청이 도착했어요!"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(.personFill24)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fill)
                .foregroundStyle(.secondary5)
                .frame(width: 24, height: 24)
                .frame(width: 36, height: 36)
                .background(.primary10)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Text(item.listingName)
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.labelNormal)
                    
                    Spacer()
                    
                    Text(item.timeText)
                        .kohereTextStyle(.caption2Regular)
                        .foregroundColor(.neutral20)
                }
                
                Text(statusText)
                    .kohereTextStyle(.body3Regular)
                    .foregroundColor(.neutral40)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .onTapGesture {
            onTap(item.id)
        }
    }
}
