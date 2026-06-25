//
//  KohereEmptyView.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import SwiftUI

struct KohereEmptyView: View {
    
    // MARK: - Property
    
    let title: String
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(.typoLogo)
                .resizable()
                .frame(width: 107, height: 28)
                .opacity(0.5)
            
            Text(title)
                .kohereTextStyle(.body2Regular)
                .foregroundColor(.labelNeutral)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
