//
//  RangeSlider.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import SwiftUI

struct RangeSliderValue: Equatable {
    var minimum: Int
    var maximum: Int

    init(minimum: Int, maximum: Int, bounds: ClosedRange<Int>) {
        let clampedMinimum = min(max(minimum, bounds.lowerBound), bounds.upperBound)
        let clampedMaximum = min(max(maximum, bounds.lowerBound), bounds.upperBound)

        self.minimum = min(clampedMinimum, clampedMaximum)
        self.maximum = max(clampedMinimum, clampedMaximum)
    }

    mutating func updateMinimum(_ value: Int, bounds: ClosedRange<Int>) {
        minimum = min(max(value, bounds.lowerBound), maximum)
    }

    mutating func updateMaximum(_ value: Int, bounds: ClosedRange<Int>) {
        maximum = max(min(value, bounds.upperBound), minimum)
    }
}

struct RangeSlider: View {
    @State private var activeThumb: SliderThumb?

    private let thumbSize: CGFloat = 24
    private let trackHeight: CGFloat = 4

    let value: RangeSliderValue
    let bounds: ClosedRange<Int>
    let onMinimumChange: (Int) -> Void
    let onMaximumChange: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let minimumX = position(for: value.minimum, width: width)
            let maximumX = position(for: value.maximum, width: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.lineNormal)
                    .frame(height: trackHeight)
                    .position(x: width / 2, y: thumbSize / 2)

                Capsule()
                    .fill(.primary50)
                    .frame(width: max(maximumX - minimumX, trackHeight), height: trackHeight)
                    .position(x: (minimumX + maximumX) / 2, y: thumbSize / 2)

                sliderThumb(.minimum)
                    .position(x: minimumX, y: thumbSize / 2)
                    .zIndex(value.minimum == value.maximum ? 1 : 0)

                sliderThumb(.maximum)
                    .position(x: maximumX, y: thumbSize / 2)
                    .zIndex(1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let thumb = activeThumb ?? nearestThumb(
                            for: value,
                            minimumX: minimumX,
                            maximumX: maximumX
                        )
                        activeThumb = thumb

                        switch thumb {
                        case .minimum:
                            onMinimumChange(sliderValue(for: value.location.x, width: width))
                        case .maximum:
                            onMaximumChange(sliderValue(for: value.location.x, width: width))
                        }
                    }
                    .onEnded { _ in
                        activeThumb = nil
                    }
            )
        }
    }

    private func sliderThumb(_ thumb: SliderThumb) -> some View {
        Circle()
            .fill(.common0)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .common100.opacity(0.12), radius: 2, x: 0, y: 1)
            .overlay {
                Circle()
                    .stroke(.lineNeutral.opacity(0.16), lineWidth: 1)
            }
            .contentShape(Circle())
            .accessibilityLabel(Text(thumb.accessibilityLabel))
            .accessibilityValue(Text("\(thumb.value(in: value))"))
            .accessibilityAdjustableAction { direction in
                adjust(thumb, direction: direction)
            }
    }

    private func adjust(_ thumb: SliderThumb, direction: AccessibilityAdjustmentDirection) {
        let step = accessibilityStep

        switch (thumb, direction) {
        case (.minimum, .increment):
            onMinimumChange(min(value.minimum + step, value.maximum))
        case (.minimum, .decrement):
            onMinimumChange(max(value.minimum - step, bounds.lowerBound))
        case (.maximum, .increment):
            onMaximumChange(min(value.maximum + step, bounds.upperBound))
        case (.maximum, .decrement):
            onMaximumChange(max(value.maximum - step, value.minimum))
        @unknown default:
            break
        }
    }

    private var accessibilityStep: Int {
        bounds.upperBound <= 100 ? 5 : 10
    }

    private func position(for value: Int, width: CGFloat) -> CGFloat {
        let trackWidth = max(width - thumbSize, 1)
        let valueRange = max(bounds.upperBound - bounds.lowerBound, 1)
        let progress = CGFloat(value - bounds.lowerBound) / CGFloat(valueRange)

        return thumbSize / 2 + progress * trackWidth
    }

    private func sliderValue(for locationX: CGFloat, width: CGFloat) -> Int {
        let trackWidth = max(width - thumbSize, 1)
        let clampedX = min(max(locationX - thumbSize / 2, 0), trackWidth)
        let progress = clampedX / trackWidth
        let valueRange = CGFloat(bounds.upperBound - bounds.lowerBound)

        return Int((CGFloat(bounds.lowerBound) + progress * valueRange).rounded())
    }

    private func nearestThumb(
        for value: DragGesture.Value,
        minimumX: CGFloat,
        maximumX: CGFloat
    ) -> SliderThumb {
        let minimumDistance = abs(value.startLocation.x - minimumX)
        let maximumDistance = abs(value.startLocation.x - maximumX)

        if minimumDistance == maximumDistance {
            return value.translation.width < 0 ? .minimum : .maximum
        }
        return minimumDistance < maximumDistance ? .minimum : .maximum
    }

    private enum SliderThumb {
        case minimum
        case maximum

        var accessibilityLabel: String {
            switch self {
            case .minimum:
                String(localized: "최소값")
            case .maximum:
                String(localized: "최대값")
            }
        }

        func value(in value: RangeSliderValue) -> Int {
            switch self {
            case .minimum:
                value.minimum
            case .maximum:
                value.maximum
            }
        }
    }
}
