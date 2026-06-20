//
//  NotificationOptionBottomSheet.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
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
                Text("We'll send alerts\nso you don't miss great listings")
                    .kohereTextStyle(.heading2Bold)
                    .foregroundColor(.neutral80)
                    .multilineTextAlignment(.leading)
                
                Text("You can manage notification settings anytime\nin your device settings.")
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
                    Text("Allow Notifications")
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
                    Text("Skip")
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
