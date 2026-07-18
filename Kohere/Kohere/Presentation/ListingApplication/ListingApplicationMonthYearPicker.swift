//
//  ListingApplicationMonthYearPicker.swift
//  Kohere
//
//  Created by Codex on 7/9/26.
//

import SwiftUI
import UIKit

struct ListingApplicationMonthPicker: View {
    let onSelect: (Int, Int) -> Void

    private let minimumDate: Date
    private let maximumDate: Date
    private let years: [Int]

    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    init(
        displayedMonth: Date,
        minimumDate: Date,
        maximumDate: Date,
        onSelect: @escaping (Int, Int) -> Void
    ) {
        let year = Self.calendar.component(.year, from: displayedMonth)
        let month = Self.calendar.component(.month, from: displayedMonth)
        let minimumYear = Self.calendar.component(.year, from: minimumDate)
        let maximumYear = Self.calendar.component(.year, from: maximumDate)
        let clampedYear = min(max(year, minimumYear), maximumYear)

        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        years = Array(minimumYear...maximumYear)
        self.onSelect = onSelect
        _selectedYear = State(initialValue: clampedYear)
        _selectedMonth = State(
            initialValue: Self.clampedMonth(
                month,
                year: clampedYear,
                minimumDate: minimumDate,
                maximumDate: maximumDate
            )
        )
    }

    var body: some View {
        let months = availableMonths(for: selectedYear)

        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.neutral5)
                .frame(height: 44)
                .allowsHitTesting(false)

            UIKitMonthYearPicker(
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                years: years,
                months: months,
                onSelect: handleSelection
            )
        }
        .frame(height: 220)
        .clipped()
        .onChange(of: selectedYear) { _, year in
            selectedMonth = Self.clampedMonth(
                selectedMonth,
                year: year,
                minimumDate: minimumDate,
                maximumDate: maximumDate
            )
        }
    }

    private static var calendar: Calendar {
        ListingApplicationFeature.State.calendar
    }

    private func handleSelection(year: Int, month: Int) {
        let clampedMonth = Self.clampedMonth(
            month,
            year: year,
            minimumDate: minimumDate,
            maximumDate: maximumDate
        )

        if selectedMonth != clampedMonth {
            selectedMonth = clampedMonth
        }

        onSelect(year, clampedMonth)
    }

    private func availableMonths(for year: Int) -> [Int] {
        let lowerBound = Self.calendar.component(.year, from: minimumDate) == year
            ? Self.calendar.component(.month, from: minimumDate)
            : 1
        let upperBound = Self.calendar.component(.year, from: maximumDate) == year
            ? Self.calendar.component(.month, from: maximumDate)
            : 12

        guard lowerBound <= upperBound else { return [] }
        return Array(lowerBound...upperBound)
    }

    private static func clampedMonth(
        _ month: Int,
        year: Int,
        minimumDate: Date,
        maximumDate: Date
    ) -> Int {
        let lowerBound = calendar.component(.year, from: minimumDate) == year
            ? calendar.component(.month, from: minimumDate)
            : 1
        let upperBound = calendar.component(.year, from: maximumDate) == year
            ? calendar.component(.month, from: maximumDate)
            : 12

        return min(max(month, lowerBound), upperBound)
    }
}

struct UIKitMonthYearPicker: UIViewRepresentable {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int

    let years: [Int]
    let months: [Int]
    let onSelect: (Int, Int) -> Void

    func makeUIView(context: Context) -> SelectionlessPickerView {
        let pickerView = SelectionlessPickerView()
        pickerView.backgroundColor = .clear
        pickerView.dataSource = context.coordinator
        pickerView.delegate = context.coordinator
        return pickerView
    }

    func updateUIView(_ pickerView: SelectionlessPickerView, context: Context) {
        context.coordinator.parent = self
        pickerView.reloadAllComponents()

        if let yearIndex = years.firstIndex(of: selectedYear) {
            pickerView.selectRow(yearIndex, inComponent: 0, animated: false)
        }

        if let monthIndex = months.firstIndex(of: selectedMonth) {
            pickerView.selectRow(monthIndex, inComponent: 1, animated: false)
        }

        pickerView.clearSelectionBackground()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: UIKitMonthYearPicker

        init(parent: UIKitMonthYearPicker) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            2
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            values(for: component).count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            44
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            pickerView.bounds.width / 2
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            let value = values(for: component)[row]
            let isSelected = component == 0
                ? value == parent.selectedYear
                : value == parent.selectedMonth

            label.text = title(for: value, component: component)
            label.textAlignment = .center
            label.backgroundColor = .clear
            label.font = Self.font
            label.textColor = UIColor(
                named: isSelected ? "coolNeutral90" : "coolNeutral20"
            ) ?? .label
            label.isUserInteractionEnabled = false
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            let value = values(for: component)[row]

            if component == 0 {
                parent.selectedYear = value
            } else {
                parent.selectedMonth = value
            }

            parent.onSelect(parent.selectedYear, parent.selectedMonth)
            pickerView.reloadAllComponents()
            (pickerView as? SelectionlessPickerView)?.clearSelectionBackground()
        }

        private func values(for component: Int) -> [Int] {
            component == 0 ? parent.years : parent.months
        }

        private func title(for value: Int, component: Int) -> String {
            if component == 0 {
                return String(
                    format: String(localized: "listingApplication.format.year"),
                    locale: ListingApplicationFeature.State.displayLocale,
                    String(value)
                )
            }

            if ListingApplicationFeature.State.displayLocale.identifier.hasPrefix("ko") {
                return String(
                    format: String(localized: "listingApplication.format.month"),
                    locale: ListingApplicationFeature.State.displayLocale,
                    String(value)
                )
            }

            let formatter = DateFormatter()
            formatter.locale = ListingApplicationFeature.State.displayLocale
            let symbols = formatter.shortMonthSymbols ?? []
            return symbols.indices.contains(value - 1) ? symbols[value - 1] : "\(value)"
        }

        private static var font: UIFont {
            UIFont(
                name: KohereTextStyle.heading3Semibold.fontName,
                size: KohereTextStyle.heading3Semibold.fontSize
            ) ?? .systemFont(
                ofSize: KohereTextStyle.heading3Semibold.fontSize,
                weight: .semibold
            )
        }
    }
}

final class SelectionlessPickerView: UIPickerView {
    override func layoutSubviews() {
        super.layoutSubviews()
        clearSelectionBackground()
    }

    func clearSelectionBackground() {
        clearSelectionBackground(in: self)
    }

    private func clearSelectionBackground(in view: UIView) {
        for subview in view.subviews {
            subview.backgroundColor = .clear
            subview.isOpaque = false

            if let visualEffectView = subview as? UIVisualEffectView {
                visualEffectView.effect = nil
            }

            clearSelectionBackground(in: subview)
        }
    }
}
