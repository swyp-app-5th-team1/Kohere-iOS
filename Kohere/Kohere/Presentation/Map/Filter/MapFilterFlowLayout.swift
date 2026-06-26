//
//  MapFilterFlowLayout.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import SwiftUI

struct MapFilterFlowLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextX = currentX + (currentX > 0 ? spacing : 0) + size.width

            if currentX > 0, nextX > containerWidth {
                totalHeight += currentRowHeight + rowSpacing
                currentX = size.width
                currentRowHeight = size.height
            } else {
                currentX = nextX
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }
        return CGSize(width: containerWidth, height: totalHeight + currentRowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > bounds.minX, currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += currentRowHeight + rowSpacing
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}
