//
//  LocationPermissionDialog.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import SwiftUI

struct LocationPermissionDialog: View {
    let onCloseTapped: () -> Void
    let onSettingsTapped: () -> Void

    var body: some View {
        ZStack {
            Image("locationPermissionSheet")
                .resizable()
                .frame(width: 300, height: 387)
                .offset(y: -13.5)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 192)

                permissionContent
            }
        }
        .frame(width: 280, height: 356)
        .overlay(alignment: .topTrailing) {
            Button {
                onCloseTapped()
            } label: {
                Image(.close24)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.labelAlternative)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
        }
    }

    private var permissionContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("위치 권한을 허용해주세요")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.coolNeutral80)

                Text("고객님의 편리한 Kohere 이용을 위해\n위치 접근 권한의 허용이 필요합니다")
                    .kohereTextStyle(.caption1Regular)
                    .foregroundStyle(.neutral60)
                    .multilineTextAlignment(.center)
            }

            Button {
                onSettingsTapped()
            } label: {
                Text("설정 바로가기")
                    .kohereTextStyle(.label2Semibold)
                    .foregroundStyle(.common0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.primary50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(width: 280, height: 164)
    }
}
