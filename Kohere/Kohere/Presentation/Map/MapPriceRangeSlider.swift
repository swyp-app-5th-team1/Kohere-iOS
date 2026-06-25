import SwiftUI

struct MapPriceRangeSlider: View {
    @State private var activeThumb: SliderThumb?

    private let thumbSize: CGFloat = 24
    private let trackHeight: CGFloat = 4

    let selection: MapFilterPriceSelection
    let bounds: ClosedRange<Int>
    let onMinimumChange: (Int) -> Void
    let onMaximumChange: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let minimumX = position(for: selection.minimum, width: width)
            let maximumX = position(for: selection.maximum, width: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.lineNormal)
                    .frame(height: trackHeight)
                    .position(x: width / 2, y: thumbSize / 2)

                Capsule()
                    .fill(.primary50)
                    .frame(width: max(maximumX - minimumX, trackHeight), height: trackHeight)
                    .position(x: (minimumX + maximumX) / 2, y: thumbSize / 2)

                sliderThumb
                    .position(x: minimumX, y: thumbSize / 2)
                    .zIndex(selection.minimum == selection.maximum ? 1 : 0)

                sliderThumb
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

    private var sliderThumb: some View {
        Circle()
            .fill(.common0)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .common100.opacity(0.12), radius: 2, x: 0, y: 1)
            .overlay {
                Circle()
                    .stroke(.lineNeutral.opacity(0.16), lineWidth: 1)
            }
            .contentShape(Circle())
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
    }
}
