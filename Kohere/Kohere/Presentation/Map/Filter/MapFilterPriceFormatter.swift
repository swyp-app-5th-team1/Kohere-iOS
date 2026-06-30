//
//  MapFilterPriceFormatter.swift
//  Kohere
//
//  Created by Codex on 6/26/26.
//

import Foundation

enum MapFilterPriceFormatter {
    static func controlSummary(
        selection: RangeSliderValue,
        bounds: ClosedRange<Int>
    ) -> String {
        switch rangeState(
            selection: selection,
            minimumBoundary: bounds.lowerBound,
            maximumBoundary: bounds.upperBound
        ) {
        case .all:
            return String(localized: "Any")
        case let .upperBound(maximum):
            return "\(maximum)만 원 이하"
        case let .lowerBound(minimum):
            return "\(minimum)만 원 이상"
        case let .range(minimum, maximum):
            return "\(minimum)만~\(maximum)만 원"
        }
    }

    static func chipTitle(
        prefix: String,
        selection: RangeSliderValue,
        defaultSelection: RangeSliderValue
    ) -> String? {
        switch rangeState(
            selection: selection,
            minimumBoundary: defaultSelection.minimum,
            maximumBoundary: defaultSelection.maximum
        ) {
        case .all:
            return nil
        case let .upperBound(maximum):
            return "\(prefix) \(maximum)만 원 이하"
        case let .lowerBound(minimum):
            return "\(prefix) \(minimum)만 원 이상"
        case let .range(minimum, maximum):
            return "\(prefix) \(minimum)만~\(maximum)만 원"
        }
    }

    private static func rangeState(
        selection: RangeSliderValue,
        minimumBoundary: Int,
        maximumBoundary: Int
    ) -> RangeState {
        switch (selection.minimum, selection.maximum) {
        case (minimumBoundary, maximumBoundary):
            return .all
        case (minimumBoundary, let maximum):
            return .upperBound(maximum)
        case (let minimum, maximumBoundary):
            return .lowerBound(minimum)
        case let (minimum, maximum):
            return .range(minimum, maximum)
        }
    }
}

private enum RangeState {
    case all
    case upperBound(Int)
    case lowerBound(Int)
    case range(Int, Int)
}
