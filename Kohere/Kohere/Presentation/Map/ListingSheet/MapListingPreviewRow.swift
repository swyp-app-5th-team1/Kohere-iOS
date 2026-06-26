//
//  MapListingPreviewRow.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import SwiftUI

struct MapListingPreviewRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.backgroundNormalAlternative)
                .frame(width: 112, height: 112)
                .overlay {
                    Image("home_fill_24")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.labelAssistive)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("₩380~400K/mo")
                            .kohereTextStyle(.label1Semibold)
                            .foregroundStyle(.labelNormal)

                        Text("≈$355~398/mo")
                            .kohereTextStyle(.label3Medium)
                            .foregroundStyle(.labelNormal)
                    }

                    Spacer(minLength: 0)

                    Image("heart_24")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.labelAlternative)
                }

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
