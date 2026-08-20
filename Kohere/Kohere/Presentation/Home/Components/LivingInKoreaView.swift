//
//  LivingInKoreaView.swift
//  Kohere
//
//  Created by soomin on 6/25/26.
//

import ComposableArchitecture
import SwiftUI

struct LivingInKoreaView: View {
    
    // MARK: - Property
    
    let store: StoreOf<HomeLivingGuideFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.homeLivingGuideTitle)
                .kohereTextStyle(.heading3Semibold)
                .foregroundColor(.coolNeutral90)
                .padding(.leading, 8)
            
            VStack(spacing: 8) {
                ForEach(store.guides) { item in
                    LivingGuideItemView(item: item) {
                        store.send(.itemTapped(id: item.id))
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 26)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
    }
}
