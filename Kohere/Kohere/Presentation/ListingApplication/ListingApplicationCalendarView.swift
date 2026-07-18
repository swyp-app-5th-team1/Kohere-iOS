//
//  ListingApplicationCalendarView.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import SwiftUI

struct ListingApplicationDateSelectionView: View {
    let moveInDate: Date
    let displayedMonth: Date
    let displayedMonthTitle: String
    let minimumMoveInDate: Date
    let maximumMoveInDate: Date
    let moveInDateText: String
    let moveOutDateText: String
    let rentalPeriodText: String
    let rentalMonths: Int
    let isMonthPickerPresented: Bool
    let canMoveToPreviousMonth: Bool
    let canMoveToNextMonth: Bool
    let onPreviousMonthTap: () -> Void
    let onNextMonthTap: () -> Void
    let onMonthTitleTap: () -> Void
    let onMonthYearSelect: (Int, Int) -> Void
    let onDateTap: (Date) -> Void
    let onRentalMonthsDecrease: () -> Void
    let onRentalMonthsIncrease: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                titleBlock
                calendarCard
                dateSummary
                rentalPeriodControl
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .background(.backgroundNormalAlternative)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(.calendar24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.labelNormal)

                Text("listingApplication.dateSelection.title")
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.labelNormal)
            }

            Text("listingApplication.dateSelection.subtitle")
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.labelAlternative)
                .padding(.leading, 24)
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 24) {
            calendarHeader

            if isMonthPickerPresented {
                ListingApplicationMonthPicker(
                    displayedMonth: displayedMonth,
                    minimumDate: minimumMoveInDate,
                    maximumDate: maximumMoveInDate,
                    onSelect: onMonthYearSelect
                )
            } else {
                ListingApplicationCalendarGrid(
                    displayedMonth: displayedMonth,
                    selectedDate: moveInDate,
                    minimumDate: minimumMoveInDate,
                    maximumDate: maximumMoveInDate,
                    onDateTap: onDateTap
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 328, alignment: .top)
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .kohereElevation(.normalSmall, shape: .roundedRectangle(cornerRadius: 16))
    }

    private var calendarHeader: some View {
        HStack(spacing: 12) {
            Button(action: onMonthTitleTap) {
                HStack(spacing: 4) {
                    Text(displayedMonthTitle)
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(isMonthPickerPresented ? .primaryNormal : .coolNeutral80)

                    Image(isMonthPickerPresented ? .chevronDown16 : .chevronRight16)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.primaryNormal)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if !isMonthPickerPresented {
                Button(action: onPreviousMonthTap) {
                    Image(.chevronLeft24)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.primaryNormal)
                }
                .buttonStyle(.plain)
                .disabled(!canMoveToPreviousMonth)
                .opacity(canMoveToPreviousMonth ? 1 : 0.35)

                Button(action: onNextMonthTap) {
                    Image(.chevronRight24)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.primaryNormal)
                }
                .buttonStyle(.plain)
                .disabled(!canMoveToNextMonth)
                .opacity(canMoveToNextMonth ? 1 : 0.35)
            }
        }
        .frame(height: 24)
    }

    private var dateSummary: some View {
        HStack(spacing: 0) {
            summaryColumn(title: String(localized: "listingApplication.field.moveInDate"), value: moveInDateText)

            Rectangle()
                .fill(.lineNeutral)
                .frame(width: 1, height: 40)

            summaryColumn(title: String(localized: "listingApplication.field.moveOutDate"), value: moveOutDateText)
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryColumn(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .kohereTextStyle(.caption1Regular)
                .foregroundStyle(.labelAlternative)

            Text(value)
                .kohereTextStyle(.label1Semibold)
                .foregroundStyle(.coolNeutral90)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }

    private var rentalPeriodControl: some View {
        HStack(spacing: 24) {
            Button(action: onRentalMonthsDecrease) {
                Image(.minusThick24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.primaryNormal)
            }
            .buttonStyle(.plain)
            .disabled(rentalMonths <= 1)
            .opacity(rentalMonths <= 1 ? 0.35 : 1)

            VStack(spacing: 2) {
                Text("listingApplication.field.contractPeriod")
                    .kohereTextStyle(.caption1Regular)
                    .foregroundStyle(.labelAlternative)

                Text(rentalPeriodText)
                    .kohereTextStyle(.label1Semibold)
                    .foregroundStyle(.primaryNormal)
            }

            Button(action: onRentalMonthsIncrease) {
                Image(.plusThick24)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.primaryNormal)
            }
            .buttonStyle(.plain)
            .disabled(rentalMonths >= 12)
            .opacity(rentalMonths >= 12 ? 0.35 : 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(.common0)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ListingApplicationCalendarGrid: View {
    let displayedMonth: Date
    let selectedDate: Date
    let minimumDate: Date
    let maximumDate: Date
    let onDateTap: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundStyle(.labelAlternative)
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(days) { day in
                    Button {
                        onDateTap(day.date)
                    } label: {
                        Text("\(Self.calendar.component(.day, from: day.date))")
                            .kohereTextStyle(.label2Medium)
                    }
                    .buttonStyle(
                        ListingApplicationDateCellStyle(
                            isSelected: isSelected(day.date),
                            isDisplayedMonth: day.isDisplayedMonth,
                            isSelectable: isSelectable(day.date)
                        )
                    )
                    .disabled(!isSelectable(day.date))
                }
            }
        }
    }

    private var days: [CalendarDay] {
        guard let monthInterval = Self.calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = Self.calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        let daysInMonth = Self.calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        let leadingCount = Self.calendar.dateComponents(
            [.day],
            from: firstWeek.start,
            to: monthInterval.start
        ).day ?? 0
        let totalCount = leadingCount + daysInMonth <= 35 ? 35 : 42

        return (0..<totalCount).compactMap { index in
            guard let date = Self.calendar.date(byAdding: .day, value: index, to: firstWeek.start) else {
                return nil
            }

            return CalendarDay(
                id: "\(date.timeIntervalSince1970)",
                date: date,
                isDisplayedMonth: Self.calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
            )
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        Self.calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func isSelectable(_ date: Date) -> Bool {
        let startOfDay = Self.calendar.startOfDay(for: date)
        return startOfDay >= minimumDate && startOfDay <= maximumDate
    }

    private static var calendar: Calendar {
        ListingApplicationFeature.State.calendar
    }
}

private struct ListingApplicationDateCellStyle: ButtonStyle {
    let isSelected: Bool
    let isDisplayedMonth: Bool
    let isSelectable: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .frame(width: 32, height: 32)
            .background {
                if let backgroundColor = backgroundColor(isPressed: configuration.isPressed) {
                    Circle().fill(backgroundColor)
                }
            }
            .contentShape(Circle())
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        if isPressed {
            return .staticWhite
        }

        if isSelected {
            return .primaryNormal
        }

        guard isDisplayedMonth, isSelectable else {
            return .coolNeutral20
        }

        return .coolNeutral90
    }

    private func backgroundColor(isPressed: Bool) -> Color? {
        if isPressed {
            return .primaryNormal
        }

        if isSelected {
            return .primary5
        }

        return nil
    }
}

private struct CalendarDay: Identifiable {
    let id: String
    let date: Date
    let isDisplayedMonth: Bool
}
