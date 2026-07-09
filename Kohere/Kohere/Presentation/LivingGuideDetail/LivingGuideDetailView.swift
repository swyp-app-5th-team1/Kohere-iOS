//
//  LivingGuideDetailView.swift
//  Kohere
//
//  Created by mandoo on 7/7/26.
//

import ComposableArchitecture
import SwiftUI

struct LivingGuideDetailView: View {
    
    // MARK: - Property
    
    let store: StoreOf<LivingGuideDetailFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {
                    ForEach(store.guide.tips) { tip in
                        LivingGuideTipCard(tip: tip)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(.staticWhite)
        }
        .background(.staticWhite)
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Subview
    
    private var header: some View {
        ZStack(alignment: .topLeading) {
            Image(store.guide.theme.bannerImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
            
            VStack(alignment: .leading, spacing: 20) {
                Button {
                    store.send(.backButtonTapped)
                } label: {
                    Image(.chevronLeft24)
                        .renderingMode(.template)
                        .foregroundStyle(.neutral70)
                        .frame(width: 24, height: 24)
                }
                .padding(.top, 12)
                .padding(.leading, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.guide.title)
                        .kohereTextStyle(.display2Bold)
                        .foregroundStyle(.staticWhite)
                    
                    Text(store.guide.subtitle)
                        .kohereTextStyle(.body1Regular)
                        .foregroundStyle(.staticWhite)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 210)
    }
}

private struct LivingGuideTipCard: View {
    
    // MARK: - Property
    
    let tip: LivingGuideTip
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            tipImage
            
            VStack(spacing: 4) {
                Text(tip.title)
                    .kohereTextStyle(.heading3Semibold)
                    .foregroundStyle(.labelNormal)
                    .multilineTextAlignment(.center)
                
                Text(tip.content)
                    .kohereTextStyle(.body2Regular)
                    .foregroundStyle(.labelNeutral)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Subview
    
    private var tipImage: some View {
        KohereRemoteImageView(urlString: tip.imageURL) {
            Color.clear
        }
        .frame(height: 188)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

private extension LivingGuideTheme {
    var bannerImageName: String {
        switch self {
        case .housingScams:
            "korean_tip_1"
            
        case .bankAccount:
            "korean_tip_2"
            
        case .publicTransit:
            "korean_tip_3"
            
        case .healthInsurance:
            "korean_tip_4"
        }
    }
}
