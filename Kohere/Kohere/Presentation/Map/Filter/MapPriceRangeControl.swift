//
//  MapPriceRangeControl.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import SwiftUI

struct MapPriceRangeControl: View {
    let title: String
    let selection: MapFilterPriceSelection
    let bounds: ClosedRange<Int>
    let middleLabel: String
    let maximumLabel: String
    let onMinimumChange: (Int) -> Void
    let onMaximumChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .kohereTextStyle(.body2Regular)
                    .foregroundStyle(.labelNeutral)

                Spacer(minLength: 0)

                Text(summaryText)
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.primary100)
            }

            VStack(spacing: 6) {
                MapPriceRangeSlider(
                    selection: selection,
                    bounds: bounds,
                    onMinimumChange: onMinimumChange,
                    onMaximumChange: onMaximumChange
                )
                .frame(height: 24)

                HStack {
                    Text("\(bounds.lowerBound)")
                        .frame(width: 46, alignment: .leading)

                    Spacer(minLength: 0)

                    Text(middleLabel)
                        .frame(width: 46, alignment: .center)

                    Spacer(minLength: 0)

                    Text(maximumLabel)
                        .frame(width: 46, alignment: .trailing)
                }
                .kohereTextStyle(.caption2Regular)
                .foregroundStyle(.labelAlternative)
            }
        }
    }

    private var summaryText: String {
        MapFilterPriceFormatter.controlSummary(
            selection: selection,
            bounds: bounds
        )
    }
}
