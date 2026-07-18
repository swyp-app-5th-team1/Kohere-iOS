//
//  ListingDetailHeroSection.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import SwiftUI

struct ListingDetailHeroSection: View {
    let overview: ListingDetailOverviewModel

    @State private var selectedImageIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            heroImage
            ListingDetailOverviewSection(overview: overview)
        }
        .background(.common0)
    }

    private var heroImage: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(overview.imageURLs.enumerated()), id: \.offset) { index, imageURL in
                KohereRemoteImageView(urlString: imageURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 267)
                    .clipped()
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity)
        .frame(height: 267)
        .background {
            if overview.imageURLs.isEmpty {
                KohereRemoteImageView(urlString: nil)
            }
        }
        .overlay {
            Color.common100.opacity(0.2)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(imageCountText)
                .kohereTextStyle(.caption2Regular)
                .foregroundStyle(.common0)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.backgroundTransparentAlternative)
                .clipShape(Capsule())
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .allowsHitTesting(false)
        }
        .onChange(of: overview.id) {
            selectedImageIndex = 0
        }
        .onChange(of: overview.imageURLs.count) {
            selectedImageIndex = min(
                selectedImageIndex,
                max(overview.imageURLs.count - 1, 0)
            )
        }
    }

    private var imageCountText: String {
        guard !overview.imageURLs.isEmpty else { return overview.imageCountText }
        return "\(selectedImageIndex + 1)/\(overview.imageURLs.count)"
    }
}
