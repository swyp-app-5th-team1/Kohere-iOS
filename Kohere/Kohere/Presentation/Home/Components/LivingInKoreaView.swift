//
//  LivingInKoreaView.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

import ComposableArchitecture
import SwiftUI

struct LivingInKoreaView: View {
    
    // MARK: - Property
    
    let store: StoreOf<HomeFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("home.livingGuide.title")
                .kohereTextStyle(.heading3Semibold)
                .foregroundColor(.coolNeutral90)
                .padding(.leading, 8)
            
            VStack(spacing: 8) {
                ForEach(store.livingGuides) { item in
                    LivingGuideItemView(item: item) {
                        store.send(.livingGuideItemTapped(id: item.id))
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
