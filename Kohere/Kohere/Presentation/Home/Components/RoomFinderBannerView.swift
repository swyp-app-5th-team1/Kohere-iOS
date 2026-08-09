//
//  RoomFinderBannerView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import ComposableArchitecture
import SwiftUI

struct RoomFinderBannerView: View {
    
    // MARK: - Property
    
    let store: StoreOf<HomeFeature>
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Image(.homeMain)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        Button {
                            store.send(.roomFinderBannerTapped)
                        } label: {
                            Text(.homeRoomFinderButton)
                                .kohereTextStyle(.label1Semibold)
                                .foregroundColor(.primaryNormal)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                            .frame(
                                width: geometry.size.width * (335 / 375),
                                height: geometry.size.height * (48 / 257)
                            )
                            .position(
                                x: geometry.size.width * 0.5,
                                y: geometry.size.height * ((257 - 24 - 24) / 257)
                            )
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(.commonRoomFinderBannerTitle)
                        .kohereTextStyle(.heading2Bold)
                        .foregroundColor(.staticBlack)
                        .padding(.top, 20)
                    
                    Text(.homeRoomFinderSubtitle)
                        .kohereTextStyle(.body1Regular)
                        .foregroundColor(.labelNeutral)
                        .padding(.top, 16)
                    
                    Spacer()
                }
                .padding(.horizontal, 28)
            }
        }
        .aspectRatio(375 / 257, contentMode: .fit)
    }
}
