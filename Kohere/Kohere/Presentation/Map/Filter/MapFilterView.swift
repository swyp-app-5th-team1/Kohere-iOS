//
//  MapFilterView.swift
//  Kohere
//
//  Created by Codex on 6/25/26.
//

import ComposableArchitecture
import SwiftUI

struct MapFilterView: View {
    @Environment(\.locale)
    private var locale
    @Bindable var store: StoreOf<MapFeature>

    private var language: AppLanguage {
        AppLanguage(locale: locale)
    }

    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .closeButton {
                    store.send(.filterDismissed)
                },
                center: .text(language.localized("map.filter.title"))
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    filterOptionsSection

                    priceSection

                    propertyTypeSection
                }
                .padding(.vertical, 16)
                .padding(.bottom, 82)
            }
            .background(.neutral5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.neutral5)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActionBar
        }
    }

    private var filterOptionsSection: some View {
        MapFilterSection(title: language.localized("map.filter.section.options")) {
            MapFilterFlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(RoomCondition.allCases, id: \.self) { option in
                    MapFilterSelectionChip(
                        title: option.mapFilterDisplayTitle(locale: locale),
                        isSelected: store.editingFilter.selectedOptions.contains(option)
                    ) {
                        store.send(.filterOptionTapped(option))
                    }
                }
            }
        }
    }

    private var priceSection: some View {
        MapFilterSection(title: language.localized("map.filter.section.price")) {
            VStack(spacing: 16) {
                MapPriceRangeControl(
                    title: language.localized("map.filter.monthlyRent"),
                    selection: store.editingFilter.monthlyRentRange,
                    bounds: MapFilterPriceRange.monthlyRent,
                    middleLabel: MapFilterPriceFormatter.amountText(50, locale: locale),
                    maximumLabel: MapFilterPriceFormatter.amountText(100, locale: locale),
                    onMinimumChange: { store.send(.monthlyRentMinimumChanged($0)) },
                    onMaximumChange: { store.send(.monthlyRentMaximumChanged($0)) }
                )

                MapPriceRangeControl(
                    title: language.localized("map.filter.deposit"),
                    selection: store.editingFilter.depositRange,
                    bounds: MapFilterPriceRange.deposit,
                    middleLabel: MapFilterPriceFormatter.amountText(150, locale: locale),
                    maximumLabel: MapFilterPriceFormatter.amountText(300, locale: locale),
                    onMinimumChange: { store.send(.depositMinimumChanged($0)) },
                    onMaximumChange: { store.send(.depositMaximumChanged($0)) }
                )
            }
        }
    }

    private var propertyTypeSection: some View {
        MapFilterSection(title: language.localized("map.filter.section.propertyType")) {
            MapFilterFlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(MapPropertyType.allCases, id: \.self) { propertyType in
                    MapFilterSelectionChip(
                        title: propertyType.displayTitle(locale: locale),
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
                    Text("common.reset")
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
                    Text("common.apply")
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
            .padding(.vertical, 10)
            .background(.common0)
        }
        .background(.common0)
    }
}
