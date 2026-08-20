//
//  NotificationOptionBottomSheet.swift
//  Kohere
//
//  Created by soomin on 6/18/26.
//

import SwiftUI

struct NotificationOptionBottomSheet: View {
    
    // MARK: - Properties
    
    let onAllowTapped: () -> Void
    let onSkipTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 999)
                .fill(.fillStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            Image(.notificationShadow)
                .resizable()
                .scaledToFit()
                .frame(width: 152, height: 152)
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 20) {
                Text(.loginNotificationTitle)
                    .kohereTextStyle(.heading2Bold)
                    .foregroundColor(.neutral80)
                    .multilineTextAlignment(.leading)
                
                Text(.loginNotificationDescription)
                    .kohereTextStyle(.caption2Regular)
                    .foregroundColor(.neutral60)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 8) {
                Button {
                    onAllowTapped()
                } label: {
                    Text(.loginNotificationAllowButton)
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.primaryNormal)
                        .cornerRadius(16)
                }
                
                Button {
                    onSkipTapped()
                } label: {
                    Text(.commonSkip)
                        .kohereTextStyle(.label2Medium)
                        .foregroundColor(.labelAlternative)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .presentationDragIndicator(.hidden)
    }
}
