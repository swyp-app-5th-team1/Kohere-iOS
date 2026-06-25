//
//  LivingGuideItemView.swift
//  Kohere
//
//  Created by mandoo on 6/25/26.
//

import SwiftUI

struct LivingGuideItemView: View {
    
    // MARK: - Properties
    
    let item: LivingGuide
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(item.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .kohereTextStyle(.label2Semibold)
                        .foregroundColor(.labelNormal)
                    
                    Text(item.subtitle)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundColor(.labelAlternative)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(.chevronRight16)
                    .renderingMode(.template)
                    .foregroundColor(.coolNeutral20)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.backgroundElevatedNormal)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.lineNeutral, lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
}
