//
//  ListingDetailHeroSection.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import SwiftUI

struct ListingDetailHeroSection: View {
    let overview: ListingDetailOverviewModel

    var body: some View {
        VStack(spacing: 0) {
            heroImage
            ListingDetailOverviewSection(overview: overview)
        }
        .background(.common0)
    }

    private var heroImage: some View {
        KohereRemoteImageView(urlString: overview.imageURLs.first)
            .frame(maxWidth: .infinity)
            .frame(height: 267)
            .clipped()
            .overlay {
                Color.common100.opacity(0.2)
            }
    }
}
