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
                Text("좋은 매물을 놓치지 않도록\n알림을 드릴게요")
                    .kohereTextStyle(.heading2Bold)
                    .foregroundColor(.neutral80)
                    .multilineTextAlignment(.leading)
                
                Text("‘설정 > 앱 > 코히어’에서 알림설정 변경이 가능합니다.")
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
                    Text("알림 받기")
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
                    Text("건너뛰기")
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
