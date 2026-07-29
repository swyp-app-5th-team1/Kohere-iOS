//
//  KohereRemoteImageView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation
import Kingfisher
import SwiftUI

struct KohereRemoteImageView<Placeholder: View>: View {
    let urlString: String?
    let contentMode: SwiftUI.ContentMode
    let placeholder: () -> Placeholder
    let onImageLoaded: (() -> Void)?

    init(
        urlString: String?,
        contentMode: SwiftUI.ContentMode = .fill,
        onImageLoaded: (() -> Void)? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.contentMode = contentMode
        self.onImageLoaded = onImageLoaded
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let remoteURL {
                KFImage.url(remoteURL)
                    .placeholder {
                        placeholder()
                    }
                    .onSuccess { _ in
                        onImageLoaded?()
                    }
                    .fade(duration: 0.2)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
    }

    private var remoteURL: URL? {
        guard let rawURLString = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawURLString.isEmpty,
              let url = URL(string: rawURLString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }

        return url
    }
}

extension KohereRemoteImageView where Placeholder == KohereImageFallbackView {
    init(
        urlString: String?,
        contentMode: SwiftUI.ContentMode = .fill,
        onImageLoaded: (() -> Void)? = nil
    ) {
        self.init(
            urlString: urlString,
            contentMode: contentMode,
            onImageLoaded: onImageLoaded
        ) {
            KohereImageFallbackView()
        }
    }
}
