//
//  MapSelectedListingSheetView.swift
//  Kohere
//
//  Created by Codex on 6/25/26.
//

import SwiftUI

struct MapSelectedListingSheetView: View {
    let closeButtonTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 10)

            selectedListingCard
                .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.common0)
        .clipShape(sheetShape)
        .kohereElevation(.bottomSheet, shape: .topRoundedRectangle(cornerRadius: 26))
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var sheetShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 26,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 26,
            style: .continuous
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Sky Goshiwon")
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(.coolNeutral75)

            Spacer()

            Image("heart_24")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(.labelAlternative)

            Button {
                closeButtonTapped()
            } label: {
                Image("close_24")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.labelAlternative)
            }
            .buttonStyle(.plain)
        }
    }

    private var selectedListingCard: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.backgroundNormalAlternative)
                .frame(width: 120, height: 120)
                .overlay {
                    Image("home_fill_24")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.labelAssistive)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("₩380~400K/mo")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.labelNormal)

                Text("≈$355~398/mo")
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(.labelNormal)

                Text("Dep. ₩200K · Maint. ₩20K")
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(.labelAlternative)

                Text("8-min walk Hongdae Sta.")
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(.labelAlternative)

                HStack(spacing: 6) {
                    Text("Goshiwon")
                        .kohereTextStyle(.caption2Medium)
                        .foregroundStyle(.labelNeutral)
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(.backgroundNormalAlternative)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Text("1 mo~")
                        .kohereTextStyle(.caption2Medium)
                        .foregroundStyle(.labelAlternative)
                }
            }
        }
    }
}
