//
//  MapFilterView.swift
//  Kohere
//
//  Created by Codex on 6/25/26.
//

import ComposableArchitecture
import SwiftUI

struct MapFilterView: View {
    @Bindable var store: StoreOf<MapFeature>

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .closeButton {
                    store.send(.filterDismissed)
                },
                center: .text("Filter")
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    filterSectionDivider

                    filterOptionsSection

                    filterSectionDivider

                    priceSection

                    filterSectionDivider

                    propertyTypeSection

                    filterSectionDivider
                }
                .padding(.bottom, 82)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundNormalNormal)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActionBar
        }
    }

    private var filterSectionDivider: some View {
        Color.neutral5
            .frame(height: 16)
    }

    private var filterOptionsSection: some View {
        MapFilterSection(title: "매물 옵션") {
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(MapFilterOption.allCases, id: \.self) { option in
                    MapFilterSelectionChip(
                        title: option.displayTitle,
                        isSelected: store.editingFilter.selectedOptions.contains(option)
                    ) {
                        store.send(.filterOptionTapped(option))
                    }
                }
            }
        }
    }

    private var priceSection: some View {
        MapFilterSection(title: "가격") {
            VStack(spacing: 16) {
                MapPriceRangeControl(
                    title: "월세",
                    selection: store.editingFilter.monthlyRentRange,
                    bounds: MapFilterPriceRange.monthlyRent,
                    middleLabel: "50만",
                    maximumLabel: "100만",
                    onMinimumChange: { store.send(.monthlyRentMinimumChanged($0)) },
                    onMaximumChange: { store.send(.monthlyRentMaximumChanged($0)) }
                )

                MapPriceRangeControl(
                    title: "보증금",
                    selection: store.editingFilter.depositRange,
                    bounds: MapFilterPriceRange.deposit,
                    middleLabel: "150만",
                    maximumLabel: "300만",
                    onMinimumChange: { store.send(.depositMinimumChanged($0)) },
                    onMaximumChange: { store.send(.depositMaximumChanged($0)) }
                )
            }
        }
    }

    private var propertyTypeSection: some View {
        MapFilterSection(title: "매물 종류") {
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(MapPropertyType.allCases, id: \.self) { propertyType in
                    MapFilterSelectionChip(
                        title: propertyType.displayTitle,
                        isSelected: store.editingFilter.selectedPropertyTypes.contains(propertyType)
                    ) {
                        store.send(.filterPropertyTypeTapped(propertyType))
                    }
                }
            }
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.lineNeutral.opacity(0.16))
                .frame(height: 1)

            HStack(spacing: 8) {
                Button {
                    store.send(.filterResetButtonTapped)
                } label: {
                    Text("초기화")
                        .kohereTextStyle(.label1Semibold)
                        .foregroundStyle(.primaryNormal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.primary5)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.lineAlternative.opacity(0.08), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .frame(width: 83)

                Button {
                    store.send(.filterApplyButtonTapped)
                } label: {
                    Text("적용하기")
                        .kohereTextStyle(.label1Semibold)
                        .foregroundStyle(.common0)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.primaryNormal)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(.common0)
        }
        .background(.common0)
    }
}

private struct MapFilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .kohereTextStyle(.heading3Semibold)
                .foregroundStyle(.common100)
                .frame(maxWidth: .infinity, alignment: .leading)

            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.common0)
    }
}

private struct MapFilterSelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .kohereTextStyle(.label3Medium)
                .foregroundStyle(isSelected ? .primaryNormal : .labelNeutral)
                .padding(.horizontal, 12)
                .frame(minWidth: 52)
                .frame(height: 32)
                .background(.coolNeutral5)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? Color.primaryPress : .clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct MapPriceRangeControl: View {
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
        let lowerBound = bounds.lowerBound
        let upperBound = bounds.upperBound

        switch (selection.minimum, selection.maximum) {
        case (lowerBound, upperBound):
            return "Any"
        case (lowerBound, let maximum):
            return "\(maximum)만 원 이하"
        case (let minimum, upperBound):
            return "\(minimum)만 원 이상"
        case let (minimum, maximum):
            return "\(minimum)만~\(maximum)만 원"
        }
    }
}

private struct FlowLayout: Layout {
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
