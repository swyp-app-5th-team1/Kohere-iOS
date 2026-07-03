//
//  UserTypeSelectBottomSheet.swift
//  Kohere
//
//  Created by mandoo on 7/2/26.
//

import SwiftUI

struct UserTypeSelectBottomSheet: View {

    // MARK: - Properties

    let findMyRoomTapped: () -> Void
    let rentOutTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 999)
                .fill(.fillStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 2) {
                Text("What brings you here?")
                    .kohereTextStyle(.heading2Bold)
                    .foregroundStyle(.labelNormal)

                Text("원하시는 서비스를 선택해주세요")
                    .kohereTextStyle(.body2Regular)
                    .foregroundStyle(.labelAlternative)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 30)
            .padding(.horizontal, 40)

            VStack(spacing: 8) {
                UserTypeButton(
                    title: "Find My Room",
                    isPrimary: true,
                    koreanTitle: "방 구하기",
                    description: "Find a safe and verified room in Korea",
                    image: .homeEmpty,
                    action: findMyRoomTapped
                )

                UserTypeButton(
                    title: "Rent Out",
                    isPrimary: false,
                    koreanTitle: "방 내놓기",
                    description: "매물을 등록하고 안전하게 관리하세요",
                    image: .rent,
                    action: RentOutTapped
                )
            }
            .padding(.top, 20)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - SubView

struct UserTypeButton: View {
    let title: String
    let isPrimary: Bool
    let koreanTitle: String
    let description: String
    let image: UIImage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .padding(.leading, 16)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .kohereTextStyle(.heading3Semibold)
                            .foregroundStyle(isPrimary ? .primaryNormal : .labelNormal)

                        Text(koreanTitle)
                            .kohereTextStyle(.heading3Semibold)
                            .foregroundStyle(.labelNormal)
                    }

                    Text(description)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundStyle(.labelAlternative)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 84)
            .background(.backgroundNormalNormal)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderStyle, lineWidth: 1)
            }
        }
    }

    private var borderStyle: AnyShapeStyle {
        if isPrimary {
            AnyShapeStyle(
                LinearGradient(
                    colors: [.primaryNormal, .yellow40],
                    startPoint: UnitPoint(x: 0.5, y: 1),
                    endPoint: UnitPoint(x: 0.65, y: 0)
                )
            )
        } else {
            AnyShapeStyle(.lineNeutral)
        }
    }
}
