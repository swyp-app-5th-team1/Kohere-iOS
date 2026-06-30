//
//  ListingDetailSectionTabs.swift
//  Kohere
//
//  Created by Codex on 6/30/26.
//

import SwiftUI

struct ListingDetailSectionTabs: View {
    let selectedSection: ListingDetailSection
    let title: (ListingDetailSection) -> String
    let onTap: (ListingDetailSection) -> Void

    var body: some View {
        ScrollViewReader { tabScrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(ListingDetailSection.allCases) { section in
                        sectionTab(
                            section,
                            isSelected: selectedSection == section
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            .onAppear {
                tabScrollProxy.scrollTo(selectedSection, anchor: .center)
            }
            .onChange(of: selectedSection) { _, section in
                withAnimation(.snappy(duration: 0.25)) {
                    tabScrollProxy.scrollTo(section, anchor: .center)
                }
            }
        }
        .frame(height: 44)
        .background(.common0)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.lineNeutral)
                .frame(height: 1)
        }
        .zIndex(1)
    }

    private func sectionTab(
        _ section: ListingDetailSection,
        isSelected: Bool
    ) -> some View {
        Button {
            onTap(section)
        } label: {
            Text(title(section))
                .kohereTextStyle(isSelected ? .label2Semibold : .body2Regular)
                .foregroundStyle(isSelected ? .labelNormal : .neutral70)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(.primary50)
                            .frame(height: 3)
                            .padding(.horizontal, 12)
                    }
                }
        }
        .buttonStyle(.plain)
        .id(section)
    }
}
