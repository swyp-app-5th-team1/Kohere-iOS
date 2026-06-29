//
//  ChatDetailView.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatDetailView: View {
    
    // MARK: - Property
    
    let store: StoreOf<ChatDetailFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    store.send(.backButtonTapped)
                } label: {
                    Image(.chevronLeft24)
                        .renderingMode(.template)
                        .foregroundColor(.neutral70)
                }
                .padding(.leading, 24)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(store.chatRoom.listingName)
                        .kohereTextStyle(.label1Medium)
                        .foregroundStyle(.neutral70)
                    
                    Text(store.chatRoom.location)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundColor(.neutral30)
                }
                Spacer()
                
                // TODO:  신고하기, 삭제하기 추가 예정
                Color.clear
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    Text("6/12/2026 Tue")
                        .kohereTextStyle(.caption1Regular)
                        .foregroundColor(.neutral40)
                     
                    HStack(alignment: .bottom, spacing: 8) {
                        Spacer()
                        
                        Text("23:03")
                            .kohereTextStyle(.caption2Regular)
                            .foregroundStyle(.neutral20)
                        
                        MoveInApplicationCardView(item: store.chatRoom) {
                            store.send(.viewDetailsButtonTapped)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
