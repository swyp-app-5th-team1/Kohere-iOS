//
//  KohereEmptyView.swift
//  Kohere
//
//  Created by soomin on 6/24/26.
//

import SwiftUI

struct KohereEmptyView: View {
    
    // MARK: - Property
    
    let title: String
    var fontStyle: KohereTextStyle = .body2Regular
    var fontColor: Color = .labelNeutral
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(.typoLogo)
                .resizable()
                .frame(width: 107, height: 28)
                .opacity(0.5)
            
            Text(title)
                .kohereTextStyle(fontStyle)
                .foregroundColor(fontColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
